(defvar rg-program (purecopy "rg")
  "The default rg program.
This is used by commands like `grep-rg-command', `rg-dired'
and others.")

(defvar rg-args nil
  "Last arguments given to `rg' by \\[rg-dired].")

;; History of rg-args values entered in the minibuffer.
(defvar rg-args-history nil)

(defcustom rg-dired-refine-function #'find-dired-sort-by-filename
  "If non-nil, a function for refining the *RipGrep* buffer of `rg-dired'.
This function takes no arguments.  The *RipGrep* buffer is narrowed to the
output of `rg' (one file per line) when this function is called."
  :version "27.1"
  :group 'rg-dired
  :type '(choice (const :tag "Sort file names lexicographically"
                        find-dired-sort-by-filename)
                 (function :tag "Refining function")
                 (const :tag "No refining" nil)))


(defun rg-re-dired (dir regexp)
  "Find files in DIR that contain matches for REGEXP and start Dired on output.
The command run (after changing into DIR) is

  rg -l -e REGEXP .
"
  (interactive "DRipGrep (directory): \nsRipGrep (regexp): ")
  (rg-dired dir
              (concat " -e "
                      (shell-quote-argument regexp))))

(defun rg-dired (dir args)
  "Run `rg' and go into Dired mode on a buffer of the output.
The command run (after changing into DIR) is essentially

    rg -l \\( ARGS \\) .
"
  (interactive (list (read-directory-name "Run rg -l in directory: " nil "" t)
                     (read-string "Run rg -l (with args): " rg-args
                                  '(rg-args-history . 1))))
  (let ((dired-buffers dired-buffers))
    ;; Expand DIR ("" means default-directory), and make sure it has a
    ;; trailing slash.
    (setq dir (file-name-as-directory (expand-file-name dir)))
    ;; Check that it's really a directory.
    (or (file-directory-p dir)
        (error "rg-dired needs a directory: %s" dir))
    (pop-to-buffer-same-window (get-buffer-create "*RipGrep*"))

    ;; See if there's still a `rg' running, and offer to kill
    ;; it first, if it is.
    (let ((rg (get-buffer-process (current-buffer))))
      (when rg
        (if (or (not (eq (process-status rg) 'run))
                (yes-or-no-p
                 (format-message "An `rg' process is running; kill it? ")))
            (condition-case nil
                (progn
                  (interrupt-process rg)
                  (sit-for 1)
                  (delete-process rg))
              (error nil))
          (error "Cannot have two processes in `%s' at once" (buffer-name)))))

    (widen)
    (kill-all-local-variables)
    (setq buffer-read-only nil)
    (erase-buffer)
    (setq default-directory dir
          rg-args args        ; save for next interactive call
          args (concat rg-program
                       " -l -0 "
                       args
                       " . | xargs -0 /bin/ls -lh"))
    ;; Start the rg process.
    (shell-command (concat args "&") (current-buffer))
    ;; The next statement will bomb in classic dired (no optional arg allowed)
    (dired-mode dir nil)
    (let ((map (make-sparse-keymap)))
      (set-keymap-parent map (current-local-map))
      (define-key map "\C-c\C-k" 'kill-rg)
      (use-local-map map))
    (make-local-variable 'dired-sort-inhibit)
    (setq dired-sort-inhibit t)
    (set (make-local-variable 'revert-buffer-function)
         `(lambda (ignore-auto noconfirm)
            (rg-dired ,dir ,rg-args)))
    ;; Set subdir-alist so that Tree Dired will work:
    (if (fboundp 'dired-simple-subdir-alist)
        ;; will work even with nested dired format (dired-nstd.el,v 1.15
        ;; and later)
        (dired-simple-subdir-alist)
      ;; else we have an ancient tree dired (or classic dired, where
      ;; this does no harm)
      (set (make-local-variable 'dired-subdir-alist)
           (list (cons default-directory (point-min-marker)))))
    (set (make-local-variable 'dired-subdir-switches) find-ls-subdir-switches)
    (setq buffer-read-only nil)
    ;; Subdir headlerline must come first because the first marker in
    ;; subdir-alist points there.
    (insert "  " dir ":\n")
    ;; Make second line a ``rg'' line in analogy to the ``total'' or
    ;; ``wildcard'' line.
    (let ((point (point)))
      (insert "  " args "\n")
      (dired-insert-set-properties point (point)))
    (setq buffer-read-only t)
    (let ((proc (get-buffer-process (current-buffer))))
      (set-process-filter proc (function rg-dired-filter))
      (set-process-sentinel proc (function rg-dired-sentinel))
      ;; Initialize the process marker; it is used by the filter.
      (move-marker (process-mark proc) (point) (current-buffer)))
    (setq mode-line-process '(":%s"))))

(defun kill-rg ()
  "Kill the `rg' process running in the current buffer."
  (interactive)
  (let ((rg (get-buffer-process (current-buffer))))
    (and rg (eq (process-status rg) 'run)
         (eq (process-filter rg) (function rg-dired-filter))
         (condition-case nil
             (delete-process rg)
           (error nil)))))

(defun rg-dired-filter (proc string)
  ;; Filter for \\[rg-dired] processes.
  (let ((buf (process-buffer proc))
        (inhibit-read-only t))
    (if (buffer-name buf)
        (with-current-buffer buf
          (save-excursion
            (save-restriction
              (widen)
              (let ((buffer-read-only nil)
                    (beg (point-max))
                    (ls-regexp (concat "^ +[^ \t\r\n]+\\( +[^ \t\r\n]+\\) +"
                                       "[^ \t\r\n]+ +[^ \t\r\n]+\\( +[^[:space:]]+\\)")))
                (goto-char beg)
                (insert string)
                (goto-char beg)
                (or (looking-at "^")
                    (forward-line 1))
                (while (looking-at "^")
                  (insert "  ")
                  (forward-line 1))
                ;; Convert ` ./FILE' to ` FILE'
                ;; This would lose if the current chunk of output
                ;; starts or ends within the ` ./', so back up a bit:
                (goto-char (- beg 3))   ; no error if < 0
                (while (search-forward " ./" nil t)
                  (delete-region (point) (- (point) 2)))
                ;; Pad the number of links and file size.  This is a
                ;; quick and dirty way of getting the columns to line up
                ;; most of the time, but it's not foolproof.
                (goto-char beg)
                (goto-char (line-beginning-position))
                (while (re-search-forward ls-regexp nil t)
                  (replace-match (format "%4s" (match-string 1))
                                 nil nil nil 1)
                  (replace-match (format "%9s" (match-string 2))
                                 nil nil nil 2)
                  (forward-line 1))
                ;; Find all the complete lines in the unprocessed
                ;; output and process it to add text properties.
                (goto-char (point-max))
                (if (search-backward "\n" (process-mark proc) t)
                    (progn
                      (dired-insert-set-properties (process-mark proc)
                                                   (1+ (point)))
                      (move-marker (process-mark proc) (1+ (point)))))))))
      ;; The buffer has been killed.
      (delete-process proc))))

(defun rg-dired-sentinel (proc state)
  "Sentinel for \\[rg-dired] processes."
  (let ((buf (process-buffer proc)))
    (if (buffer-name buf)
        (with-current-buffer buf
          (let ((inhibit-read-only t))
            (save-excursion
              (save-restriction
                (widen)
                (when rg-dired-refine-function
                  ;; `rg-dired-filter' puts two whitespace characters
                  ;; at the beginning of every line.
                  (narrow-to-region (point) (- (point-max) 2))
                  (funcall rg-dired-refine-function)
                  (widen))
                (let ((point (point-max)))
                  (goto-char point)
                  (insert "\n  find "
                          (substring state 0 -1) ; omit \n at end of STATE.
                          " at " (substring (current-time-string) 0 19))
                  (dired-insert-set-properties point (point))))
              (setq mode-line-process
                    (format ":%s" (process-status proc)))
              ;; Since the buffer and mode line will show that the
              ;; process is dead, we can delete it now.  Otherwise it
              ;; will stay around until M-x `list-processes'.
              (delete-process proc)
              (force-mode-line-update))))
          (message "find-dired %s finished." buf))))

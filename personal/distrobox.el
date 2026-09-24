(use-package tramp
  :config
  (add-to-list 'tramp-default-user-alist '("podman" "^\\(?:dev\\|bwapi\\)$" "zefs"))
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

(defun radz-container--foreign-remote-p (path)
  "Non-nil if PATH is remote over some method other than podman."
  (let ((method (file-remote-p path 'method)))
    (and method (not (equal method "podman")))))

(defun radz-container-for-path (path alist)
  "Return the container ALIST maps PATH to, or nil.
ALIST maps directories to container names.  Both sides are compared
as true names, so symlinks like /home -> /var/home don't matter.
The longest matching directory wins.  A podman PATH is looked up by
its local name; any other remote PATH never matches."
  (unless (radz-container--foreign-remote-p path)
    (let ((target (file-name-as-directory (file-truename (file-local-name path))))
          best best-length)
      (dolist (entry alist)
        (let ((dir (file-name-as-directory (file-truename (car entry)))))
          (when (and (string-prefix-p dir target)
                     (or (null best-length) (> (length dir) best-length)))
            (setq best (cdr entry)
                  best-length (length dir)))))
      best)))

(defun radz-container-tramp-path (path container)
  "Return PATH as a TRAMP path into CONTAINER as the current user.
A podman PATH is re-targeted at CONTAINER; any other remote PATH is
returned unchanged."
  (if (radz-container--foreign-remote-p path)
      path
    (format "/podman:%s@%s:%s" (user-login-name) container (file-local-name path))))

(defcustom radz-container-directory-alist nil
  "Alist mapping directories to the podman container to open files in.
The longest directory containing a file wins.  Used by
`radz-find-file-in-container'."
  :type '(alist :key-type directory :value-type (string :tag "Container"))
  :group 'tramp)

(setopt radz-container-directory-alist
        '(("~/prog" . "dev")
          ("~/prog/bwapi" . "bwapi")))

(defun radz-container--podman (&rest args)
  "Run podman locally with ARGS and return its output lines."
  (let ((default-directory (expand-file-name "~/")))
    (apply #'process-lines "podman" args)))

(defun radz-container--ensure-running (container)
  "Start CONTAINER if it isn't running."
  (unless (equal (radz-container--podman "container" "inspect"
                                         "--format" "{{.State.Running}}" container)
                 '("true"))
    (message "Starting container %s..." container)
    (radz-container--podman "start" container)
    (message "Starting container %s...done" container)))

(defun radz-find-file-in-container (filename)
  "Visit FILENAME in the container `radz-container-directory-alist' maps it to.
Prompts for a container when no directory matches.  Remote files over
anything but podman are visited with plain `find-file'."
  (interactive
   (list (let ((default-directory (file-local-name default-directory)))
           (read-file-name "Find file in container: "))))
  (if (radz-container--foreign-remote-p filename)
      (find-file filename)
    (let* ((local (expand-file-name (file-local-name filename)))
           (container (or (radz-container-for-path local radz-container-directory-alist)
                          (completing-read
                           (format "Container for %s: " (abbreviate-file-name local))
                           (radz-container--podman "ps" "-a" "--format" "{{.Names}}")
                           nil t))))
      (radz-container--ensure-running container)
      (find-file (radz-container-tramp-path local container)))))

(global-set-key (kbd "C-c c c") #'radz-find-file-in-container)

(defun radz-container-local-name (path)
  "Return PATH without its podman TRAMP prefix.
Any other PATH is returned unchanged.  This is safe because every
container mounts the home directory at the same path."
  (if (equal (file-remote-p path 'method) "podman")
      (file-local-name path)
    path))

(defun radz-magit-status-locally (fn &optional directory &rest args)
  "Around advice for `magit-status' that runs it on the host.
Git over TRAMP is slow, and commit signing only works on the host."
  (interactive (lambda (spec)
                 (let ((default-directory (radz-container-local-name default-directory)))
                   (advice-eval-interactive-spec spec))))
  (let ((default-directory (radz-container-local-name default-directory)))
    (apply fn (and directory (radz-container-local-name directory)) args)))

(advice-add 'magit-status :around #'radz-magit-status-locally)

(defconst radz-distrobox-shim-script
  (expand-file-name "bin/in-container" (file-name-directory (or load-file-name buffer-file-name)))
  "Script every shim links to.  It runs the tool in the shim's box.")

(defvar radz-distrobox-shims-directory
  (expand-file-name ".distrobox-shims" (file-name-directory (or load-file-name buffer-file-name)))
  "Directory holding one subdirectory of shims per box.")

(defcustom radz-distrobox-tools nil
  "Alist mapping each distrobox to the tools Emacs runs inside it.
Only these get shims, so anything else, git in particular, runs on
the host.  Call `radz-distrobox-sync-shims' after changing it."
  :type '(alist :key-type (string :tag "Box") :value-type (repeat (string :tag "Tool")))
  :group 'tramp)

(defun radz-distrobox-shim-directory (box)
  "Return the directory of shims for BOX."
  (file-name-as-directory (expand-file-name box radz-distrobox-shims-directory)))

(defun radz-distrobox-sync-shims ()
  "Make the shims in `radz-distrobox-shims-directory' match `radz-distrobox-tools'.
Only symlinks are removed, and a box's directory only once it's empty."
  (dolist (entry radz-distrobox-tools)
    (let ((dir (radz-distrobox-shim-directory (car entry))))
      (make-directory dir t)
      (dolist (tool (cdr entry))
        (let ((link (expand-file-name tool dir)))
          (unless (equal (file-symlink-p link) radz-distrobox-shim-script)
            (make-symbolic-link radz-distrobox-shim-script link t))))))
  (when (file-directory-p radz-distrobox-shims-directory)
    (dolist (dir (directory-files radz-distrobox-shims-directory t "\\`[^.]"))
      (when (file-directory-p dir)
        (let ((tools (cdr (assoc (file-name-nondirectory dir) radz-distrobox-tools))))
          (dolist (link (directory-files dir t "\\`[^.]"))
            (when (and (file-symlink-p link)
                       (not (member (file-name-nondirectory link) tools)))
              (delete-file link)))
          (unless (directory-files dir nil "\\`[^.]")
            (delete-directory dir)))))))

(setopt radz-distrobox-tools
        '(("dev" "rust-analyzer" "cargo" "rustfmt")))

(radz-distrobox-sync-shims)

(defun radz-distrobox-path-with-shims (shims env)
  "Return a copy of the process environment ENV with SHIMS first on PATH."
  (let ((path (split-string (or (getenv-internal "PATH" env) "") path-separator t)))
    (setenv-internal (copy-sequence env) "PATH"
                     (string-join (cons shims (remove shims path)) path-separator)
                     t)))

(defun radz-distrobox-box-with-shims (directory)
  "Return the box that DIRECTORY maps to, if it has shims.
Remote directories never do: their processes don't run on the host."
  (unless (file-remote-p directory)
    (let ((box (radz-container-for-path directory radz-container-directory-alist)))
      (and (assoc box radz-distrobox-tools) box))))

(defun radz-distrobox-use-shims ()
  "Run this buffer's processes through the shims of its box, if any.
Sets `exec-path', which `make-process' and `executable-find' use, and
PATH, which shell commands like `compile' use."
  (when-let* ((box (radz-distrobox-box-with-shims default-directory)))
    (let ((shims (directory-file-name (radz-distrobox-shim-directory box))))
      (setq-local exec-path (cons shims (remove shims exec-path)))
      (setq-local process-environment
                  (radz-distrobox-path-with-shims shims process-environment)))))

(add-hook 'after-change-major-mode-hook #'radz-distrobox-use-shims)

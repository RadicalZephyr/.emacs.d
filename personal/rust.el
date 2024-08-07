;;; rust.el --- My rust configuration

;;; Commentary:

;;; Code:

(prelude-require-packages '(rust-mode lsp-mode flycheck-rust flycheck-inline racer company-racer toml-mode))

(require 'compile)
(require 'cargo-process)
(require 'rust-mode)
(require 'racer)
(require 'toml-mode)
(require 'lsp-mode)
(require 'lsp-rust)

;; Racer setup

(setq racer-cmd (concat home-dir "/.cargo/bin/racer")
      racer-rust-src-path (concat home-dir "/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src")
      rust-format-on-save t
      rust-rustfmt-bin "rustfmt"
      cargo-process--command-clippy "clippy"
      lsp-rust-analyzer-cargo-load-out-dirs-from-check t
      lsp-rust-analyzer-cargo-watch-command "clippy"
      lsp-rust-analyzer-proc-macro-enable t)

(define-key rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)
(define-key rust-mode-map (kbd "C-c C-c M-k") #'cargo-process-clippy)
(define-key rust-mode-map (kbd "C-c C-c C-e") #'cargo-process-current-file-expand)
(define-key rust-mode-map (kbd "C-c C-c M-e") #'cargo-process-current-file-expand-and-compile)

(define-key rust-mode-map (kbd "C-c C-l d") #'lsp-execute-code-action)
(define-key rust-mode-map (kbd "C-c C-l e") #'lsp-rust-analyzer-expand-macro)
(define-key rust-mode-map (kbd "C-c C-l r") #'lsp-rename)

(add-hook 'rust-mode-hook #'lsp-deferred)

(add-hook 'rust-mode-hook #'cargo-minor-mode)
(add-hook 'toml-mode-hook #'cargo-minor-mode)

(add-hook 'racer-mode-hook #'company-mode)

(eval-after-load 'compile
  '(progn
     (setq compilation-error-regexp-alist-alist
           (delete (cons 'cargo (alist-get 'cargo compilation-error-regexp-alist-alist))
                   compilation-error-regexp-alist-alist))
     (add-to-list 'compilation-error-regexp-alist-alist
                  (list 'cargo
                        "', \\(\\([^:]+\\):\\([0-9]+\\)\\)"
                        2 3 nil nil 1))))

(defun radz-customize-rust-mode ()
  (setq read-process-output-max (* 1024 1024)
        lsp-idle-delay 0.75)
  (remove-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p))

(add-hook 'rust-mode-hook #'radz-customize-rust-mode)

(defun radz-colorize-cargo-output ()
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region (point-min) (point-max))))

;; (add-hook 'cargo-process-mode-hook
;;           (lambda ()
;;             (add-hook 'compilation-filter-hook #'radz-colorize-cargo-output)))

;; Flycheck Inline Setup

;; (with-eval-after-load 'flycheck
;;   (add-hook 'flycheck-mode-hook #'flycheck-inline-mode))

;; Relative import grouping

(cl-defstruct relative-import
  "Contains the match position data and crate for a single crate
  relative import line."
  match-markers
  import-string)

(defun radz-rust-replace-imports (crate-root relative-imports)
  "Replace all single imports with one nested import.

  For each group of imports with a common root crate: Write out
  one `use <root>::{' Write out each associated second
  capture match Write out `};'"
  ;; Figure out where the first relative-import line for this crate was
  (when (not (eql 1 (length relative-imports)))
   (let ((target-marker (copy-marker (first (relative-import-match-markers (first relative-imports))))))
     (dolist  (import relative-imports)
       (let ((begin-marker (first (relative-import-match-markers import)))
             (end-marker (second (relative-import-match-markers import))))
         ;; Delete each current relative import
         (delete-region begin-marker end-marker)
         ;; Remove both markers
         (set-marker begin-marker nil)
         (set-marker end-marker nil)))
     ;; Go to beginning of the first relative import
     (goto-char target-marker)
     ;; Format grouped import and insert
     (insert (format "%s::{" crate-root ))
     (dolist (import relative-imports)
       (insert (format "%s, " (relative-import-import-string import))))
     (insert "};\n"))))

(defun radz-rust-trim-match-data (match-markers)
  "Extract only the whole pattern match markers and push the end
  marker past the following newline."
  (let ((begin-marker (first match-markers))
        (end-marker (second match-markers)))
    (set-marker end-marker (+ 1 end-marker))
    (dolist (m (rest (rest match-markers)))
      (set-marker m nil))
    (list begin-marker end-marker)))

(defun radz-rust-group-imports ()
  "Group Rust imports by crate."
  (interactive)
  ;; Check that this a '*.rs' file
  (if (equal "rs" (file-name-extension buffer-file-name))
      (save-excursion
        ;; Go to beginning of buffer
        (goto-char (point-min))
        (let ((crate-use-statements (make-hash-table :test 'equal)))
         ;; Find all lines that look like: "^use \([a-zA-Z0-9]*?\)::\(.*?\);$"
          (while (re-search-forward "^\\( *use [[:alpha:]_][[:alnum:]_]*\\)::\\(.*\\);$" nil t)
           (let* ((crate-name (match-string 1))
                  (import (make-relative-import :match-markers (radz-rust-trim-match-data (match-data))
                                                :import-string (match-string 2)))
                  (relative-imports (cons import (gethash crate-name crate-use-statements '()))))
             ;; Group by first capture match, recording buffer positions
             (puthash crate-name relative-imports crate-use-statements)))
         (maphash (function radz-rust-replace-imports) crate-use-statements)))))


(defvar radz-popped-compilation-error-regexp '())

(defun radz-pop-compilation-regexp ()
  (interactive)
  (setq radz-popped-compilation-error-regexp
        (cons (car compilation-error-regexp-alist-alist)
              radz-popped-compilation-error-regexp))
  (setq compilation-error-regexp-alist-alist
        (cdr compilation-error-regexp-alist-alist)))

(defun radz-inline-module ()
  (interactive)
  (re-search-forward "mod \\(.*?\\);")
  (let* ((end-marker (match-end 0))
         (mod-name (match-string 1))
         (mod-filename (locate-file mod-name (list default-directory) '(".rs" "")
                                    (lambda (f) (if (file-directory-p f) 'dir-ok t)))))
    (if mod-filename
        (save-mark-and-excursion
          (goto-char end-marker)
          (insert-char ?})
          (with-restriction (- end-marker 1) end-marker
                            (insert-file-contents mod-filename nil nil nil t))
          (insert " {\n"))
      (message "could not find file %s" mod-filename))))

;;; rust.el ends here

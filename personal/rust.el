;;; rust.el --- My rust configuration

;;; Commentary:

;;; Code:

(prelude-require-packages '(rust-mode flycheck-rust racer company-racer toml-mode))

(require 'compile)
(require 'rust-mode)
(require 'racer)
(require 'toml-mode)

;; Racer setup

(setq racer-cmd (concat home-dir "/.cargo/bin/racer")
      racer-rust-src-path (concat home-dir "/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src")
      rust-format-on-save t
      rust-rustfmt-bin "rustfmt")

(define-key rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)
(define-key rust-mode-map (kbd "C-c C-c M-k") #'cargo-process-clippy)
(define-key rust-mode-map (kbd "C-c C-c C-e") #'cargo-process-current-file-expand)
(define-key rust-mode-map (kbd "C-c C-c M-e") #'cargo-process-current-file-expand-and-compile)

(add-hook 'rust-mode-hook #'cargo-minor-mode)
(add-hook 'toml-mode-hook #'cargo-minor-mode)

(add-hook 'racer-mode-hook #'company-mode)

(defun radz-deactivate-exec-save ()
  (remove-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p))

(add-hook 'rust-mode-hook #'radz-deactivate-exec-save)

(defun radz-colorize-cargo-output ()
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region (point-min) (point-max))))

(add-hook 'cargo-process-mode-hook
          (lambda ()
            (add-hook 'compilation-filter-hook #'radz-colorize-cargo-output)))

(defun radz-rust-group-imports ()
  "Group Rust imports "
  (interactive)
  ;; Check that this a '*.rs' file
  (if (equal "rs" (file-name-extension buffer-file-name))
      (save-excursion
        ;; Go to beginning of buffer
        (goto-char (point-min))
        (let ((crate-use-statements (make-hash-table :test 'equal)))
         ;; Find all lines that look like: "^use \([a-zA-Z0-9]*?\)::\(.*?\);$"
         (while (re-search-forward "^use \\([[:alpha:]_][[:alnum:]_]*\\)::\\([^{].*\\);" nil t)
           (let* ((use-line-matches (match-data))
                  (crate-name (match-string 1))
                  (relative-import (match-string 2))
                  (subcrate-imports (cons relative-import (gethash crate-name crate-use-statements '()))))
             (puthash crate-name subcrate-imports crate-use-statements)))
         (message "use matches: %s" crate-use-statements))

        ;; Group by first capture match, recording buffer positions
        ;;   An a-list of crate roots and import tails
        ;;   ((<crate-root> . (<import-tail>...)...)
        ;; For each group of imports with a common root crate:
        ;;   Write out one "use <root>::{"
        ;;   Write out each associated second capture match
        ;;   Write out "};"
        )))

;;; rust.el ends here

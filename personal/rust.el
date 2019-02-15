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
      rust-rustfmt-bin "rustfmt"
      cargo-process--command-clippy "+nightly clippy")

(defun cargo-process-expand ()
  "Run the Cargo expand command.
With the prefix argument, modify the command's invocation.
Cargo: Macro-expand the  current project.
Requires Cargo expand to be installed."
  (interactive)
  (cargo-process--start "Expand" "expand --color never"))

(defun cargo-process-current-file-expand ()
  "Run the Cargo expand command on the current file.
With the prefix argument, modify the command's invocation.
Requires cargo-expand to be installed."
  (interactive)
  (cargo-process--start "Expand" (concat "expand --color never --"
                                         (cargo-process--get-current-file-type)
                                         " "
                                         (file-name-base buffer-file-truename))))

(define-key rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)
(define-key rust-mode-map (kbd "C-c C-c M-k") #'cargo-process-clippy)
(define-key rust-mode-map (kbd "C-c C-c C-e") #'cargo-process-expand)
(define-key rust-mode-map (kbd "C-c C-c M-e") #'cargo-process-current-file-expand)

(add-hook 'rust-mode-hook 'cargo-minor-mode)
(add-hook 'toml-mode-hook 'cargo-minor-mode)

(add-hook 'racer-mode-hook #'company-mode)

(defun radz-deactivate-exec-save ()
  (remove-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p))

(add-hook 'rust-mode-hook 'radz-deactivate-exec-save)


;;; rust.el ends here

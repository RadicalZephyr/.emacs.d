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
      rust-rustfmt-bin "rustup run nightly fmt"
      cargo-process--command-clippy "+nightly clippy")

(define-key rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)
(define-key rust-mode-map (kbd "C-c C-c M-k") #'cargo-process-clippy)

(add-hook 'rust-mode-hook 'cargo-minor-mode)
(add-hook 'toml-mode-hook 'cargo-minor-mode)

(add-hook 'racer-mode-hook #'company-mode)

(defun rust-file-p ()
  "Check if the current file is a rust file."
  (string-suffix-p ".rs" (buffer-file-name) true))

(advice-add 'executable-make-buffer-file-executable-if-script-p :before-until #'rust-file-p)


;;; rust.el ends here

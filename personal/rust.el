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
      rust-rustfmt-bin "rustup run nightly fmt")

(define-key rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)

(defun radz-set-rust-build-command ()
  (set (make-local-variable 'compile-command)
       (if (locate-dominating-file (buffer-file-name) "Cargo.toml")
           "cargo build"
         "rustc *.rs")))

(add-hook 'rust-mode-hook 'radz-set-rust-build-command)
(add-hook 'toml-mode-hook 'radz-set-rust-build-command)

(add-hook 'racer-mode-hook #'company-mode)

;;; rust.el ends here

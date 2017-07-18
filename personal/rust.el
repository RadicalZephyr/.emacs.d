;;; rust.el --- My rust configuration

;;; Commentary:

;;; Code:

(prelude-require-packages '(rust-mode flycheck-rust racer company-racer toml-mode))

(require 'compile)
(require 'rust-mode)
(require 'toml-mode)

(defun radz-set-rust-build-command ()
  (set (make-local-variable 'compile-command)
       (if (locate-dominating-file (buffer-file-name) "Cargo.toml")
           "cargo build"
         "rustc *.rs")))

(add-hook 'rust-mode-hook 'radz-set-rust-build-command)
(add-hook 'toml-mode-hook 'radz-set-rust-build-command)

(add-hook 'rust-mode-hook #'racer-mode)
(add-hook 'racer-mode-hook #'eldoc-mode)

(add-hook 'rust-mode-hook #'rustfmt-enable-on-save)

(add-hook 'flycheck-mode-hook #'flycheck-rust-setup)
;;; rust.el ends here

(require 'compile)
(add-hook 'rust-mode-hook
          (lambda ()
            (set (make-local-variable 'compile-command)
                 (if (locate-dominating-file "Cargo.toml")
                     "cargo build"
                   "rustc *.rs"))))

(prelude-require-packages '(rust-mode rustfmt racer company-racer))

(add-hook 'rust-mode-hook #'racer-mode)
(add-hook 'racer-mode-hook #'eldoc-mode)

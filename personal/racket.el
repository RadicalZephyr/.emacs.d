(require 'use-package)
(require 'paredit)

(use-package racket-mode
  :ensure t
  :mode "\\.rkt\\'"
  :config
  (dolist (k '("RET" "C-m" "C-j"))
    (define-key paredit-mode-map (kbd k) nil)))

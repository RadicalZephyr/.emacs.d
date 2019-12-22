;;; racket.el --- My racket configuration

;;; Commentary:

;;; Code:

(prelude-require-packages '(racket-mode))

(require 'racket-mode)

(setq auto-mode-alist
      (append '(("\\.rkt\\'" . racket-mode)) auto-mode-alist))

;;; racket.el ends here

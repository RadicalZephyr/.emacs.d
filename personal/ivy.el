;;; ivy.el --- Custom Ivy setup

(prelude-require-packages '(
                            flx
                            ivy
                            ivy-avy
                            swiper
                            counsel
                            ))

(require 'flx)
(require 'ivy)
(require 'counsel)

(setq ivy-count-format "(%d/%d)"
      ivy-re-builders-alist '((t . ivy--regex-fuzzy)))


(global-set-key (kbd "C-c c k") 'counsel-bookmark)
(global-set-key (kbd "C-c c m") 'counsel-mark-ring)
(global-set-key (kbd "C-c c r") 'counsel-rg)
(global-set-key (kbd "C-h a") 'counsel-apropos)
(global-set-key (kbd "C-h f") 'counsel-describe-function)
(global-set-key (kbd "C-h v") 'counsel-describe-variable)
(global-set-key (kbd "C-h o") 'counsel-describe-symbol)

;;; ivy.el ends here

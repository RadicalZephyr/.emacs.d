(require 'use-package)
(require 'paredit)

;; I think this is unbinding 'paredit-newline because that triggers
;; local reindentation which conflicts with racket-mode's electric
;; reindentation.
(defun radz-unbind-paredit-newline ()
  (dolist (k '("RET" "C-m" "C-j"))
    (define-key paredit-mode-map (kbd k) nil)))

(use-package racket-mode
  :ensure t
  :mode "\\.rkt\\'"
  :hook (racket-mode . radz-unbind-paredit-newline))

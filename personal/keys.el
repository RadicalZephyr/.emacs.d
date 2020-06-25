;;; keys --- My personal keybindings

;;; Commentary:

;; Lots of little personalizations that I've built up over the years

;;; Code:

(global-set-key (kbd "C-x C-b") 'switch-to-buffer)
(global-set-key (kbd "C-x o")   'ace-window)
(global-set-key (kbd "C-x C-o") 'ace-window)
(global-set-key (kbd "C-x C-h") 'bury-buffer)

(global-set-key (kbd "C-c c j") 'avy-goto-char)
(global-set-key (kbd "C-c c u") 'unfill-paragraph)
(global-set-key (kbd "C-c c f") 'desktop-change-dir)
(global-set-key (kbd "C-c c b") 'ibuffer)
(global-set-key (kbd "C-c c g") 'find-grep-dired)
(global-set-key (kbd "C-c c o") 'occur)
(global-set-key (kbd "C-c c s") #'rg-menu)

(global-set-key [kp-subtract] 'undo)
(global-set-key [insert]    'overwrite-mode)
(global-set-key [kp-insert] 'overwrite-mode)

(global-set-key (kbd "M-n") 'goto-line)

(global-set-key (kbd "C-z") 'compile)
(global-set-key (kbd "C-c /") 'comment-or-uncomment-region)

(global-set-key [f12] 'man)

;; Swap regex-isearch and isearch
(global-set-key (kbd "C-r") 'isearch-backward-regexp)
(global-set-key (kbd "C-s") 'isearch-forward-regexp)

(global-set-key (kbd "C-M-r") 'isearch-backward)
(global-set-key (kbd "C-M-s") 'isearch-forward)

;; Swap line upwards
(global-set-key (kbd "C-c t")
                (lambda ()
                  (interactive)
                  (transpose-lines -1)))

(global-set-key (kbd "<C-up>")
                (lambda ()
                  (interactive)
                  (scroll-down 1)))

(global-set-key (kbd "<C-down>")
                (lambda ()
                  (interactive)
                  (scroll-up 1)))

(global-set-key (kbd "M-`") 'other-frame)
;;; keys.el ends here

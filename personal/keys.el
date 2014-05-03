;;; keys --- My personal keybindings

;;; Commentary:

;; Lots of little personalizations that I've built up over the years

;;; Code:

(global-set-key "%" 'goto-match-paren)
(global-set-key "\C-x\C-b" 'switch-to-buffer)
(global-set-key "\C-x\C-o" 'other-window)

(global-set-key "\C-ccu" 'unfill-paragraph)
(global-set-key "\C-ccf" 'desktop-change-dir)

(global-set-key [kp-subtract] 'undo)
(global-set-key [insert]    'overwrite-mode)
(global-set-key [kp-insert] 'overwrite-mode)

(global-set-key "\M-n" 'goto-line)

(global-set-key "\C-z" 'compile)
(global-set-key "\C-c/" 'comment-or-uncomment-region)

(global-set-key [f12] 'man)

;; Swap regex-isearch and isearch
(global-set-key "\C-r" 'isearch-backward-regexp)
(global-set-key "\C-s" 'isearch-forward-regexp)

(global-set-key "\C-\M-r" 'isearch-backward)
(global-set-key "\C-\M-s" 'isearch-forward)

;; Swap line upwards
(global-set-key "\C-ct" (lambda ()
                           (interactive)
                           (transpose-lines -1)))

(global-set-key (kbd "<C-up>") (lambda ()
                                 (interactive)
                                 (scroll-down 1)))

(global-set-key (kbd "<C-down>") (lambda ()
                                 (interactive)
                                 (scroll-up 1)))

;;; keys.el ends here

;; Desktop mode enhancements
(desktop-save-mode)
(dolist (pattern '("irc\..*" ; Keep irc buffers when
                   "#.+"))   ; switching desktops
  (add-to-list 'desktop-clear-preserve-buffers
               pattern))

(add-hook 'desktop-no-desktop-file-hook
          (lambda ()
            (dired default-directory)))

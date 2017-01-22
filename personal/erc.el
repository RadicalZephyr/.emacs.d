;; ERC Settings
(setq erc-nick "geoffs")
(setq erc-fill-column 72)
(setq erc-autojoin-channels-alist
      '(("freenode.net" "#clojure" "#emacs")))

(defun erc-ghost-maybe (server nick)
  "Send GHOST message to NickServ if NICK ends with `erc-nick-uniquifier'.
The function is suitable for `erc-after-connect'."
  (when (string-match (format "\\(.*?\\)%s+$" erc-nick-uniquifier) nick)
    (let ((nick-orig (match-string 1 nick))
          (password erc-session-password))
      (when (y-or-n-p (format "Current nick is '%s'. Do you want to ghost?"
                              nick))
        (erc-message "PRIVMSG" (format "NickServ GHOST %s %s"
                                       nick-orig password))
        (erc-cmd-NICK nick-orig)
        (erc-message "PRIVMSG" (format "NickServ identify %s %s"
                                       nick-orig password))))))
(add-hook 'erc-after-connect 'erc-ghost-maybe)

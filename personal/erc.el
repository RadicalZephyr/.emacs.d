;; ERC Settings

(require 'auth-source)
(require 'erc)

(setq
 erc-nick "radicalzephyr"
 erc-prompt-for-password nil
 erc-fill-column 89
 erc-autojoin-timing 'ident
 erc-autojoin-channels-alist
 '(("freenode.net" "#clojure" "#emacs" "#beagle"))
 )

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

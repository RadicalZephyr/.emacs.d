
(dolist (auto-mode-pair '(("\\.php\\'" . php-mode)
                          ("\\.rkt\\'" . scheme-mode)
                          ("\\.md\\'" . markdown-mode)
                          ("\\.markdown\\'" . markdown-mode)))
  (add-to-list 'auto-mode-alist
               auto-mode-pair))

(setq completion-ignored-extensions
      (append '(".ali" ".exe" ".beam")
              completion-ignored-extensions))

(require 'ido)
(ido-mode t)

(setq-default indent-tabs-mode nil)

(desktop-save-mode)

(put 'narrow-to-region 'disabled nil)

(ansi-color-for-comint-mode-on)

;; Mac specific changes
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta)
  (setenv "GIT_SSH" "/usr/bin/ssh")
  (setq special-display-regexps
        (remove "[ ]?\\*[hH]elp.*" special-display-regexps)))

;; Windows specific changes
(when (eq system-type 'windows-nt)
  (setq magit-git-executable "C:\\Program Files (x86)\\Git\\bin\\git.exe"))

;; School specific changes
(when (file-accessible-directory-p "/home/shannog")
  (add-to-list 'exec-path "/home/shannog/local/bin"))

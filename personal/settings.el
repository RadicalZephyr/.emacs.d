;;; settings --- My personal emacs settings

;;; Commentary:

;; Setup up my personal modifications

;;; Code:

;; Set my user-init-file to be this file
(setq prelude-user-init-file load-file-name)
(setq magit-last-seen-setup-instructions "1.4.0")

(dolist (auto-mode-pair '(("\\.php\\'" . php-mode)
                          ("\\.rkt\\'" . scheme-mode)
                          ("\\.md\\'" . markdown-mode)
                          ("\\.markdown\\'" . markdown-mode)
                          ("\.groovy$" . groovy-mode)
                          ("\.gradle$" . groovy-mode)
                          ("\\.xtm$" . extempore-mode)
                          ("\\.boot$" . clojure-mode)
                          ("\\.mustache$" . web-mode)))
  (add-to-list 'auto-mode-alist
               auto-mode-pair))

(dolist (auto-interpreter-pair '(("groovy" . groovy-mode)))
  (add-to-list 'interpreter-mode-alist auto-interpreter-pair))

(setq completion-ignored-extensions
      (append '(".ali" ".exe" ".beam")
              completion-ignored-extensions))

(setq-default indent-tabs-mode nil)

(setq prelude-guru nil)

;; Activate server mode
(server-start)

;; Desktop mode enhancements
(desktop-save-mode)
(dolist (pattern '("irc\..*" ; Keep irc buffers when
                   "#.+"))   ; switching desktops
  (add-to-list 'desktop-clear-preserve-buffers
               pattern))

(add-hook 'desktop-no-desktop-file-hook
          (lambda ()
            (dired default-directory)))

;; Compile setups
(setq compilation-always-kill nil)

;; Visual Modifications
(blink-cursor-mode 1)
(setq default-tab-width 2)
(setq x-stretch-cursor t)
(setq visible-bell t)
(ansi-color-for-comint-mode-on)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)
(set-frame-font "-*-Fira Mono-normal-normal-normal-*-16-*-*-*-m-0-iso10646-1")

;; Scrolling settings

(setq scroll-margin 5
      scroll-conservatively 10
      scroll-preserve-screen-position nil)

;; Enable some modes
(dolist (mode '(column-number-mode
                global-linum-mode
                ))
  (when (fboundp mode)
    (funcall mode)))

;; Disable some modes
(dolist (mode '(scroll-bar-mode
                tool-bar-mode
                menu-bar-mode))
  (when (fboundp mode)
    (funcall mode -1)))

;; Mac specific changes
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta)
  (setq mouse-wheel-scroll-amount '(0.00001))
  (setenv "GIT_SSH" "/usr/bin/ssh"))

;; Windows specific changes
(when (eq system-type 'windows-nt)
  (setq magit-git-executable "C:\\Program Files (x86)\\Git\\bin\\git.exe"))

;; ERC Settings
(setq erc-nick "geoffs")
(setq erc-fill-column 72)
(setq erc-autojoin-channels-alist
      '(("freenode.net" "#clojure" "#emacs"
         "#wwu-alumni" "#wwucs" "#wwu-devops")))

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

;; Packages and Stuff
(prelude-require-packages '(;; Great utilities
                            color-theme
                            magit
                            paredit
                            smart-tab
                            smartparens
                            exec-path-from-shell
                            lentic

                            ;; Clojure stuff
                            clj-refactor
                            cljsbuild-mode
                            clojure-cheatsheet

                            ;; PHP
                            flymake-php
                            php-mode

                            ;; Ruby
                            rbenv
                            inf-ruby
                            rinari
                            yari
                            ruby-tools
                            robe
                            rspec-mode
                            rubocop
                            ruby-guard

                            ;; R
                            ess
                            ess-smart-underscore

                            ;; flycheck
                            flycheck
                            flycheck-tip
                            flycheck-color-mode-line

                            ;; Other cool stuff
                            aggressive-indent
                            batch-mode
                            erefactor
                            gnuplot
                            gh-md
                            paradox
                            csharp-mode
                            fsharp-mode
                            groovy-mode
                            markdown-mode
                            markdown-mode+

                            ;; Snippets!!
                            yasnippet
                            java-snippets
                            clojure-snippets

                            yatemplate
                            ))

(require 'lentic)

(require 'exec-path-from-shell)
(exec-path-from-shell-initialize)

;; Yasnippet setups
(require 'yasnippet)
(yas-global-mode t)

(smartparens-global-mode t)

;; Clojure  setups
(require 'clojure-mode)

(define-clojure-indent
  (updating-coll-by 'defun)
  (defroutes 'defun)
  (GET 2)
  (POST 2)
  (PUT 2)
  (DELETE 2)
  (HEAD 2)
  (ANY 2)
  (context 2)
  (b-do 2)
  (listen 2)
  (for-all 1)
  (centered 2)
  (push 1)
  (game-loop 2)
  (describe 1)
  (it 1))

(require 'clj-refactor)

(add-hook 'clojure-mode-hook (lambda ()
                               (clj-refactor-mode 1)
                               (cljr-add-keybindings-with-prefix "C-c C-s")))

;; ESS setups
(require 'ess)
(require 'ess-site)

;; Csharp setups
(add-hook 'csharp-mode-hook
          (lambda ()
            (setq indent-tabs-mode t)
            (set (make-local-variable 'compile-command) "xbuild")))

;; Groovy setups

(require 'groovy-mode)

;; Lisp mode setups
(defun radz-paredit-no-smartparens ()
  "Deactivate smartparens in favor of paredit mode.

Meant for use with all Lisp modes"
  (smartparens-mode -1)
  (paredit-mode t))

(add-hook 'emacs-lisp-mode-hook 'radz-paredit-no-smartparens)
(add-hook 'scheme-mode-hook 'radz-paredit-no-smartparens)
(add-hook 'lisp-mode-hook 'radz-paredit-no-smartparens)
(add-hook 'clojure-mode-hook 'radz-paredit-no-smartparens)

(add-hook 'text-mode-hook (lambda ()
                            (smartparens-mode -1)
                            (auto-fill-mode 1)
                            (flyspell-mode 1)))

;; Android mode setups
(require 'android-mode)
(setq android-mode-sdk-dir (concat (getenv "HOME")
                                   "/local/android-sdk-linux"))

(require 'magit)
(add-hook 'magit-status-mode-hook (lambda ()
                                    (magit-refresh)))
;; CC-mode setups
(let ((indent-tabs '((c-offsets-alist
                      (case-label . +)))))
  (dolist (style '("user" "k&r" "java")) ;; Update some styles to
    (c-add-style style indent-tabs)))    ;; indent the case labels

;; JDEE setups
(add-to-list 'load-path
             (concat (file-name-as-directory prelude-personal-dir)
                     "jdee-2.4.1/lisp"))
(load "jde")

(setq  jde-import-auto-sort t
       jde-import-auto-sort-function (lambda () ;; Force reorganizing
                                       (jde-import-organize t))
       jde-import-blank-line-between-groups t
       jde-import-sorted-groups 'asc)

(setq jde-mode-line-format '("-" mode-line-mule-info mode-line-modified mode-line-frame-identification mode-line-buffer-identification " " global-mode-string
                             (line-number-mode "(%l,")
                             (column-number-mode "%c)")
                             (jde-which-method-mode
                              ("  " jde-which-method-format "  "))
                             "%[(" mode-name mode-line-process minor-mode-alist "%n" ")%] "
                             (-3 . "%p")))

(dolist (group-reg '(;; This is a clever regex that matches all but
                     ;; the classname of an import. Grouping for
                     ;; everybody!
                     ("^\\(\\([[:alnum:]]+\\.?\\)\\{1,3\\}\\)\\." . 1)))
  (add-to-list 'jde-import-group-of-rules
               group-reg t))

;; Add directories relative to HOME to classpath
(dolist (path
         '("local/android-sdk-linux/platforms/android-17/android.jar"))
  (let* ((home (file-name-as-directory
                (expand-file-name "~")))
         (fullpath (concat home path)))
    (add-to-list 'jde-global-classpath
                 fullpath)))

;; Setup android mode to work with gradle
(setq android-mode-builder 'gradle)

(add-to-list 'compilation-error-regexp-alist
             '("^:[[:alpha:]]*\\(/.*?\\):\\([[:digit:]]+\\): ?\\(error\\)"
               1 2 nil 2 1 (3 compilation-error-face)))

(setq user-extempore-directory
      "/usr/local/Cellar/extempore/0.53/")

;; Setup Web-mode indentations how I like
(setq web-mode-attr-indent-offset 2
      web-mode-code-indent-offset 2
      web-mode-css-indent-offset 2
      web-mode-markup-indent-offset 2
      web-mode-sql-indent-offset 2)

;;; settings.el ends here

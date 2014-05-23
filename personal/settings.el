;;; settings --- My personal emacs settings

;;; Commentary:

;; Setup up my personal modifications

;;; Code:

;; Set my user-init-file to be this file
(setq prelude-user-init-file load-file-name)

(dolist (auto-mode-pair '(("\\.php\\'" . php-mode)
                          ("\\.rkt\\'" . scheme-mode)
                          ("\\.md\\'" . markdown-mode)
                          ("\\.markdown\\'" . markdown-mode)
                          ("\.groovy$" . groovy-mode)
                          ("\.gradle$" . groovy-mode)))
  (add-to-list 'auto-mode-alist
               auto-mode-pair))

(dolist (auto-interpreter-pair '(("groovy" . groovy-mode)))
  (add-to-list 'interpreter-mode-alist auto-interpreter-pair))

(setq completion-ignored-extensions
      (append '(".ali" ".exe" ".beam")
              completion-ignored-extensions))

(setq-default indent-tabs-mode nil)

(setq prelude-guru nil)

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
(setq tab-width 2)
(setq x-stretch-cursor t)
(setq visible-bell t)
(ansi-color-for-comint-mode-on)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

;; Enable some modes
(dolist (mode '(column-number-mode
                global-linum-mode
                toggle-frame-maximized))
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
  (setenv "GIT_SSH" "/usr/bin/ssh"))

;; Windows specific changes
(when (eq system-type 'windows-nt)
  (setq magit-git-executable "C:\\Program Files (x86)\\Git\\bin\\git.exe"))

;; School specific changes
(when (file-accessible-directory-p "/home/shannog")
  (add-to-list 'exec-path "/home/shannog/local/bin"))

;; Packages and Stuff
(prelude-require-packages '(;; Great utilities
                            color-theme
                            magit
                            paredit
                            smart-tab
                            smartparens
                            exec-path-from-shell

                            ;; PHP
                            flymake-php
                            php-mode

                            ;; Ruby
                            inf-ruby
                            rinari
                            yari
                            ruby-tools

                            ;; R
                            ess
                            ess-smart-underscore

                            ;; flycheck
                            flycheck
                            flycheck-tip
                            flycheck-color-mode-line

                            ;; auto-complete sources
                            ac-c-headers
                            ac-etags
                            ac-inf-ruby
                            ac-ispell
                            ac-math
                            ac-octave

                            ;; Other cool stuff
                            batch-mode
                            erefactor
                            gnuplot
                            csharp-mode
                            fsharp-mode
                            groovy-mode
                            markdown-mode
                            markdown-mode+
                            yasnippet
                            java-snippets))

(require 'exec-path-from-shell)
(exec-path-from-shell-initialize)

;; Yasnippet setups
(require 'yasnippet)
(yas-global-mode t)

(smartparens-global-mode t)

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
                            (flyspell-mode 1)))

;; Android mode setups
(require 'android-mode)
(setq android-mode-sdk-dir (concat (getenv "HOME")
                                   "/local/android-sdk-linux"))

(require 'magit)

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
(setq android-mode-builder 'gradle
      android-mode-root-file "build.gradle")

(add-to-list 'compilation-error-regexp-alist
             '("^:[[:alpha:]]*\\(/.*?\\):\\([[:digit:]]+\\): ?\\(error\\)"
               1 2 nil 2 1 (3 compilation-error-face)))

;;; settings.el ends here

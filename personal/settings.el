;;; settings --- My personal emacs settings

;;; Commentary:

;; Setup up my personal modifications

;;; Code:

(dolist (auto-mode-pair '(("\\.php\\'" . php-mode)
                          ("\\.rkt\\'" . scheme-mode)
                          ("\\.md\\'" . markdown-mode)
                          ("\\.markdown\\'" . markdown-mode)))
  (add-to-list 'auto-mode-alist
               auto-mode-pair))

(setq completion-ignored-extensions
      (append '(".ali" ".exe" ".beam")
              completion-ignored-extensions))

(setq-default indent-tabs-mode nil)

(setq prelude-guru nil)

;; Desktop mode enhancements
(desktop-save-mode)
(dolist (pattern '("irc\..*"
                   "#.+"))
  (add-to-list 'desktop-clear-preserve-buffers
               pattern))

(add-hook 'desktop-no-desktop-file-hook
          (lambda ()
            (dired default-directory)))

(add-hook 'dired-load-hook
          (lambda ()
            (load "dired-x")))

;; Undisable some commands
(put 'narrow-to-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; Visual Modifications
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
                            android-mode
                            batch-mode
                            erefactor
                            gnuplot
                            csharp-mode
                            fsharp-mode
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

;; Csharp setups
(add-hook 'csharp-mode-hook
          (lambda ()
            (setq indent-tabs-mode t)
            (set (make-local-variable 'compile-command) "xbuild")))

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

;; Android mode setup
(require 'android-mode)
(setq android-mode-sdk-dir (concat (getenv "HOME") "/local/android-sdk-linux"))

(require 'magit)

;;; settings.el ends here

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

(desktop-save-mode)

(put 'narrow-to-region 'disabled nil)

(ansi-color-for-comint-mode-on)

(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

;; Visual Modifications
(setq default-tab-width 2)
(setq x-stretch-cursor t)

;; Enable some modes
(dolist (mode '(column-number-mode
                global-linum-mode
                toggle-frame-maximized))
  (when (fboundp mode)
    (funcall mode)))

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

;; Packages and Stuff
(prelude-require-packages '(;; Great utilities
                            color-theme
                            magit
                            smart-tab
                            smartparens
                            exec-path-from-shell

                            ;; Clojure
                            ac-cider-compliment
                            cider
                            clojure-mode
                            clojure-test-mode
                            clojure-cheatsheet
                            nrepl
                            nrepl-ritz
                            paredit

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
                            markdown-mode+))

(require 'exec-path-from-shell)
(exec-path-from-shell-initialize)

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

;;; settings.el ends here

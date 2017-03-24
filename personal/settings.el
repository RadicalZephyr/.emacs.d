;;; settings --- My personal emacs settings

;;; Commentary:

;; Setup up my personal modifications

;;; Code:

;; Set my user-init-file to be this file
(setq magit-last-seen-setup-instructions "1.4.0")

(setq-default indent-tabs-mode nil)

(setq prelude-guru nil)

;; Activate server mode
(server-start)

;; Compile setups
(setq compilation-always-kill nil)

(setq home-dir "/home/geoff")

;; Packages and Stuff
(prelude-require-packages '(;; Great utilities
                            color-theme
                            magit
                            magit-filenotify
                            git-timemachine
                            paredit
                            smart-tab
                            smartparens
                            exec-path-from-shell
                            lentic

                            ;; Common lisp stuff
                            slime
                            slime-company
                            common-lisp-snippets

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
                            ruby-refactor

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

;; Company mode on tab by default

(global-set-key (kbd "TAB") #'company-indent-or-complete-common)

;; Ido/everywhere/ubiquitous settings
(ido-everywhere +1)
(setq ido-use-filename-at-point nil)

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
  (fdef 'defun)
  (updating-coll-by 'defun)
  (defroutes 'defun)
  (routes 'defun)
  (GET 'defun)
  (POST 'defun)
  (PUT 'defun)
  (DELETE 'defun)
  (HEAD 'defun)
  (ANY 'defun)
  (fact 1)
  (facts 1)
  (context 1)
  (b-do 2)
  (listen 2)
  (for-all 1)
  (centered 2)
  (push 1)
  (game-loop 2)
  (around 'defun)
  (after 'defun)
  (before 'defun)
  (with 'defun)
  (describe 'defun)
  (context 'defun)
  (it 'defun)
  (xit 'defun)
  (alter-var-root 1)
  (html-fn 'defun)
  (:require 0)
  (expect 'defun)
  (expect-let 'defun)
  (given 'defun)
  (freeze-time 1)
  (redef-state 1)
  (from-each 1)
  (trace-forms 'defun))

(require 'clj-refactor)

(add-hook 'clojure-mode-hook (lambda ()
                               (clj-refactor-mode 1)
                               (cljr-add-keybindings-with-prefix "C-c C-s")))

;; ESS setups
;; (require 'ess)
;; (require 'ess-site)

;; Csharp setups
(add-hook 'csharp-mode-hook
          (lambda ()
            (setq indent-tabs-mode t)
            (set (make-local-variable 'compile-command) "xbuild")))

;; Groovy setups

;; (require 'groovy-mode)

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
(add-hook 'cider-repl-mode-hook 'radz-paredit-no-smartparens)

(add-hook 'text-mode-hook (lambda ()
                            (smartparens-mode -1)
                            (auto-fill-mode 1)
                            (flyspell-mode 1)))

;; Android mode setups
;; (require 'android-mode)
(setq android-mode-sdk-dir (concat (getenv "HOME")
                                   "/.local/android-sdk-linux"))

(require 'magit)
(global-magit-file-buffer-mode)

;; CC-mode setups
(let ((indent-tabs '((c-offsets-alist
                      (case-label . +)))))
  (dolist (style '("user" "k&r" "java")) ;; Update some styles to
    (c-add-style style indent-tabs)))    ;; indent the case labels

;; JDEE setups
;; (add-to-list 'load-path
;;              (concat (file-name-as-directory prelude-personal-dir)
;;                      "jdee-2.4.1/lisp"))
;; (load "jde")

;; (setq  jde-import-auto-sort t
;;        jde-import-auto-sort-function (lambda () ;; Force reorganizing
;;                                        (jde-import-organize t))
;;        jde-import-blank-line-between-groups t
;;        jde-import-sorted-groups 'asc)

;; (setq jde-mode-line-format '("-" mode-line-mule-info mode-line-modified mode-line-frame-identification mode-line-buffer-identification " " global-mode-string
;;                              (line-number-mode "(%l,")
;;                              (column-number-mode "%c)")
;;                              (jde-which-method-mode
;;                               ("  " jde-which-method-format "  "))
;;                              "%[(" mode-name mode-line-process minor-mode-alist "%n" ")%] "
;;                              (-3 . "%p")))

;; (dolist (group-reg '(;; This is a clever regex that matches all but
;;                      ;; the classname of an import. Grouping for
;;                      ;; everybody!
;;                      ("^\\(\\([[:alnum:]]+\\.?\\)\\{1,3\\}\\)\\." . 1)))
;;   (add-to-list 'jde-import-group-of-rules
;;                group-reg t))

;; Add directories relative to HOME to classpath
;; (dolist (path
;;          '("local/android-sdk-linux/platforms/android-17/android.jar"))
;;   (let* ((home (file-name-as-directory
;;                 (expand-file-name "~")))
;;          (fullpath (concat home path)))
;;     (add-to-list 'jde-global-classpath
;;                  fullpath)))

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

;; Common Lisp!

(setq inferior-lisp-program "/usr/local/bin/sbcl")

;; Racer setup

(setq racer-cmd (concat home-dir "/.cargo/bin/racer")
      racer-rust-src-path (concat home-dir "/src/rust/src"))

;; Enable disabled things
(put 'set-goal-column 'disabled nil)

;;; settings.el ends here

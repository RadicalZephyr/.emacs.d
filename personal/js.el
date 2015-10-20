(add-hook 'js2-mode-hook (lambda ()
                           (setq c-basic-offset 2
                                 js-indent-level 2
                                 js2-basic-offset 2)))

(prelude-require-package 'jasminejs-mode)

(add-hook 'js2-mode-hook (lambda ()
                           (jasminejs-mode)))
(add-hook 'jasminejs-mode-hook (lambda ()
                                 (jasminejs-add-snippets-to-yas-snippet-dirs)))

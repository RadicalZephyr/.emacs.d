(defun radz-set-js-offset ()
    "Set js offset to 2 probably"
  (setq c-basic-offset 2
        js-indent-level 2
        js2-basic-offset 2))

(add-hook 'js2-mode-hook 'radz-set-js-offset)
(add-hook 'json-mode-hook 'radz-set-js-offset)

(prelude-require-package 'jasminejs-mode)

(add-hook 'js2-mode-hook (lambda ()
                           (jasminejs-mode)))
(add-hook 'jasminejs-mode-hook (lambda ()
                                 (jasminejs-add-snippets-to-yas-snippet-dirs)))

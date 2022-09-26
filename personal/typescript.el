(with-eval-after-load 'typescript-mode
  (defun radz-ts-mode-setup ()
    (interactive)
    (setq lsp-ui-doc-show-with-cursor t))

  (when (featurep 'prelude-lsp)
    (add-hook 'typescript-mode-hook 'lsp)
    (add-hook 'typescript-mode-hook #'radz-ts-mode-setup)))

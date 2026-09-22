(defun radz-customize-markdown ()
  (setq fill-column 90))

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  :config (add-hook 'markdown-mode-hook #'radz-customize-markdown))

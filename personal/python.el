(require 'use-package)

(use-package pipenv
  :ensure t
  :config
  (add-hook 'python-mode-hook #'pipenv-mode))

(use-package pytest
  :ensure t
  :config
  (add-hook 'python-mode-hook
            (lambda ()
              (local-set-key (kbd "C-c C-a") 'pytest-all)
              ;; (local-set-key "\C-cm" 'pytest-module)
              ;; (local-set-key "\C-c." 'pytest-one)
              ;; (local-set-key "\C-cd" 'pytest-directory)
              ;; (local-set-key "\C-cpa" 'pytest-pdb-all)
              ;; (local-set-key "\C-cpm" 'pytest-pdb-module)
              ;; (local-set-key "\C-cp." 'pytest-pdb-one)
              )))

(require 'use-package)

(use-package pipenv
  :ensure t
  :config
  (add-hook 'python-mode-hook #'pipenv-mode))

(use-package pytest
  :ensure t
  :bind (:map python-mode-map
         ("C-c C-a" . pytest-all)
         ("C-c m" . pytest-module)
         ("C-c ." . pytest-one)
         ("C-c d" . pytest-directory)
         ("C-c p a" . pytest-pdb-all)
         ("C-c p m" . pytest-pdb-module)
         ("C-c p ." . pytest-pdb-one)))

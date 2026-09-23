(use-package tramp
  :config
  (add-to-list 'tramp-default-user-alist '("podman" "^\\(?:dev\\|bwapi\\)$" "zefs"))
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

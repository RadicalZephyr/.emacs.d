(require 'use-package)

(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c C-l")
  :hook (;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands (lsp lsp-deferred)
  :config
  (setq read-process-output-max (* 1024 1024)
        lsp-idle-delay 0.75
        ;; File watchers over TRAMP stat the whole dependency tree through
        ;; `podman exec'.  Unusable on a Bevy project.
        lsp-enable-file-watchers nil)

  ;; lsp-mode needs one client registration per remote server.  Without
  ;; `:remote? t' it falls back to the local client — and because $HOME is
  ;; shared with the distrobox, the de-prefixed path resolves on the host
  ;; too, so rust-analyzer silently runs outside the container.
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-tramp-connection "rust-analyzer")
    :major-modes '(rust-mode rustic-mode rust-ts-mode)
    :remote? t
    :server-id 'rust-analyzer-remote)))

(use-package lsp-ui :commands lsp-ui-mode)

;; optionally
;; (use-package lsp-treemacs :commands lsp-treemacs-errors-list)

;; optionally if you want to use debugger
;; (use-package dap-mode)
;; (use-package dap-LANGUAGE) to load the dap adapter for your language

;; optional if you want which-key integration
;; prelude already enables which-key
;; (use-package which-key
;;   :config
;;   (which-key-mode))

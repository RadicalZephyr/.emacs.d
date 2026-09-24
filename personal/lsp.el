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
        ;; rust-analyzer watches files itself when the client doesn't,
        ;; and lsp-mode's watchers prompt on a Bevy-sized tree.
        lsp-enable-file-watchers nil))

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

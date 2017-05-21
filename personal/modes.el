(dolist (auto-mode-pair '(("\\.php\\'" . php-mode)
                          ("\\.rkt\\'" . scheme-mode)
                          ("\\.md\\'" . markdown-mode)
                          ("\\.markdown\\'" . markdown-mode)
                          ("\.groovy$" . groovy-mode)
                          ("\.gradle$" . groovy-mode)
                          ("\\.xtm$" . extempore-mode)
                          ("\\.boot$" . clojure-mode)
                          ("\\.gpr$" . ada-mode)
                          ("\\.mustache$" . web-mode)
                          ("\\.cljt$" . clojure-mode)))
  (add-to-list 'auto-mode-alist
               auto-mode-pair))

(dolist (auto-interpreter-pair '(("groovy" . groovy-mode)))
  (add-to-list 'interpreter-mode-alist auto-interpreter-pair))

(setq completion-ignored-extensions
      (append '(".ali" ".exe" ".beam" ".class")
              completion-ignored-extensions))

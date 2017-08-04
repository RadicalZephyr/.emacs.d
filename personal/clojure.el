(defun speclj-test-ns-fn (ns)
  "For a NS, return the test namespace, which may be the argument itself.
This uses the Leiningen convention of appending '-test' to the namespace name."
  (when ns
    (let ((suffix "-spec"))
      ;; string-suffix-p is only available in Emacs 24.4+
      (if (string-match (rx-to-string `(: ,suffix eos) t) ns)
          ns
        (concat ns suffix)))))

(defun speclj-activate-speclj-dev ()
  (interactive)
  (setq cider-test-infer-test-ns 'speclj-test-ns-fn))

(setenv "EXPECTATIONS_COLORIZE" "false")

(setq cider-boot-parameters "repl -s watch notify -v refresh")

(require 'clojure-mode)

(require 'clj-refactor)

(add-hook 'clojure-mode-hook (lambda ()
                               (clj-refactor-mode 1)
                               (cljr-add-keybindings-with-prefix "C-c C-s")))

(define-clojure-indent
  (fdef 'defun)
  (updating-coll-by 'defun)
  (defroutes 'defun)
  (routes 'defun)
  (GET 'defun)
  (POST 'defun)
  (PUT 'defun)
  (DELETE 'defun)
  (HEAD 'defun)
  (ANY 'defun)
  (fact 1)
  (facts 1)
  (context 1)
  (b-do 2)
  (listen 2)
  (for-all 1)
  (centered 2)
  (push 1)
  (game-loop 2)
  (around 'defun)
  (after 'defun)
  (before 'defun)
  (with 'defun)
  (describe 'defun)
  (context 'defun)
  (it 'defun)
  (xit 'defun)
  (alter-var-root 1)
  (html-fn 'defun)
  (:require 0)
  (expect 'defun)
  (expect-let 'defun)
  (given 'defun)
  (freeze-time 1)
  (redef-state 1)
  (from-each 1)
  (trace-forms 'defun))

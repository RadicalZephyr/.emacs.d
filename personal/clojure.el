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

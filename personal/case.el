(defun camel-case (s)
  (mapconcat (function capitalize) (split-string s "[_-]") ""))

(require 'grep)
(require 'find-dired)

(defun find-grep-dired-no-target (dir regexp)
  "Find files in DIR that contain matches for REGEXP and start Dired on output.
The command run (after changing into DIR) is

  find . \\( -path target -prune \\) -o \\( -type f -exec `grep-program' `find-grep-options' \\
    -e REGEXP {} \\; \\) -ls

where the first string in the value of the variable `find-ls-option'
specifies what to use in place of \"-ls\" as the final argument."
  ;; Doc used to say "Thus ARG can also contain additional grep options."
  ;; i) Presumably ARG == REGEXP?
  ;; ii) No it can't have options, since it gets shell-quoted.
  (interactive "DFind-grep (directory): \nsFind-grep (grep regexp): ")
  ;; find -exec doesn't allow shell i/o redirections in the command,
  ;; or we could use `grep -l >/dev/null'
  ;; We use -type f, not ! -type d, to avoid getting screwed
  ;; by FIFOs and devices.  I'm not sure what's best to do
  ;; about symlinks, so as far as I know this is not wrong.
  (find-dired dir
              (concat
               (shell-quote-argument "(")
               " -type d "
               (shell-quote-argument "(")
               " -name target -o -name .git "
               (shell-quote-argument ")")
               " -prune "
               (shell-quote-argument ")")
               " -o "
               (shell-quote-argument "(")
               " -type f -exec "
               grep-program
               " "
               find-grep-options
               " -e "
               (shell-quote-argument regexp)
               " "
               (shell-quote-argument "{}")
               " "
               ;; Doesn't work with "+".
               (shell-quote-argument ";")
               " "
               (shell-quote-argument ")"))))

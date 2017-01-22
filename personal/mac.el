;; Mac specific changes
(when (eq system-type 'darwin)
  (setq mac-command-modifier      'meta
        mouse-wheel-scroll-amount '(0.00000000000000000000001)
        home-dir "/Users/geoff")
  (setenv "GIT_SSH" "/usr/bin/ssh"))

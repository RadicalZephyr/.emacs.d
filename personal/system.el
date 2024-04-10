;; Clipboard settings
(when (not (eq window-system 'w32))
  (prelude-require-package xclip)

  ((xclip-mode 1))
  (setq
   select-enable-clipboard t
   select-enable-primary   t))

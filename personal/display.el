(when (window-system)
  (toggle-frame-maximized))

;; Change default font size for everything forever
(set-face-attribute 'default nil :height 110)
;; for low DPI screens
;; (set-face-attribute 'default nil :height 50)

;; Visual Modifications
(blink-cursor-mode 1)
(setq default-tab-width 2)
(setq x-stretch-cursor t)
(setq visible-bell t)
(ansi-color-for-comint-mode-on)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)

;; Scrolling settings

(setq scroll-margin 5
      scroll-conservatively 10
      scroll-preserve-screen-position nil)

;; Enable some modes
(dolist (mode '(column-number-mode
                global-linum-mode
                ))
  (when (fboundp mode)
    (funcall mode)))

;; Disable some modes
(dolist (mode '(scroll-bar-mode
                tool-bar-mode
                menu-bar-mode))
  (when (fboundp mode)
    (funcall mode -1)))

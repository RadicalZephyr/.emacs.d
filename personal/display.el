(when (window-system)
  (toggle-frame-maximized))

(defun radz-reset-default-font-height ()
  "Set the font height to my favored default."
  (interactive)
  (set-face-attribute 'default nil :height 110))

;; Change default font size for everything forever
(radz-reset-default-font-height)
(global-set-key (kbd "C-c C-f") 'radz-reset-default-font-height)

;; for low DPI screens
;; (set-face-attribute 'default nil :height 50)

;; Visual Modifications
(ansi-color-for-comint-mode-on)
(blink-cursor-mode 1)
(setq
 default-tab-width           2
 uniquify-buffer-name-style 'post-forward-angle-brackets
 visible-bell                t
 x-stretch-cursor            t
 redisplay-dont-pause        nil
 )

;; Scrolling settings

(setq
 scroll-conservatively           10
 scroll-margin                   5
 scroll-preserve-screen-position nil
 )

;; Enable some modes
(dolist (mode '(column-number-mode
                ))
  (when (fboundp mode)
    (funcall mode)))

;; Disable some modes
(dolist (mode '(scroll-bar-mode
                tool-bar-mode
                menu-bar-mode))
  (when (fboundp mode)
    (funcall mode -1)))

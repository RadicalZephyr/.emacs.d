;;; globals --- Set up global variables used in my personal setting

;;; Commentary:

;; Set up global variables used in my personal setting

;;; Code:

(setq home-dir (getenv "HOME"))

(add-to-list 'package-archives
             '("non-gnu" . "https://elpa.nongnu.org/nongnu/"))

;;; globals.el ends here

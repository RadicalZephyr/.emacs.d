;;; config-files.el --- configure where various packages store data  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Zefira Shannon

;; Author: Zefira Shannon <zefs@pop-os>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(eval-after-load 'anaconda-mode
  '(progn
     (setq anaconda-mode-installation-directory
           (expand-file-name "anaconda-mode" prelude-vendor-dir))))

(eval-after-load 'multiple-cursors
  '(progn
     (setq mc/list-file (expand-file-name ".mc-lists.el" prelude-personal-dir))))

;;; config-files.el ends here

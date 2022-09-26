;;; org-export.el --- Customization for exporting org files to LaTeX  -*- lexical-binding: t; -*-

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

;;

;;; Code:

(prelude-require-packages '(ox-pandoc ox-reveal ox-timeline))

(require 'ox-latex)

;; Setup adapted from https://www.aidanscannell.com/post/org-mode-resume/
(eval-after-load 'ox-latex
  '(progn
     (setq org-latex-pdf-process
           ;; Use latexmk with xelatex
           '("latexmk -pvc -pdfxe %f")

           ;; stop org adding hypersetup{author..} to latex export
           org-latex-with-hyperref nil

           ;;
           ;; org-latex-prefer-user-labels t

           ;; deleted unwanted file extensions after latexMK
           org-latex-logfiles-extensions '("lof" "lot" "tex~" "aux" "idx" "log"
                                           "out" "toc" "nav" "snm" "vrb" "dvi"
                                           "fdb_latexmk" "blg" "brf" "fls" "entoc"
                                           "ps" "spl" "bbl" "xmpi" "run.xml" "bcf"
                                           "acn" "acr" "alg" "glg" "gls" "ist"))

     ;; Why is this here????
     (unless (boundp 'org-latex-classes)
       (setq org-latex-classes nil))))

;;; org-export.el ends here

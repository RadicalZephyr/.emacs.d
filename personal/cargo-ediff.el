;;; cargo-ediff.el --- Cargo Process Major Mode Ediff Extension -*-lexical-binding: t-*-

;; Copyright (C) 2020  Zephyr Shannon

;; Author: Zephyr Shannon <earthlingzephyr@gmail.com>
;; Keywords: processes, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Cargo Process Ediff Extension Sets up the output of assert_eq!()
;; failures as buttons that format the left and right ouput and invoke
;; ediff to allow viewing a

;;
;;; Code:

(prelude-require-packages '(cargo))

(require 'compile)
(require 'button)
(require 'cargo-process)
(require 'ediff-util)

(defconst cargo-process--shell-escape-code-regex "\\[[[:digit:];]+m\\(.*?\\)\\[0m"
  "A regular expression to match shell escape codes.")

(defconst cargo-process--assert-eq-prefix-regex "thread '.*?' panicked at 'assertion failed: `(left == right)`"
  "A regular expression to match the assert-eq output prefix.")

(defconst cargo-process--assert-eq-left-regex "left: `\\(.*?\\)`,"
  "A regular expression to match assert_eq left output.")

(defconst cargo-process--assert-eq-right-regex "right: `\\(.*?\\)`',"
  "A regular expression to match assert_eq right output.")

(defconst cargo-process--assert-diff-fmt-prefix "const _: T = "
  "String to prefix values to allow formatting with Rustfmt")

(defconst cargo-process--assert-diff-fmt-suffix ";"
  "String to suffix values to allow formatting with Rustfmt")

(define-button-type 'rustc-assert-eq-diff
  'follow-link t
  'face 'cargo-process--warning-face
  'action #'cargo-process--ediff-assert-eq)

(defun cargo-process--get-assert-eq-region (end regex)
  "Find the beginning and end of the next occurence of REGEX after position END."
  (save-excursion
    (goto-char end)
    (when (re-search-forward regex nil t 1)
      (list (match-beginning 1) (match-end 1)))))

(defun cargo-process--copy-region-to-buffer (to-buf region)
  (let ((from-buf (current-buffer))
        (temp-file (make-temp-file (buffer-name to-buf))))
    (message "Copying region (%s, %s) from %s" (cl-first region) (cl-second region) (buffer-name from-buf))
    (with-temp-file temp-file
      (insert cargo-process--assert-diff-fmt-prefix)
      (insert-buffer-substring-no-properties from-buf (cl-first region) (cl-second region))
      (insert cargo-process--assert-diff-fmt-suffix))
    (call-process "rustfmt" nil nil nil temp-file)
    (save-current-buffer
      (set-buffer to-buf)
      (insert-file-contents-literally temp-file nil)
      (set-buffer-modified-p nil)
      (point-max))))

(defun cargo-process--ediff-janitor ()
  (ediff-janitor nil nil))

(defun cargo-process--assert-eq-ediff-startup ()
  (add-hook 'ediff-cleanup-hook #'cargo-process--ediff-janitor))

(defun cargo-process--ediff-assert-eq (button)
  "Action called when the user activates assert-eq diff BUTTON"
  (let* ((end (button-end button))
         (left-region (cargo-process--get-assert-eq-region end cargo-process--assert-eq-left-regex))
         (right-region (cargo-process--get-assert-eq-region end cargo-process--assert-eq-right-regex))
         (left-buf (generate-new-buffer "LEFT"))
         (right-buf (generate-new-buffer "RIGHT"))
         (reg-left-end (cargo-process--copy-region-to-buffer left-buf left-region))
         (reg-right-end (cargo-process--copy-region-to-buffer right-buf right-region)))
    (cargo-process--copy-region-to-buffer left-buf left-region)
    (cargo-process--copy-region-to-buffer right-buf right-region)
    (ediff-regions-internal
     left-buf 1 reg-left-end
     right-buf 1 reg-right-end
     (list #'cargo-process--assert-eq-ediff-startup)
     'ediff-regions-wordwise 'word-mode nil)))

(defun cargo-process--add-assert-eq-buttons ()
  "Turn assert_eq output into clickable links in Cargo process output.
Meant to be run as a `compilation-filter-hook'."
  (save-excursion
    (let ((start compilation-filter-start)
          (end (point)))
      (goto-char start)
      (while (re-search-forward cargo-process--assert-eq-prefix-regex end t)
        (make-text-button (match-beginning 0)
                          (match-end 0)
                          :type 'rustc-assert-eq-diff)))))

(defun cargo-process--setup-assert-eq-ediff ()
  (add-hook 'compilation-filter-hook #'cargo-process--add-assert-eq-buttons))

(add-hook 'cargo-process-mode-hook #'cargo-process--setup-assert-eq-ediff)

;;; cargo-ediff.el ends here

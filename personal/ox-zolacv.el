;;; ox-zolacv.el --- LaTeX zolacv Back-End for Org Export Engine -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Free Software Foundation, Inc.

;; Author: Oscar Najera <hi AT oscarnajera.com DOT com>, Zefira Shannon <zefira AT hey DOT com>
;; Keywords: org, wp, tex

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This library implements a LaTeX zolacv back-end, derived from the
;; LaTeX one.

;;; Code:
(require 'ox-hugo)

;;; User-Configurable Variables

(defgroup org-export-zolacv nil
  "Options for exporting Org mode files to Markdown compatible with the Zola static site generator."
  :tag "Org Export Zola CV"
  :group 'org-export
  :version "1.0")

;;; Define Back-End
(org-export-define-derived-backend 'zolacv 'hugo
  :options-alist
  '(
    (:mobile "MOBILE" nil nil parse)
    (:homepage "HOMEPAGE" nil nil parse)
    (:address "ADDRESS" nil nil newline)
    (:photo "PHOTO" nil nil parse)
    (:gitlab "GITLAB" nil nil parse)
    (:github "GITHUB" nil nil parse)
    (:stack-overflow "STACKOVERFLOW" nil nil parse)
    (:linkedin "LINKEDIN" nil nil parse)
    (:with-email nil "email" t t)
    )
  :translate-alist '((headline . org-zolacv-headline)
                     (inner-template . org-zolacv-inner-template)))


(defun org-zolacv-utils--org-timestamp-to-shortdate (date_str)
  "Format orgmode timestamp DATE_STR  into a short form date.
Other strings are just returned unmodified

e.g. <2012-08-12 Mon> => Aug 2012
today => today"
  (if (string-match (org-re-timestamp 'all) date_str)
      (let* ((dte (org-parse-time-string date_str))
             (month (nth 4 dte))
             (year (nth 5 dte))) ;;'(02 07 2015)))
        (concat
         (calendar-month-name month 'abbreviate) " " (number-to-string year)))
    date_str))

(defun org-zolacv-utils--format-time-window (from-date to-date)
  "Join date strings in a time window.
FROM-DATE -- TO-DATE
in case TO-DATE is nil return Present.
If both dates are the same, return just FROM-DATE"
  (let ((from (when from-date (org-zolacv-utils--org-timestamp-to-shortdate from-date)))
        (to (if (not to-date) "Present"
              (org-zolacv-utils--org-timestamp-to-shortdate to-date))))

    (if from
        (if (string= from to)
            from
          (concat from " -- " to))
      "")))

(defun org-zolacv-utils--parse-cvproject (headline info)
  "Return alist describing the entry in HEADLINE.
INFO is a plist used as a communication channel."
  (let ((title (org-export-data (org-element-property :title headline) info)))
    `((title . ,title)
      (tech-tags . ,(org-element-property :TECH headline))
      (url . ,(org-element-property :URL headline)))))

(defun org-zolacv-utils--parse-cventry (headline info)
  "Return alist describing the entry in HEADLINE.
INFO is a plist used as a communication channel."
  (let ((title (org-export-data (org-element-property :title headline) info)))
    `((title . ,title)
      (from-date . ,(or (org-element-property :FROM headline)
                        (error "No FROM property provided for cventry %s" title)))
      (to-date . ,(org-element-property :TO headline))
      (tech-tags . ,(org-element-property :TECH headline))
      (employer . ,(org-element-property :EMPLOYER headline))
      (location . ,(or (org-element-property :LOCATION headline) "")))))

(defun org-zolacv-utils--format-tags (tags)
  "Return a string of HTML formatting the given list of tags."
  (if tags
      (concat
       "
    <li class=\"fa fa-tags\">
      <ul class=\"cventry-tags\">
"
       (mapconcat (lambda (tag)
                    (format "        <li class=\"cventry-tag\">%s</li>" tag))
                  (split-string tags " ")
                  "\n")
       "
      </ul>
    </li>
")
    ""))

(defun org-zolacv--format-cvproject (headline contents info)
  "Format HEADLINE as as cvproject.
CONTENTS holds the contents of the headline.  INFO is a plist used
as a communication channel."
  (let* ((entry (org-zolacv-utils--parse-cvproject headline info))
         (loffset (string-to-number (plist-get info :hugo-level-offset))) ;"" -> 0, "0" -> 0, "1" -> 1, ..
         (level (org-export-get-relative-level headline info))
         (title (concat (make-string (+ loffset level) ?#) " " (alist-get 'title entry))))
    (format "\n%s

<ul class=\"cventry\">
  <li class=\"fa fa-home\"> <a href=\"%s\">%s</a></li>%s

%s
"
            title
            (alist-get 'url entry)
            (alist-get 'url entry)
            (org-zolacv-utils--format-tags (alist-get 'tech-tags entry))
            contents)))

(defun org-zolacv--format-cventry (headline contents info)
  "Format HEADLINE as as cventry.
CONTENTS holds the contents of the headline.  INFO is a plist used
as a communication channel."
  (let* ((entry (org-zolacv-utils--parse-cventry headline info))
         (loffset (string-to-number (plist-get info :hugo-level-offset))) ;"" -> 0, "0" -> 0, "1" -> 1, ..
         (level (org-export-get-relative-level headline info))
         (title (concat (make-string (+ loffset level) ?#) " " (alist-get 'title entry))))
    (format "\n%s

<ul class=\"cventry\">
    <li class=\"fa fa-building\"> %s</li>
    <li class=\"fa fa-map-marker\"> %s</li>
    <li class=\"fa fa-calendar\"> %s</li>%s
</ul>

%s
" title
(alist-get 'employer entry)
(alist-get 'location entry)
(org-zolacv-utils--format-time-window (alist-get 'from-date entry) (alist-get 'to-date entry))
(org-zolacv-utils--format-tags (alist-get 'tech-tags entry))
contents)))



;;;; Headline
(defun org-zolacv-headline (headline contents info)
  "Transcode HEADLINE element into zolacv code.
CONTENTS is the contents of the headline.  INFO is a plist used
as a communication channel."
  (unless (org-element-property :footnote-section-p headline)
    (let ((environment (let ((env (org-element-property :CV_ENV headline)))
                         (or (org-string-nw-p env) "block"))))
      (cond
       ;; is a cv entry
       ((equal environment "cventry")
        (org-zolacv--format-cventry headline contents info))
       ((equal environment "cvproject")
        (org-zolacv--format-cvproject headline contents info))
       ((org-export-with-backend 'hugo headline contents info))))))

(defun org-zolacv-inner-template (contents info)
  "Return body of document after converting it to Zola-compatible markdown.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat "<ul id=\"cvcontacts\">\n"
          ;; email
          (let ((email (and (plist-get info :with-email)
                            (org-export-data (plist-get info :email) info))))
            (when (org-string-nw-p email)
              (format "<li class=\"fa fa-envelope\"><a href=\"mailto:%s\"> %s</a></li>\n" email email)))
          ;; homepage
          (let ((homepage (org-export-data (plist-get info :homepage) info)))
            (when (org-string-nw-p homepage) (format "<li class=\"fa fa-globe\"><a href=\"https://%s\"> %s</a></li>\n" homepage homepage)))
          ;; stack-overflow

          (let ((stack-overflow (org-export-data (plist-get info :stack-overflow) info)))
            (when (org-string-nw-p stack-overflow)
              (let ((so-data (split-string stack-overflow " ")))
               (format "<li class=\"fa fa-stack-overflow\"><a href=\"https://www.stackoverflow.com/users/%s/%s\"> %s</a></li>\n"
                       (nth 0 so-data)
                       (nth 1 so-data)
                       (capitalize (nth 1 so-data))))))
          ;; social media
          (mapconcat (lambda (social-network)

                       (let ((network (org-export-data
                                       (plist-get info (car social-network))

                                       info)))

                         (when (org-string-nw-p network)
                           (format "<li class=\"fa fa-%s\"><a href=\"https://%s/%s\"> %s</a></li>\n"
                                   (nth 1 social-network)
                                   (nth 2 social-network)
                                   network
                                   network))))

                     '((:github "github" "www.github.com")
                       (:gitlab "gitlab" "www.gitlab.com")
                       (:linkedin "linkedin" "www.linkedin.com/in"))
                     "")
          "</ul>\n\n"
          (org-hugo-inner-template contents info)))


(provide 'ox-zolacv)
;;; ox-zolacv ends here

;;; ox-s5.el --- S5 Presentation Back-End for Org Export Engine

;; Copyright (C) 2011-2013  Rick Frankel

;; Author: Rick Frankel <emacs at rickster dot com>
;; Keywords: outlines, hypermedia, S5, wp

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

;; This library implements an S5 Presentation back-end for the Org
;; generic exporter.

;; Installation
;; ------------
;; Get the s5 scripts from
;;    http://meyerweb.com/eric/tools/s5/
;; (Note that the default s5 version is set for using the alpha, 1.2a2.
;; Copy the ui dir to somewhere reachable from your published presentation
;; The default (`org-s5-ui-url') is set to "ui" (e.g., in the
;; same directory as the html file).

;; Usage
;; -----
;; Follow the general instructions at the above website. To generate
;; incremental builds, you can set the HTML_CONTAINER_CLASS on an
;; object to "incremental" to make it build. If you want an outline to
;; build, set the` INCREMENTAL property on the parent headline.

;; To test it, run:
;;
;;   M-x org-s5-export-as-html
;;
;; in an Org mode buffer.  See ox.el and ox-html.el for more details
;; on how this exporter works.

(require 'ox-html)

(org-export-define-derived-backend s5 html
  :menu-entry
  (?s "Export to S5 HTML Presentation"
      ((?H "To temporary buffer" org-s5-export-as-html)
       (?h "To file" org-s5-export-to-html)
       (?o "To file and open"
	   (lambda (a s v b)
	     (if a (org-s5-export-to-html t s v b)
	       (org-open-file (org-s5-export-to-html nil s v b)))))))
  :options-alist
  ((:html-link-home "HTML_LINK_HOME" nil nil)
   (:html-link-up "HTML_LINK_UP" nil nil)
   (:html-mathjax "HTML_MATHJAX" nil "" space)
   (:html-postamble nil "html-postamble" nil t)
   (:html-preamble nil "html-preamble" nil t)
   (:html-style-extra "HTML_STYLE" nil org-html-style-extra newline)
   (:html-style-include-default "HTML_INCLUDE_DEFAULT" nil nil)
   (:html-style-include-scripts "HTML_INCLUDE_SCRIPTS" nil nil)
   (:s5-version "S5_VERSION" nil org-s5-version)
   (:s5-theme-file "S5_THEME_FILE" nil org-s5-theme-file)
   (:s5-ui-url "S5_UI_URL" nil org-s5-ui-url))
  :translate-alist
  ((headline . org-s5-headline)
   (plain-list . org-s5-plain-list)
   (template . org-s5-template)))

(defgroup org-export-s5 nil
  "Options for exporting Org mode files to S5 HTML Presentations."
  :tag "Org Export S5"
  :group 'org-export-html)

(defcustom org-s5-version "1.2a2"
  "Version of s5 being used (for version metadata.) Defaults to
s5 v2 alpha 2.
Can be overridden with S5_VERSION."
  :group 'org-export-s5
  :type 'string)

(defcustom org-s5-theme-file nil
"Url to S5 theme (slides.css) file. Can be overriden with the
S5_THEME_FILE property. If nil, defaults to
`org-s5-ui-url'/default/slides.css. If it starts with anything but
\"http\" or \"/\", it is used as-is. Otherwise the link in generated
relative to `org-s5-ui-url'.
The links for all other required stylesheets and scripts will be
generated relative to `org-s5-ui-url'/default."
  :group 'org-export-s5
  :type 'string)

(defcustom org-s5-ui-url "ui"
  "Base url to directory containing S5 \"default\" subdirectory
and the \"s5-notes.html\" file.
Can be overriden with the S5_UI_URL property."
  :group 'org-export-s5
  :type 'string)

(defcustom org-s5-default-view 'slideshow
  "Setting for \"defaultView\" meta info."
  :group 'org-export-s5
  :type '(choice (const slideshow) (const outline)))

(defcustom org-s5-control-visibility 'hidden
  "Setting for \"controlVis\" meta info."
  :group 'org-export-s5
  :type '(choice (const hidden) (const visibile)))

(defcustom org-s5-footer-template
  "<div id=\"footer\">
<h1>%author - %title</h1>
</div>"
  "Format template to specify footer div. Completed using
`org-fill-template'.
Optional keys include %author, %email, %file, %title and %date.
Note that the div id must be \"footer\"."
  :group 'org-export-s5
  :type 'string)

(defcustom org-s5-header-template "<div id=\"header\"></div>"
  "Format template to specify footer div. Completed using
`org-fill-template'.
Optional keys include %author, %email, %file, %title and %date.
Note that the div id must be \"header\"."
  :group 'org-export-s5
  :type 'string)

(defcustom org-s5-title-page-template
  "<div class=\"slide title-page\">
<h1>%title</h1>
<h1>%author</h1>
<h1>%email</h1>
<h1>%date</h1>
</div>"
  "Format template to specify title page div. Completed using
`org-fill-template'.
Optional keys include %author, %email, %file, %title and %date.
Note that the wrapper div must include the class \"slide\"."
  :group 'org-export-s5
  :type 'string)


(defun org-s5-toc (depth info)
  (let* ((headlines (org-export-collect-headlines info depth))
	 (toc-entries
	  (loop for headline in headlines collect
		(list (org-html-format-headline--wrap
		       headline info 'org-html-format-toc-headline)
		      (org-export-get-relative-level headline info)))))
    (when toc-entries
      (concat
       "<div id=\"table-of-contents\" class=\"slide\">\n"
       (format "<h1>%s</h1>\n"
	       (org-html--translate "Table of Contents" info))
       "<div id=\"text-table-of-contents\">"
       (org-html-toc-text toc-entries)
       "</div>\n"
       "</div>\n"))))

(defun org-s5--build-style (info)
  (let* ((dir (plist-get info :s5-ui-url))
	 (theme (or (plist-get info :s5-theme-file) "default/slides.css")))
    (mapconcat
     'identity
     (list
      "<!-- style sheet links -->"
      (mapconcat
       (lambda (list)
	 (format
	  (concat
	   "<link rel='stylesheet' href='%s/default/%s' type='text/css'"
	   " media='%s' id='%s' />")
	  dir (nth 0 list) (nth 1 list) (nth 2 list)))
       (list
	'("outline.css" "screen" "outlineStyle")
	'("print.css" "print" "slidePrint")
	'("opera.css" "projection" "operaFix")) "\n")
      (format (concat
	       "<link rel='stylesheet' href='%s' type='text/css'"
	       " media='screen' id='slideProj' />")
	      (if (string-match-p "^\\(http\\|/\\)" theme) theme
		(concat dir "/" theme)))
      "<!-- S5 JS -->"
      (concat
       "<script src='" dir
       "/default/slides.js' type='text/javascript'></script>")) "\n")))

(defun org-s5--build-meta-info (info)
  (concat
   (org-html--build-meta-info info)
   (format "<meta name=\"version\" content=\"S5 %s\" />"
	   (plist-get info :s5-version))
   "<meta name='defaultView' content='slideshow' />\n"
   "<meta name='controlVis' content='hidden' />"))

(defun org-s5-headline (headline contents info)
  (let ((org-html-toplevel-hlevel 1))
    (org-html-headline
     (if (= 1 (+ (org-element-property :level headline)
		 (plist-get info :headline-offset)))
         (org-element-put-property
	  headline :html-container-class
	  (mapconcat 'identity
		     (list
		      (org-element-property
		       :html-container-class headline)
		      "slide") " "))
	  headline) contents info)))

(defun org-s5-plain-list (plain-list contents info)
  "Transcode a PLAIN-LIST element from Org to HTML.
CONTENTS is the contents of the list.  INFO is a plist holding
contextual information.
If a containing headline has the property :incremental,
then the \"incremental\" class will be added to the to the list,
which will make the list into a \"build\"."
  (let* ((type (org-element-property :type plain-list))
	(tag (case type
	       (ordered "ol")
	       (unordered "ul")
	       (descriptive "dl"))))
    (format "%s\n%s%s"
	    (format
	     "<%s class='org-%s%s'>" tag tag
	     (if (org-export-get-node-property :incremental plain-list t)
		 " incremental" ""))
	    contents (org-html-end-plain-list type))))

(defun org-s5-template-alist (info)
  `(
   ("title"  . ,(car (plist-get info :title)))
   ("author" . ,(car (plist-get info :author)))
   ("email"  . ,(plist-get info :email))
   ("date"   . ,(substring (nth 0 (plist-get info :date)) 0 10))
   ("file"   . ,(plist-get info :input-file))))

(defun org-s5-template (contents info)
  "Return complete document string after HTML conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (mapconcat
   'identity
   (list
    "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
	\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"
    (format "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"%s\" xml:lang=\"%s\">"
	    (plist-get info :language) (plist-get info :language))
    "<head>"
    (org-s5--build-meta-info info)
    (org-s5--build-style info)
    (org-html--build-style info)
    (org-html--build-mathjax-config info)
    "</head>"
    "<body>"
    "<div class=\"layout\">"
    "<div id=\"controls\"><!-- no edit --></div>"
    "<div id=\"currentSlide\"><!-- no edit --></div>"
    (org-fill-template
     org-s5-header-template (org-s5-template-alist info))
    (org-fill-template
     org-s5-footer-template (org-s5-template-alist info))
    "</div>"
    (format "<div id=\"%s\" class=\"presentation\">" (nth 1 org-html-divs))
    ;; title page
    (org-fill-template
     org-s5-title-page-template (org-s5-template-alist info))
    (let ((depth (plist-get info :with-toc)))
      (when depth (org-s5-toc depth info)))
    contents
    "</div>"
    "</body>"
    "</html>\n") "\n"))

(defun org-s5-export-as-html
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to an HTML buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org S5 Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (if async
      (org-export-async-start
	  (lambda (output)
	    (with-current-buffer (get-buffer-create "*Org S5 Export*")
	      (erase-buffer)
	      (insert output)
	      (goto-char (point-min))
	      (nxml-mode)
	      (org-export-add-to-stack (current-buffer) 's5)))
	`(org-export-as 's5 ,subtreep ,visible-only ,body-only ',ext-plist))
    (let ((outbuf (org-export-to-buffer
		   's5 "*Org S5 Export*"
		   subtreep visible-only body-only ext-plist)))
      ;; Set major mode.
      (with-current-buffer outbuf (nxml-mode))
      (when org-export-show-temporary-export-buffer
	(switch-to-buffer-other-window outbuf)))))

(defun org-s5-export-to-html
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a S5 HTML file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return output file's name."
  (interactive)
  (let* ((extension (concat "." org-html-extension))
	 (file (org-export-output-file-name extension subtreep))
	 (org-export-coding-system org-html-coding-system))
    (if async
	(org-export-async-start
	    (lambda (f) (org-export-add-to-stack f 's5))
	  (let ((org-export-coding-system org-html-coding-system))
	    `(expand-file-name
	      (org-export-to-file
	       's5 ,file ,subtreep ,visible-only ,body-only ',ext-plist))))
      (let ((org-export-coding-system org-html-coding-system))
	(org-export-to-file
	 's5 file subtreep visible-only body-only ext-plist)))))

(defun org-s5-publish-to-html (plist filename pub-dir)
  "Publish an org file to S5 HTML Presentation.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 's5 filename ".html" plist pub-dir))

(provide 'ox-s5)

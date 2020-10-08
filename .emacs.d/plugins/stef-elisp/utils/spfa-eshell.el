;;; -*- auto-recompile: t -*-

;; This file is not part of GNU Emacs.
;; 
;; spfa-eshell.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; spfa-eshell.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;-------------
;;             extensions to Eshell 

;; last modified March 19, 2011
;;; --------------------------------------------------------------------------

(require 'eshell)

;(add-to-list 'eshell-output-filter-functions 'surmulot-eshell-display-images)

(defvar surmulot-eshell-image-regexp "\"?image:\\(\\([^\"]*\\)\"?\\)"
  "Regexp matching an image file specification in an Eshell buffer.
\(match-string 2\) should return the image file name")

(defun surmulot-eshell-expand-file-name ()
  "Get the last image file name found after a successful search for 
`surmulot-eshell-image-regexp' from the match data"
  (expand-file-name
   (substitute-in-file-name (match-string-no-properties 2))
   (substitute-in-file-name "$SURMULOTDIR")))

(defun surmulot-eshell-display-images ()
  "Scan the last output for image specifications; display said images."
  (condition-case nil
      (save-excursion 
	(goto-char eshell-last-output-start)
	(while (re-search-forward surmulot-eshell-image-regexp
				  eshell-last-output-end t)
	   (set-text-properties
	    (match-beginning 0) (match-end 1)
	    `(display (image :type png 
			     :file ,(surmulot-eshell-expand-file-name)) 
	      nonsticky t))))
    (error nil)))

(defun surmulot-eshell-images-in-region (beg end)
  "Return a list of all displayed image files in region.
See variable `surmulot-eshell-image-regexp'"
  (save-excursion 
    (goto-char beg)
    (loop while (re-search-forward surmulot-eshell-image-regexp end t)
	  collect (surmulot-eshell-expand-file-name)))) 

(defun surmulot-eshell-file-temporary-p (file)
  "Tell weither FILE is a temporary file that can be automatically deleted."
  (string-match "^_tmp_" (file-name-nondirectory file)))

(defun surmulot-eshell-kill-region (&optional beg end)
  "Take care to remove displayed images from both disk and memory."
  (let ((inhibit-read-only t)
	(beg (or beg (point-min)))
	(end (or end (point-max))))
    (dolist (file (surmulot-eshell-images-in-region beg end))
      (when (and (surmulot-eshell-file-temporary-p file)
		 (file-exists-p file))
	(clear-image-cache file)
	(delete-file file)))
    (kill-region beg end)))

(custom-add-option 'eshell-exit-hook 'surmulot-eshell-kill-region)
;(add-hook 'eshell-exit-hook 'surmulot-eshell-kill-region)

(defun line-concat-stringify (&rest objects)
  (mapconcat 'eshell-stringify (remove-if 'null objects) "\n"))

;;; ===========================================================================
;;;              eshell/clear
;;; ===========================================================================


;; fix ?
;; (defun eshell-next-prompt (n)
;;   "Move to end of Nth next prompt in the buffer.
;; See `eshell-prompt-regexp'."
;;   (interactive "p")
;;   (forward-paragraph n)
;;   (eshell-skip-prompt))


(defun eshell-next-prompt-region ()
  (interactive)
  (save-excursion
    (when (re-search-forward eshell-prompt-regexp nil t)
      (let ((input (buffer-substring-no-properties (point) (point-at-eol))))
	(list input
	      (save-excursion (re-search-backward eshell-prompt-regexp))
	      (if (re-search-forward eshell-prompt-regexp nil t)
		  (re-search-backward eshell-prompt-regexp)
		(point-at-eol)))))))

(defun eshell-last-prompt-region ()
  (interactive)
  (save-excursion
    (when (and (re-search-backward eshell-prompt-regexp nil t)   
	       (re-search-backward eshell-prompt-regexp nil t))
      (eshell-next-prompt-region))))

(defun eshell-cut-next-prompt-region ()
  (interactive)
  (apply 'surmulot-eshell-kill-region (cdr (eshell-next-prompt-region))))

(defun eshell-cut-last-prompt-region ()
  (interactive)
  (apply 'surmulot-eshell-kill-region (cdr (eshell-last-prompt-region))))

(defun eshell-cut-first-prompt-region ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (eshell-cut-next-prompt-region)))

(defun eshell-cut-last-prompt-regions-matching (regexp)
  (interactive)
  (let (pr)
    (save-excursion
      (while (setq pr (eshell-last-prompt-region))
	(if (string-match regexp (car pr))
	    (eshell-cut-last-prompt-region)
	  (goto-char (caddr pr)))))))

(defun eshell-clear ()
  (surmulot-eshell-kill-region (point-min) (point-max)))

(defun eshell/clear (&rest rest)
  (eshell-eval-using-options
   "clear" rest
   '((?h "help" nil nil "show this usage screen")
     (?a "all" nil all "clear all")
     (?l "last" t last "cut last commands")
     (?f "first" t first "cut first commands")
     (?k "keep" t keep "cut all but last commands")
     (?d "duplicates" t dup "keep only the last instance of any command")
     :show-usage
     :usage "[options] REGEXP"
     :post-usage
"Clear eshell buffer, or cut some commands off.")
   (when keep
     (setq first
	   (max 0 (- (save-excursion
		       (goto-char (point-min))
		       (loop while 
			     (re-search-forward eshell-prompt-regexp nil t)
			     sum 1 into n
			     finally return (- n 1)))
		     (read keep)))))
   (condition-case nil
       (if all (eshell-clear)
	 (if dup (eshell-keep-single-instance-of-commands)
	   (if last (loop repeat (read last)
			  do (eshell-cut-last-prompt-region))
	     (if first (loop repeat (if keep first (read first))
			     do (eshell-cut-first-prompt-region))
	       (if args (eshell-cut-last-prompt-regions-matching
			 (mapconcat 'identity args " ")))))))
     (error nil))))

(defun eshell-keep-single-instance-of-commands ()
  (save-excursion
    (goto-char (point-max))
    (loop do (eshell-keep-single-instance-of-command)
	  while (eshell-last-prompt-region)
	  do (goto-char (caddr (eshell-last-prompt-region))))))

(defun eshell-keep-single-instance-of-command ()
  "Delete from Eshell buffer all commands identical to the last command,
along with their output.
This allows endless repetition of a command without cluttering."
  (save-excursion
    (let (pr input)
      (while (setq pr (eshell-last-prompt-region))
	(if input
	    (if (string= input (car pr))
		(eshell-cut-last-prompt-region)
	      (goto-char (caddr pr)))
	  (setq input (car pr))
	  (goto-char (caddr pr)))))))

(defun eshell-clear-clear-commands ()
  "Delete all `clear' commands from the Eshell buffer."
  (when (eshell-last-prompt-region)
    (save-excursion
      (goto-char (point-max))
      (when (string-match "^ *clear .+" (car (eshell-last-prompt-region)))
	(eshell-cut-last-prompt-region)))))

(custom-add-option 'eshell-post-command-hook 'eshell-clear-clear-commands)
(custom-add-option 'eshell-post-command-hook 'eshell-keep-single-instance-of-command)
;(add-hook 'eshell-post-command-hook 'eshell-clear-clear-commands)
;(add-hook 'eshell-post-command-hook 'eshell-keep-single-instance-of-command)


;;; ===========================================================================
;;;              misc.
;;; ===========================================================================

(defun eshell/query (prompt &optional initial-input)
  (when initial-input
    (setq initial-input (prin1-to-string initial-input)))
  (read-from-minibuffer (format "%s " prompt) initial-input))

; completing-read

(provide 'spfa-eshell)

;;; spfa-eshell.el ends here








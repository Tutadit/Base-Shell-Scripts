;;; -*- auto-recompile: t -*-

;;; surmulot-midi.el --- Handling MIDI files across the Surmulot system

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

(require 'cl)

(defun directory-files-with-attributes (dir)
  (remove-if 'caadr
	     (mapcar (lambda (f)
		       (list f (file-attributes f)))
		     (directory-files dir t))))

(defmacro noting-changed-files (files-symb directory &rest body)
  (let ((dir-symb (gensym)))
  `(let ((,dir-symb (or ,directory (file-name-directory buffer-file-name))))
     (setq ,files-symb (directory-files-with-attributes ,dir-symb))
     ,@body
     (setq ,files-symb
	   (mapcar 'car
		   (set-difference (directory-files-with-attributes ,dir-symb)
				   ,files-symb :test 'equal))))))


(defmacro changed-files (&rest body)
  (let ((files-symb (gensym)))
    `(let (,files-symb)
       (noting-changed-files ,files-symb nil
			     ,@body)
       ,files-symb)))

(defcustom surmulot-midi-file-handler 'muo-get-midi-files
  "Define the action to be taken whenever MIDI files are being noticed
by the system for some reason (newly generated, dragged'n'dropped, etc)."
  :group 'surmulot
  :type '(radio (const :tag "none (no action)" nil)
		(function-item :tag "send to muO" muo-get-midi-files)))

(defun surmulot-handle-midi-files (files)
  "FILES have been noticed for some reason: handle the MIDI ones through the
function bound by `surmulot-midi-file-handler'."
  (when surmulot-midi-file-handler
    (funcall surmulot-midi-file-handler 
	     (remove-if-not (lambda (f) (string-match "\.midi?$" f)) files))))

(defun muo-get-midi-files (midi-files)
  "Send MIDI-FILES to muO, which see"
  ($$ `[SurmulotManager emacsSendMIDIFilesNamed: \#,midi-files]))


;================= music21 & athenaCL usage


(defun surmulot-music21-output-filter (output)
  (if (string-match "'\\(.*\\.mid\\)'" output)
      (let ((fname (read (format "\"%s\""(match-string 1 output)))))
	(surmulot-handle-midi-files (list fname)))))

(defvar surmulot-athenaCL-last-output "")

(defun surmulot-athenaCL-output-filter (output)
  (unless (string= output surmulot-athenaCL-last-output)
    (setq surmulot-athenaCL-last-output output)
    (if (string-match "(\\(.*\\.mid\\))" output) ;; command PIh
	(let ((fname (match-string 1 output)))
	  (surmulot-handle-midi-files (list fname)))
      (if (string-match "complete:\n?\\([^ ]+\\.mid\\)$" output) 
	  ;; commands ELn, ELw, ELv
	  (let ((fname (match-string 1 output)))
	    (surmulot-handle-midi-files (list fname)))))))


;================= drag'n'drop midi file

(add-to-list 'dnd-protocol-alist
	     '("^file:.*\\.midi?$" . surmulot-insert-midi))

(defun surmulot-insert-midi (midi-file ignored) 
  (surmulot-handle-midi-files (list (dnd-get-local-file-name midi-file t))))



(provide 'surmulot-midi)
;;; surmulot-midi.el ends here


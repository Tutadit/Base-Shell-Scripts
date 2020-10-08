;;; -*- auto-recompile: t -*-

;; This file is not part of GNU Emacs.
;; 
;; surmulot-csd.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; surmulot-csd.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;-------------
;;             Surmulot integration for CSD buffers 

;; last modified February 9, 2012
;;; --------------------------------------------------------------------------


; (muo-get '("a,e,f" kphrase asBox))
(defun muo-get (object)
  ($$ `[SurmulotManager emacsSend: ,object]))

(defun muo-edit-string (encoded-string rid mode label)
  "Decode ENCODED-STRING and create a buffer to edit it
RID is a numeric handle allowing muO to know what to do with the edited string
MODE is the major mode the edit buffer should be in
LABEL is the name for that buffer

This function is required by EmacsInteraction in muO"
  (save-excursion
    (switch-to-buffer-other-frame
     (generate-new-buffer label))
    (erase-buffer)
    (insert (squeak-decode encoded-string))
    (goto-char (point-min))
    (condition-case nil
	(funcall mode)
      (error nil))
    (set (make-local-variable 'receiver-id) rid)
    (setq header-line-format
	  (list
	   (squeak-console-button-do 
	    " Accept " "accept the changes"
	    ($$ `[EmacsInteraction updateString: ,(squeak-encode-buffer) 
				   receiverId: ,receiver-id])
	    (set-buffer-modified-p nil))
	   " "
	   (squeak-console-button-do 
	    " Explore receiver " "open an ObjectExplorer in Squeak"
	    ($$ `[(EmacsInteraction  msDict at: ,receiver-id) explore]))
	   " "
	   (squeak-console-button-do 
	    " Accept and exit " "accept the changes and kill this buffer"
	    ($$ `[EmacsInteraction updateString: ,(squeak-encode-buffer) 
				   receiverId: ,receiver-id
				   cleanUp: true])
	    (let ((f (selected-frame)))
	      (when (and (kill-buffer (current-buffer))
			 (eq f (selected-frame)))
		(delete-frame))))
	   " "
	   (squeak-console-button-do 
	    " Exit " "kill this buffer and its frame"
	    ($$ `[EmacsInteraction cleanUpReceiverId: ,receiver-id])
	    (let ((f (selected-frame)))
	      (when (and (kill-buffer (current-buffer))
			 (eq f (selected-frame)))
		(delete-frame))))))
    (set-buffer-modified-p nil)
    ;;; making the buffer persistent across sessions
    (setq desktop-save-buffer 
	  `(lambda (sdir)
	    (list (squeak-encode 
		   (buffer-substring-no-properties (point-min) (point-max)))
		  ,rid ',mode ,label)))))

;==
(defun surmulot-restore-buffer (desktop-buffer-file-name
				   desktop-buffer-name
				   desktop-buffer-misc)
  "restore a buffer editing a string in behalf of muO"
  (if desktop-buffer-misc
      (apply 'muo-edit-string desktop-buffer-misc)
    (desktop-restore-file-buffer desktop-buffer-file-name
				 desktop-buffer-name
				 desktop-buffer-misc)))
				 
(mapc (lambda (mode)
	(add-to-list 'desktop-buffer-mode-handlers
		     (cons mode 'surmulot-restore-buffer)))
      '(text-mode csound-csd-mode csound-orc-mode csound-sco-mode))
;==

(defun muo-get-sco ()
  "send to muO the appropriate MGraphElement for representing the current score"
  (interactive)
  (let ((filename (buffer-file-name)))
    (if (and filename (string-match "\\.sco$" filename))
        (muo-get
	 `(MGraphMusicFile newFromFile: ,filename))
      (muo-get 
       `(MGraphCsoundScore 
	 newFromB64: ,(if (cscsd-buffer-is-a-sco-p)
			  (squeak-encode-region (cscsd-sco-beginning)
						(cscsd-sco-end))
			(squeak-encode-buffer)))))))

(defun muo-get-orc ()
  (interactive)
  "send to muO the appropriate MGraphElement for representing the current orchestra"
  (let ((filename (buffer-file-name)))
    (if (and filename (string-match "\\.orc$" filename))
        (muo-get `(MGraphCsoundComposer newFromFile: ,filename))
      (muo-get
       `(MGraphCsoundComposer 
	 newFromB64: ,(if (cscsd-buffer-is-an-orc-p)
			  (squeak-encode-region (cscsd-orc-beginning) 
						(cscsd-orc-end))
			(squeak-encode-buffer)))))))

; (muo-get-patch 50 21 "test")
(defun muo-get-patch (bank program name)
  (muo-get 
   `((MGraphCode new code: ,(format "
    value _ MusicalPhrase bank: %s program: %s
                      channel: (box1 ifNil: [1] 
                                   ifNotNil: [box1 output ifNil: [1]])"
				    bank program))
     label: ,name)))
	  

(defun muo-get-csd ()
  (interactive)
  "Send to muO the appropriate MGraphElement for representing the current csd"
  (let ((filename (cscsd-buffer-CSD-file)))
    (if filename
        (muo-get `((CSDFile named: ,filename) asBox))
      (muo-get-csd-as-composition))))

(defun muo-get-csd-as-WAV ()
  (interactive)
  (muo-get
   `((CSDFile named: ,(cscsd-make-temp-buffer-for-processing)) 
     asWAVFile asBox)))

(defun muo-get-csd-as-composition () 
  "Send the current CSD buffer contents to muO as a CsoundComposition"
  (interactive)
  (muo-get
   `((CSDFile named: ,(cscsd-make-temp-buffer-for-processing)) 
     asCsoundComposition asBox)))

(defun surmulot-eval-in-csd (quoted-form)
  "Evaluate QUOTED-FORM in the current buffer if that buffer is a CSD, 
else return 'not-a-csd"
  (surmulot-widget-default-eval-in-csd-function nil quoted-form))


;; ===================================================================
;;                   score format specification
;; ===================================================================

(defvar cscsd-instrument-format-setters
  '((pitchField: nil)
    (pitchFormat: nil)
    (pitchInflexionField: nil)
    (ampField: nil)
    (ampMin:max: (0 1))
    (panField: nil)
    (panMin:max: (-1 1))
    (chanField: nil)
    (selectChannels: nil)
    (selectChannel: nil)
    (dispatchField: nil)
    (dispatchGap: nil) 
    (iTemplate: nil))
  "A association list of all setters for instrument format, with their 
default value.")

(defun cscsd-instrument-format-template (&optional setters)
  (format "/*|\n (%s)\n|*/"
	  (substring 
	   (mapconcat (lambda (c) (format "  %S" c)) 
		      (or setters cscsd-instrument-format-setters)
		      "\n")
	   2)))

(defun cscsd-may-have-format-p ()
  (save-excursion
    (goto-char (point-min))
    (and (re-search-forward "^/\\*|" nil t)
	 (re-search-forward ".+:.+" nil t)
	 (re-search-forward "^|\\*/" nil t))))

(defun cscsd-get-format (&optional csd-file)
  "Reads all instrument formats in CSD-FILE or in current CSD buffer."
  (if csd-file
      (with-temp-buffer
	(insert-file-contents csd-file)
	(cscsd-get-format))
    (with-base-buffer
      (append `((header: ,(squeak-encode (cscsd-get-score-header) t))
		(kr: ,(csound-get-kr)))
	      ;; global score format setters
	      (save-excursion
		(cscsd-go-before-cssynth)
		(loop while (re-search-forward 
			     "/\\*|[ \t]*\\(.+:.+\\)[ \t]*|\\*/" 
			     (save-excursion
			       (cscsd-goto-end-of-cssynth)) t)
		      append (list (read (concat "(" (match-string 1) ")")))
		      into spec
		      finally return spec))
	      ;; intruments formats & effects
	      (loop for i in (cscsd-instruments)
		    do (goto-char (cscsd-beginning-of-instrument i))
		    if (re-search-forward "/\\*|[ \t]*effect\\(.*\\)|\\*/" 
					  (cscsd-end-of-instrument i) t)
		    append `((readEffect: ,(match-string-no-properties 1)))
		    into spec
		    if (re-search-forward "/\\*|\\([^;]+\\)|\\*/" 
					  (cscsd-end-of-instrument i) t)
		    ;; support for multiple instrument numbers
		    append (let ((fmt (read (match-string 1))))
			     (mapcar (lambda (ea) (list (read ea) fmt))
				     (split-string i ",")))
;		    append (list (list (read i) (read (match-string 1))))
		    into spec
		    finally return spec)))))

(defun cscsd-insert-itemplate (instr &optional setters)
  ""
  (save-excursion
    (goto-char (cscsd-beginning-of-instrument instr))
    (goto-char (point-at-eol))
    (insert ?\n (cscsd-instrument-format-template setters) ?\n)))

(defun cscsd-read-phrase (&optional str)
  "Replace the current score section with musical phrase STR as read
using the current CSD format"
  (interactive "sPhrase: ")
  (cscsd-overwrite-score
   ($$ `[((CsoundScoreFormat fromConsCell: \# ,(cscsd-get-format) asCons)
	  readPhrase: ,str kphrase) asString])))

(defun muo-insert-itemplates ()   
  ""
  (interactive)
  (save-excursion
    (loop for i in (cscsd-instruments nil t)
	  do (cscsd-insert-itemplate i))))

(defvar csound-score-header-beg-regexp "/\\*|[ \t]*header[ \t]*|\\*/"
  "Should fit the value of CsoundScore headerStartComment in muO")

(defvar csound-score-header-end-regexp "/\\*|[ \t]*header[ \t]*end[ \t]*|\\*/"
  "Should fit the value of CsoundScore headerEndComment in muO")

(defun cscsd-get-score-header ()
  "Read the header in the current buffer CSD score section.
This function does not attempt to analyse the score statements: it simply
looks for specific comment templates marking the beginning and end of the
header section.
See `csound-score-header-beg-regexp' and `csound-score-header-end-regexp'"
  (save-excursion
    (cscsd-goto-sco)
    (condition-case nil
	(buffer-substring-no-properties
	 (re-search-forward csound-score-header-beg-regexp (cscsd-sco-end))
	 (progn
	   (goto-char (cscsd-sco-end))
	   (re-search-backward csound-score-header-end-regexp))) 
      (error ""))))

(defun muo-edit-csd ()
  "Edit the current CSD buffer contents as a CsoundComposition in MuO"
  (interactive)
  (let$ (csdfile sf)
    ($$ `[csdfile <- (CSDFile named: ,(cscsd-make-temp-buffer-for-processing))]
	`[sf <- CsoundScoreFormat fromConsCell: \#,(cscsd-get-format) asCons]
	[((csdfile> asCsoundComposition) scoreFormat: sf>) edit])))

(defun muo-edit-csd-as-widget ()  
  "Edit the current CSD buffer contents in a CsoundCompositionEditor widget.
This is a graphical tool for score composition."
  (interactive)
  (surmulot-attach-widget
   (surmulot-widgets-add
    "Composition Editor"
    `((CSDFile named: ,(cscsd-make-temp-buffer-for-processing)) 
      asCsoundComposition editorMorph))))

(defun muo-register-csd-as-synthesizer (&optional address label)  
  "Register the current CSD at ADDRESS in the CsoundSynthesizer library.
ADDRESS is a string defining the access path of the new synth, such as
\"my-synths/specials/example soundfont-based synth\"."
  (interactive "saddress in library: \nslabel: ")
  (squeak-eval
   (format "CsoundSynthesizer libraryAt: #(%s) put: ((CsoundSynthesizer csdFileNamed: '%s') label: '%s')"
	   (mapconcat (lambda (s) (concat "#'" s "'"))
		      (split-string address "/") " ")
	   (cscsd-make-temp-buffer-for-processing)
	   (or label (format "CS from %s" (buffer-name))))))

(defun surmulot-play-with-score (score &optional append)
  (cscsd-process (cscsd-make-temp-buffer-for-processing score append)
		 nil nil "$csound -dodac %s &"))

(defun surmulot-play-midi (midifile)
  (cscsd-process nil
		 nil midifile "$csound -dodac %s -TF %s &"))

(defun surmulot-render-with-score (wavfile score &optional append)
  (cscsd-process (cscsd-make-temp-buffer-for-processing score append)
		 wavfile nil "$csound -dWo %s %s"))

(defun surmulot-render-midi (midifile wavfile)
  (cscsd-process (cscsd-make-temp-buffer-for-processing)
		 wavfile midifile "$csound -dWo %s %s -TF %s"))

(defun surmulot-csd-menu ()
  '(("Surmulot"
     ["Edit in widget"  muo-edit-csd-as-widget t]
     ["Edit in muO"  muo-edit-csd t]
     "--"
     ["Send to muO as a CSDFile"  muo-get-csd t]
     ["Send to muO as a CsoundComposition"  muo-get-csd-as-composition t]
     ["Send to muO as a WAVFile"  muo-get-csd-as-WAV t]
     "--"
     ["Read musical phrase (to score)" cscsd-read-phrase 
      (cscsd-may-have-format-p)]
     ["Insert instrument format templates" muo-insert-itemplates t]
     "--"
     ["Register CSD as synthesizer" muo-register-csd-as-synthesizer 
      (cscsd-may-have-format-p)]
     ["Use dynamically as muO default synthesizer" 
      ($$ `[MIDISynthesizerInteraction default: 
		(SurmulotSynthesizer buffer: ,(buffer-name))]) 
      (cscsd-may-have-format-p)]
     ["Use dynamically as muO default WAV synthesizer" 
      ($$ `[MIDISynthesizerInteraction defaultToWAV: 
		(SurmulotSynthesizer buffer: ,(buffer-name))]) 
      (cscsd-may-have-format-p)])
    "--"))

(provide 'surmulot-csd)

;;; surmulot-csd.el ends here








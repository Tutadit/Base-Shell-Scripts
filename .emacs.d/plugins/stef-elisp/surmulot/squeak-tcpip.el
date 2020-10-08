;;; -*- auto-recompile: t -*-

;; This file is not part of GNU Emacs.
;; 
;; squeak-tcpip.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; squeak-tcpip.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;-------------
;;             interacting with Squeak via TCP/IP

;; last modified March 20, 2011
;; for Emacs 23.2
;;; ---------------------------------------------------------------------------

(require 'cl)

;;; Code:

(defcustom squeak-tcpip-vm "$SURMULOTDIR/squeak/vm/squeak"
  "Shell command used to launch Squeak VM"
  :type 'string
  :group 'spfa-paths
  :group 'squeak)

(defcustom squeak-tcpip-cog-vm "$SURMULOTDIR/squeak/vm/cog/squeak"
  "Shell command used to launch the Cog VM"
  :type 'string
  :group 'spfa-paths
  :group 'squeak)

(defcustom squeak-tcpip-use-cog-vm (eq system-type 'windows-nt)
  "When non-nil, the cog VM is used to run Squeak images"
  :type 'boolean
  :group 'squeak)

(defun squeak-tcpip-vm ()
  (expand-file-name (substitute-in-file-name 
		     (if squeak-tcpip-use-cog-vm 
			 squeak-tcpip-cog-vm
			 squeak-tcpip-vm))))

(defcustom squeak-tcpip-vm-options (if (eq system-type 'gnu/linux) 
				       "-vm-sound-pulse" 
				     "")
  "Options to be used with Squeak VM"
  :type 'string
  :group 'spfa-paths
  :group 'squeak)

(defcustom squeak-tcpip-cog-vm-options ""
  "Options to be used with Cog VM"
  :type 'string
  :group 'spfa-paths
  :group 'squeak)

(defun squeak-tcpip-vm-options ()
  (let ((options (if squeak-tcpip-use-cog-vm 
	      squeak-tcpip-cog-vm-options
	    squeak-tcpip-vm-options)))
    (if (string= options "") ""
      (format " %s " options))))

(defcustom squeak-tcpip-default-images '("$SURMULOTDIR/squeak/muO"
					 "$SURMULOTDIR/squeak/muO-*"
					 "$SURMULOTDIR/squeak/muO+*"
					 "$SURMULOTDIR/squeak/Squeak4.1.SPFA")
  "A list of Squeak images that can be interactively started from Emacs.
Each item here is interpreted as a root name so that the latest corresponding
versions can be considered. The \".image\" extension is optional.
Any root name may include wildcards and stands for several related root names.
See function `squeak-tcpip-default-image' for details"
  :type '(repeat string)
  :group 'spfa-paths
  :group 'squeak)

(defcustom squeak-tcpip-prompt "squeak> "
  "Squeak console prompt.
Must have the same value as Squeak class variable promptTCPIP in 
EmacsInteraction"
  :type 'string
  :group 'squeak)

(defcustom squeak-tcpip-init-command "'(Squeak connected)'"
  "Command send to Squeak when the TCPIP console starts.
Its returned value will be the first thing to appear in the console"
  :type 'string
  :group 'squeak)

(defcustom squeak-console-hide-commands t
  "If not nil, the Elisp commands from Squeak are not fully displayed at
the console; only a summary is displayed. If nil, nothing is hidden "
  :type 'boolean
  :group 'squeak)

(defcustom squeak-tcpip-ELisp-error "<evaluation error>"
  "Error message returned by ELisp() when evaluation failed."
  :type 'string
  :group 'squeak)

(defcustom squeak-tcpip-port 5552
  "Default Squeak TCP/IP port in local host. 
Must have the same value as the default value for EmacsInteraction class
variable LocalPort in Squeak"
  :type 'integer
  :group 'squeak)

(defcustom squeak-eval-with-return-timeout 15
  "Time-out \(in seconds\) for function `squeak-eval-with-return'"
  :type 'integer
  :group 'squeak)

(defcustom squeak-tcpip-console-is-special t
  "When non-nil, the console buffer is added to special-display-buffer-names"
  :type 'boolean
  :group 'squeak)

(defvar squeak-tcpip-process nil
  "buffer-local: the Squeak interaction TCP/IP process")

(defvar squeak-tcpip-last-evalue nil
  "buffer-local: used by `squeak-eval-with-return' to store the return value
of a Squeak expression")

(defvar squeak-tcpip-accumulated-preoutput ""
  "buffer-local: accumulated incoming strings from Squeak.
This is parsed in squeak-tcpip-preoutput-filter")

(defvar squeak-tcpip-last-output ""
  "buffer-local: last output from the TCP/IP process \(that is, from Squeak")


;;; ---------------------------------------------------------------------------
;;;
;;; image names comprehension & versioning
;;;
;;; ---------------------------------------------------------------------------

(defcustom squeak-tcpip-proposed-versions 2
  "Defines which versions of images listed in `squeak-tcpip-default-images'
are to be interactively proposed when starting Squeak from Emacs.
If 0, only root images are selected.
If -1, only the single latest versions are selected.
If a positive integer N, select all root images and their N latest versions.
See function `squeak-tcpip-default-image'."
  :type 'integer
  :group 'squeak)

(defun squeak-version-number (image-name)
  "Return the version number of IMAGE-NAME as a list of integers"
  (when (string-match "\\.\\([0-9.]+\\)\\(\\.image\\)?$" image-name)
    (mapcar 'read (split-string (match-string 1 image-name) "\\."))))

;TEST (squeak-version-number "$SURMULOTDIR/squeak/Squeak4.1.SPFA") => nil
;TEST (squeak-version-number "squeak/Squeak4.1.SPFA.21.4.image") => '(21 4)
;TEST (squeak-version-number "$SURMULOTDIR/Squeak4.1.SPFA.21.4") => '(21 4)
;TEST (squeak-version-number "muO") => nil
;TEST (squeak-version-number "muO.4") => '(4)
;TEST (squeak-version-number "muO.4.image") => '(4)
;TEST (squeak-version-number "muO.4.5.image") => '(4 5)
;TEST (squeak-version-number "muO.4.5.6.image") => '(4 5 6)

(defun squeak-image-root-name (image-name)
  "Return the root name of IMAGE-NAME \(no version numbers, no extension)"
  (if (string-match "\\(\\.[0-9.]+\\)?\\(\\.image\\)?$" image-name)
      (replace-match "" nil nil image-name)
    image-name))

;TEST (squeak-image-root-name "squeak/Squeak4.1.SPFA.21.4.image") => "squeak/Squeak4.1.SPFA"
;TEST (squeak-image-root-name "muO") => "muO"
;TEST (squeak-image-root-name "d:/devel/surmulot/squeak/muO+cf TempoEvent.image") => "d:/devel/surmulot/squeak/muO+cf TempoEvent"

(defun squeak-images-roots ()
  (remove-duplicates
   (loop for name in squeak-tcpip-default-images
	 append (or (mapcar
		     'squeak-image-root-name
		     (delete-if
		      (lambda (name)
			(not (string-match ".*\\.image" name)))
		      (file-expand-wildcards (substitute-in-file-name name))))
		    (list name))
	 into roots
	 finally return roots)
   :test 'string=))

; (squeak-images-roots)

(defun squeak-tcpip-default-image ()
  "Return the image to be opened when starting Squeak from Emacs.
If several images are available, interactively query the user via a dialog. 
Valid images candidates are some versions of the root images listed in variable
`squeak-tcpip-default-images'; which versions are considered exactly depends on
the value of variable `squeak-tcpip-proposed-versions'.
If no image is found, return \"\" which will have the Squeak VM interactively
query the user."
  (let (all-versions)
    (dolist (root-name (squeak-images-roots))
      (let ((versions (squeak-image-versions
		       root-name
		       (< squeak-tcpip-proposed-versions 0))))
	(when versions
	  (unless (squeak-version-number (first versions))
	    (add-to-list 'all-versions (first versions) t))
	  (dolist (image (last versions 
			       (max 0
				    (min squeak-tcpip-proposed-versions
					 (length versions)))))
	    (add-to-list 'all-versions image t)))))
    (if (= 1 (length all-versions))
	(first all-versions)
      (or (x-popup-dialog
	   (selected-frame)
	   (append '("choose a Squeak image")
		   (append (mapcar (lambda (s) (cons s s)) all-versions)
			   '("-" ("open file browser" . nil)))))
	  (x-file-dialog "select a Squeak image"
			 (substitute-in-file-name "$SURMULOTDIR/squeak")
			 nil t)))))

(defun squeak-latest-image (image-name)
  "Return the last version of Squeak image IMAGE-NAME.
Return \"\" if no version exists at all."
  (or (car (last (squeak-image-versions image-name))) 
      ""))

(defun squeak-image-versions (image-name &optional no-root)
  "Return a sorted list of all versions of Squeak image IMAGE-NAME.
If NO-ROOT is not nil, include IMAGE-NAME itself only if latest versions are
not found; else skip it."
  (let* ((image-name (substitute-in-file-name
		      (if (string-match "\\.image$" image-name)
			  (file-name-sans-extension image-name)
			image-name)))
	 (numbered-versions (directory-files
			     (file-name-directory image-name) 
			     t (format "%s\\(\\.[0-9]+\\)+\\.image"
				       (regexp-quote 
					(file-name-nondirectory image-name))))))
    (append
     (let ((full-name (concat image-name ".image")))
       (and (or (null no-root) (not numbered-versions))
	    (file-exists-p full-name) 
	    (list full-name)))
     (sort numbered-versions
	   (lambda (n1 n2)
	     (let ((v1 (squeak-version-number n1))
		   (v2 (squeak-version-number n2)))
	       (loop for n in v1
		     for m in v2
		     if (> m n) return t
		     if (< m n) return nil
		     finally return (< (length v1) (length v2)))))))))

;(squeak-image-versions "$SURMULOTDIR/squeak/muO.image")
;(squeak-image-versions "$SURMULOTDIR/squeak/muO.image" t)
;(squeak-latest-image (surmulot-squeak-widget-image))
;(squeak-latest-image "$SURMULOTDIR/squeak/muO.image")

;;; ---------------------------------------------------------------------------
;;;
;;; connection
;;;
;;; ---------------------------------------------------------------------------


(defun squeak-start (&optional confirmation-message image-file script-file)
  "Start Squeak image IMAGE-FILE.
The VM executable is specified in variable `squeak-tcpip-vm'
IMAGE-FILE defaults to the value of function `squeak-tcpip-default-image'
SCRIPT-FILE is a Smalltalk script which will be evaluated at start up.
If CONFIRMATION-MESSAGE is not nil, it is supposed to be a string; the user
will be prompted to answer yes or no to that message in order to confirm the
starting up of squeak"
  (when (or (null confirmation-message) 
	    (y-or-n-p confirmation-message))
   (save-window-excursion
     (with-temp-buffer
       (cd (file-name-directory (squeak-tcpip-vm)))
       (shell-command 
	(format "%s %s %s %s &"
		(safe-shell-quote-argument (squeak-tcpip-vm))
		(squeak-tcpip-vm-options)
		(safe-shell-quote-argument 
		 (or image-file (squeak-tcpip-default-image))) 
		(safe-shell-quote-argument (or script-file "")))
	 (generate-new-buffer-name " *Squeak VM*"))))))

(defun squeak-start-and-connect 
  (&optional confirmation-message image-file script-file port)
  "Start Squeak image IMAGE-FILE.
The VM executable is specified in variable `squeak-tcpip-vm'
IMAGE-FILE defaults to the value of function `squeak-tcpip-default-image'
SCRIPT-FILE is a Smalltalk script which will be evaluated at start up.
If CONFIRMATION-MESSAGE is not nil, it is supposed to be a string; the user
will be prompted to answer yes or no to that message in order to confirm the
starting up of squeak.
When no PORT is specified, the image is supposed to open immediately a socket
listening to `squeak-tcpip-port'.
\(see Smalltalk EmacsInteraction>>startOnPort:)
If the image do not set up the socket, this can be coded in SCRIPT-FILE. 
\(see `squeak-start-image-on-port' for an example of use)
Return the connection process."
  (when (or (null confirmation-message) 
	    (y-or-n-p confirmation-message))
   (save-window-excursion
     (with-temp-buffer
       (cd (file-name-directory (squeak-tcpip-vm)))
       (shell-command 
	(format "%s %s %s &"
		(safe-shell-quote-argument (squeak-tcpip-vm))
		(safe-shell-quote-argument 
		 (or image-file (squeak-tcpip-default-image))) 
		(safe-shell-quote-argument (or script-file "")))
	 (generate-new-buffer-name " *Squeak VM*"))))
;;; ??
   (when (featurep 'surman)
      (while (not (squeak-connected-via-surman-p))
				    (sit-for 1))
      (squeak-eval "EmacsInteraction restart"))
;;;
   (squeak-tcpip-connect port)))

(defun safe-shell-quote-argument (arg)
  (if (string= arg "") ""
    (shell-quote-argument arg)))

(defmacro with-squeak-on-port (port &rest body)
  "Evaluate BODY in the comint buffer associated to PORT.
When PORT is nil, this is the Squeak console buffer"
  (declare (indent 1))
  `(save-excursion
    (set-buffer (squeak-buffer-name ,port))
    ,@body))

(defun squeak-tcpip-connect (&optional port once)
  "Set up a comint buffer on a TCP/IP process on port PORT.
When nil, PORT defaults to `squeak-tcpip-port'.
If ONCE try and connect only once; else try harder.
Return the newly started process."
  (let (proc)
    (flet ((connect () (make-comint
			(squeak-buffer-root-name port) 
			(cons "127.0.0.1" (or port squeak-tcpip-port)))))
      (loop repeat 300
	    unless (or (condition-case nil (connect) (error nil))
		       (when once (error "connection failed")))
	    do (sit-for 0.2))
      (connect) ;; so that an error is thrown if connection eventually failed
      (with-squeak-on-port port
	(set (make-local-variable 'squeak-tcpip-last-evalue) "<nope>")
	(set (make-local-variable 'squeak-tcpip-last-output) "")
	(set (make-local-variable 'squeak-tcpip-accumulated-preoutput) "")
	(set (make-local-variable 'comint-input-sender) 
	     (function squeak-tcpip-simple-send))
	(set (make-local-variable 'comint-preoutput-filter-functions)
	     (list 'squeak-tcpip-preoutput-filter))
	(add-to-list (make-local-variable 'comint-output-filter-functions)
		     'comint-truncate-buffer)
	(set (make-local-variable 'squeak-tcpip-process)
	     (get-buffer-process (current-buffer)))
	(setq proc squeak-tcpip-process)))
    proc))

(defun squeak-port-for-process (process)
  "Return the local port number for PROCESS \(a TCP/IP process)"
  (second (process-contact process)))

(defun squeak-buffer-root-name (&optional port)
  (if (and port (not (= port squeak-tcpip-port)))
      (format "Squeak on port %s" port)
    "Squeak console"))

(defun squeak-buffer-name (&optional port)
  (format "*%s*" (squeak-buffer-root-name port)))

(defun squeak-tcpip-process (&optional port)
  (get-buffer-process (squeak-buffer-name port)))

(defun squeak-tcpip-simple-send (proc string)
  (comint-send-string proc (squeak-tcpip-format-for-sending string)))

(defun squeak-comint-buffer (port)
  (get-buffer (squeak-buffer-name port)))

;;; ---------------------------------------------------------------------------
;;;
;;; encoding
;;;
;;; ---------------------------------------------------------------------------


(defun squeak-decode (string &optional clear) 
  "Convert STRING from Squeak coding system.
By default STRING is supposed to be in base64 compressed form; set CLEAR
to a non-nil value if STRING is not compressed."
  (decode-coding-string (if clear string
			  (base64-decode-string string)) 
			'compound-text-mac))
;'utf-8-emacs))

(defun squeak-encode (string &optional clear) 
  "Convert STRING to Squeak coding system.
By default also compress STRING in base64 format; set CLEAR to a non-nil 
value to keep STRING uncompressed."
  (let ((str (encode-coding-string string 'compound-text-mac)))
    (if clear str
      (base64-encode-string str t))))

(defun squeak-encode-region (&optional beg end)
  (interactive "r")
  (squeak-encode
   (buffer-substring-no-properties beg end)))

(defun squeak-encode-buffer ()
  (squeak-encode-region (point-min) (point-max)))


;;; ---------------------------------------------------------------------------
;;;
;;; console output filter
;;;
;;; ---------------------------------------------------------------------------

(defun squeak-output-is-command (str)
  "Return nil if str is not an elisp command from Squeak
else return the command as a string to be read"
  (when (and (>= (length str) (+ 7 8))
	     (equal (substring str 0 7) "<ELisp>")
	     (equal (substring str -8) "</ELisp>"))
    (substring (substring str 0 (- (length str) 8))
	       7)))

;TEST (squeak-output-is-command "(+ 1 2)") => nil
;TEST (squeak-output-is-command "<ELisp>(+ 1 2)</ELisp>") => "(+ 1 2)"
;TEST (eval (read (squeak-output-is-command "<ELisp>(+ 1 2)</ELisp>"))) => 3

(defun squeak-tcpip-preoutput-filter (strinput)
  (let ((str "")
	(output "")
	(command "")
	(decoded-str ""))

    (setq squeak-tcpip-accumulated-preoutput
          (concat squeak-tcpip-accumulated-preoutput strinput))

    ;; remove all ?\n at the beginning
    (while (and (> (length squeak-tcpip-accumulated-preoutput) 0)
                (equal (elt squeak-tcpip-accumulated-preoutput 0) ?\n))
      (setq squeak-tcpip-accumulated-preoutput 
            (substring squeak-tcpip-accumulated-preoutput 1)))

    ;; if one ?\n is left, at least one expression is complete
    (while (and (string-match "\n" squeak-tcpip-accumulated-preoutput)
                (setq str (car (split-string squeak-tcpip-accumulated-preoutput
					     "\n" t))))

      (setq decoded-str (squeak-decode str))

      ;; reduce the stack by removing first expression str
      (setq squeak-tcpip-accumulated-preoutput 
            (substring squeak-tcpip-accumulated-preoutput 
		       (1+ (max (length str) 1))))

      ;; again remove all ?\n in the beginning
      ;;  ... then start over as long as ?\n are found
      (while (and (> (length squeak-tcpip-accumulated-preoutput) 0)
                  (equal (substring squeak-tcpip-accumulated-preoutput 0 1)
			 "\n"))
        (setq squeak-tcpip-accumulated-preoutput
              (substring squeak-tcpip-accumulated-preoutput 1)))

      ;; Lisp expression to be evaluated (see EmacsInteraction>>elisp:)
      (when (setq command (squeak-output-is-command decoded-str))
	(squeak-tcpip-send-string 
	 (condition-case nil
	     (prin1-to-string (eval (read command)))
	   (error squeak-tcpip-ELisp-error))))

      (unless (and command squeak-console-hide-commands)
	(setq output (concat output decoded-str))))

    ;; storing current value
    (setq str (replace-regexp-in-string squeak-tcpip-prompt "" decoded-str)
	  squeak-tcpip-last-output str
	  squeak-tcpip-last-evalue str)

    ;; output is what is eventually printed in console
    (setq output (replace-regexp-in-string 
		  squeak-tcpip-prompt 
		  "" 
		  output))
    (if (string= output "")
      ""
     (format "%s\n%s" output squeak-tcpip-prompt))))


;;; ---------------------------------------------------------------------------
;;;
;;; Squeak console
;;;
;;; ---------------------------------------------------------------------------

(defmacro squeak-console-button-do (label info &rest body)
  `(propertize 
    ,label
    'face 'custom-button-face
    'mouse-face 'custom-button-pressed-face
    'help-echo ,info
    'local-map
    '(keymap (header-line keymap
			  (mouse-1 . (lambda () (interactive) ,@body))
			  (mouse-3 . (lambda () (interactive) ,@body))
			  (mouse-2 . (lambda () (interactive) ,@body))))))

(defun display-squeak-tcpip-console ()
  "Open a buffer establishing an interactive TCP/IP connection with Squeak.
Which image is started depends on function `squeak-tcpip-default-image'.
That image is supposed to immediately open a socket on port `squeak-tcpip-port';
when that port is already open, no special action is taken apart from 
displaying the console buffer"
  (interactive)
  (if squeak-tcpip-console-is-special
      (add-to-list 'special-display-buffer-names "*Squeak console*"))
  (condition-case nil
      (progn
	(when (and (featurep 'surman)
		   (squeak-connected-via-surman-p))
	  (squeak-eval "EmacsInteraction restart"))
	(squeak-tcpip-connect nil t))
    (error (squeak-start-and-connect 
	    (unless (featurep 'surman)
	      "Connection was refused. Shall I launch Squeak ?"))))
  (when (get-buffer-process "*Squeak console*")
    (save-excursion
      (set-buffer "*Squeak console*")
      (setq header-line-format
	    (list
	     "- Squeak TCP/IP console - "
	     (squeak-console-button-do 
	      " Restart " "(display-squeak-tcpip-console)"
	      (display-squeak-tcpip-console)
	      (end-of-buffer))
	     " "
	     (squeak-console-button-do 
	      " Kill " "Kill buffer & disconnect"
	      (let ((kill-buffer-query-functions nil))
		(when (squeak-connected-somehow-p)
		  (squeak-eval "EmacsInteraction stop"))
		(kill-buffer))))))
    (display-buffer "*Squeak console*")
    (squeak-eval-with-return squeak-tcpip-init-command)))


;;; ---------------------------------------------------------------------------
;;;
;;; high-level communication
;;;
;;; ---------------------------------------------------------------------------
          
(defun squeak-tcpip-send-region (beg end &optional port)
  (interactive "r")
  (if (squeak-tcpip-process port)
      (squeak-tcpip-send-string
       (subst-char-in-string 
	?\n ? 
	(buffer-substring-no-properties beg end)))))

(defun squeak-eval-with-return (&optional str port)
  "Has its argument (a string) evaluated as Squeak code.
Always returns a string. Return with an error message if
`squeak-eval-with-return-timeout' has elapsed with no answer."
  (interactive "P")
  (when (null str)
    (setq str (read-from-minibuffer squeak-tcpip-prompt)))
  (unless (and (squeak-tcpip-process port)
	       (eq (process-status (squeak-tcpip-process port)) 'open))
    (if port
        (error "port not available")
      (squeak-start-and-connect)))
  (with-squeak-on-port port
    (setq squeak-tcpip-last-evalue "<nope>")
    (squeak-tcpip-send-string str)
    (let ((timer 0))
      (while (and (eq (process-status (get-buffer-process (current-buffer)))
				      'open)
		  (< timer squeak-eval-with-return-timeout)
		  (or (string= squeak-tcpip-last-evalue "<nope>") 
		      (string= squeak-tcpip-last-evalue ""))) ;; ??
	(accept-process-output nil 0.05)
	(setq timer (+ 0.05 timer))))
    (let ((result squeak-tcpip-last-evalue))
      (setq squeak-tcpip-last-evalue "<nope>")
      result)))

(defun squeak-eval-no-return (&optional str port)
  "Has its argument (a string) evaluated as Squeak code"
  (interactive "P")
  (when (null str)
    (setq str (read-from-minibuffer squeak-tcpip-prompt)))
  (unless (and (squeak-tcpip-process port)
	       (eq (process-status (squeak-tcpip-process port)) 'open))
    (if port
        (error "port not available")
      (squeak-start-and-connect)))
  (with-squeak-on-port port
    (squeak-tcpip-send-string str)))

(defun squeak-eval-buffer-string (beg end &optional port)
  (squeak-eval-with-return (buffer-substring beg end) port))

(defun squeak-tcpip-send-string (str)
  (process-send-string 
   squeak-tcpip-process (squeak-tcpip-format-for-sending str)))

(defun squeak-tcpip-format-for-sending (str)
  ""
  (format "%s \"end\"" 
	  (with-temp-buffer
	    (insert str)
	    (goto-char (point-min))
	    (while (search-forward "!#" nil t)
	      (let* ((beg (point))
		     (val (progn
			    (forward-sexp)
			    (eval (read (buffer-substring beg (point)))))))
		(delete-region (- beg 2) (point))
		(insert (prin1-to-string val))))
	    (buffer-string))))

;;; --------------------------- End  -----------------------------

(provide 'squeak-tcpip)

;;; squeak-tcpip.el ends here








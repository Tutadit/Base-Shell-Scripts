;;; -*- auto-recompile: t -*-

;; This file is not part of GNU Emacs.
;; 
;; surmulot.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; surmulot.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;-------------
;;             Surmulot integration 

;; last modified November 19, 2010
;;; --------------------------------------------------------------------------------
(require 'cl)    
(require 'squeak)    
(require 'csound-x)
(require 'winner)

(defgroup surmulot nil
  "Emacs side of the Surmulot environment for musical composition"
  :link '(info-link :tag "Surmulot documentation (Info)" "(surmulot)Top")
  :group 'emacs)

(defgroup surmulot-paths nil
  "Variables defining a path for Surmulot"
  :group 'spfa-paths)

(defun surmulot-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-directory)))

(defcustom surmulot-squeak-directory "$SURMULOTDIR/squeak"
  "Directory for all things Squeak"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-squeak-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-squeak-directory)))

(defcustom surmulot-csound-directory "$SURMULOTDIR/csound"
  "Directory for all things Csound"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-csound-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-csound-directory)))

(defcustom surmulot-csd-directory "$SURMULOTDIR/csound/csd"
  "Directory for CSD files"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-csd-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-csd-directory)))

(defcustom surmulot-keykit-directory "$SURMULOTDIR/keykit"
  "Directory for all things Keykit"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-keykit-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-keykit-directory)))

(defcustom surmulot-midi-directory "$SURMULOTDIR/midi"
  "Directory for MIDI files"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-midi-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-midi-directory)))

(defcustom surmulot-abc-directory "$SURMULOTDIR/abc"
  "Directory for ABC files"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-abc-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-abc-directory)))

(defcustom surmulot-scripts-directory "$SURMULOTDIR/scripts"
  "Directory for Eshell scripts"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-scripts-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-scripts-directory)))

(defcustom surmulot-bin-directory "$SURMULOTDIR/bin"
  "Directory for executable files"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-bin-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-bin-directory)))

(defcustom surmulot-tmp-directory "$SURMULOTDIR/tmp"
  "Directory for temporary files"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-tmp-directory ()
  (substitute-in-file-name surmulot-tmp-directory))

(defcustom surmulot-doc-directory "$SURMULOTDIR/documentation"
  "Directory for extra documentation"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-doc-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-doc-directory)))

(defcustom surmulot-emacs-directory "$SURMULOTDIR/emacs"
  "Directory for all things Emacs"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-emacs-directory (&optional file-name)
  (expand-file-name
   (or file-name "")
   (substitute-in-file-name surmulot-emacs-directory)))

(defcustom surmulot-scales-directory "$SURMULOTDIR/scales"
  "Directory for musical scales, which are files in Scala format."
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-scales-directory ()
  (substitute-in-file-name surmulot-scales-directory))

(defcustom surmulot-timidity-directory "$SURMULOTDIR/timidity"
  "Directory for all things Timidity"
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-timidity-directory ()
  (substitute-in-file-name surmulot-timidity-directory))

(defcustom surmulot-soundfonts-directory "$SURMULOTDIR/soundfonts"
  "Directory for soundfonts."
  :type 'directory
  :group 'surmulot-paths)

(defun surmulot-soundfonts-directory ()
  (substitute-in-file-name surmulot-soundfonts-directory))

(defcustom surmulot-timidity-cfg "$SURMULOTDIR/timidity/timidity.cfg"
  "Timidity configuration file for Surmulot"
  :type 'file
  :group 'spfa-paths)

(defun surmulot-timidity-cfg ()
  (expand-file-name (substitute-in-file-name surmulot-timidity-cfg)))

(defcustom surmulot-timidity-man "$SURMULOTDIR/timidity/man.html"
  "HTML manual for Timidity"
  :type 'file
  :group 'spfa-paths)

(defun surmulot-timidity-man ()
  (expand-file-name (substitute-in-file-name surmulot-timidity-man)))

(require 'surmulot-midi)
(require 'surmulot-widget)
(require 'surmulot-csd)
(require 'surmulot-eshell)
(require 'surmulot-python)
(require 'csound-fluid)

(put 'surmulot 'custom-group
     (union (get 'surmulot 'custom-group)
	    '((csound-x custom-group)
	      (squeak custom-group)
	      (timidity-cfg custom-group)
	      (surmulot-widget custom-group)
	      (spfa-paths custom-group)
	      (keykit custom-group))
	    :test 'equal))

;;; ============================ testing

(defun muo-connected-p ()
  (squeak-connected-somehow-p))


(defun surmulot-assert (test result)
  (let ((val (squeak-eval test)))
    (or (string= val result) val)))	

(defun surmulot-tests ()
  (and
   (surmulot-assert "1+1" "2")
   (surmulot-assert "1 + (SurmulotManager askEmacsFor: '(+ 8 7)')" "16")
   (surmulot-assert "(SurmulotManager askEmacsFor: '(shell-command-to-string \"echo 42\")') asInteger" "42")   
   ;; hairy... 
   (surmulot-assert 
    "SurmulotManager askEmacsFor: '(surmulot-assert \"2+2\" \"4\")'" "'t'")))
;TEST (surmulot-tests) => t

;TEST (squeak-eval "(SurmulotManager askEmacsFor: '(+ 8 7)') first") => "$1"
;TEST (squeak-eval "SurmulotManager askEmacsFor: '(+ 1 1)'") => "'2'"
;TEST (squeak-eval "SurmulotManager askEmacsFor: '(+ 1 (read (squeak-eval \"1+1\")))'") => '"'3'"

(defun surmulot-run-all-comment-tests ()
  (interactive)
  (require 'comm-tests)
  (require 'csound-fx)
  (require 'csound-tests)
  (unless (squeak-connected-via-surman-p)
    (squeak-start)); -and-connect))
  (apply 'run-commented-tests-in 
	 (set-difference 
	  (append
	   (directory-files (file-name-directory (locate-library "surmulot")) 
			    nil "\\.el$") 
	   (directory-files (file-name-directory (locate-library "csound-x")) 
			    nil "\\.el$"))
	  '("comm-tests.el" "surman.el") :test 'string=)))


;;; ============================ meta: surmulot system description

(defvar surmulot-directory (getenv "SURMULOTDIR")
  "root directory for the surmulot distribution")   

(defvar this-surmulot-version nil
  "holds the current surmulot version number")

(defvar this-surmulot-elisp-version nil
  "holds the current stef-elisp version number")

(defvar this-surmulot-muo-version nil
  "holds the current muO version number")

(defvar this-surmulot-gm-version nil
  "holds the current GeoMaestro version number")

(defvar this-surmulot-published-files nil
  "holds the list of all files in the current surmulot release")

(defun surmulot-fetch-meta-info ()
  (when (boundp 'surmulot-directory) ;; this is defined in surmulot.emacs
    (load (expand-file-name "meta/surmulot-org.el" surmulot-directory) t)))

(surmulot-fetch-meta-info)

(defun surmulot-check-up ()
  (let ((modified))
    (dolist (fspec this-surmulot-published-files)
      (when (consp fspec)
        (let* ((file (car fspec))
               (fname (expand-file-name file surmulot-directory))
               (fmd5 (cdr fspec)))
          (unless (and (file-exists-p fname)
                       (string= fmd5 (with-temp-buffer
                                       (insert-file-contents fname)
                                       (md5 (current-buffer) nil nil 'raw-text))))
            (add-to-list 'modified file)))))
    (or modified t)))

;;TO DO:
;;       repair from archive (use 7za) !!


;;; ==============================================================

(defun custom-initialize-setting (symbol)
  "Reset the value of SYMBOL by re-evaluating its standard value.
Use the :set function to do so."
  (funcall (or (get symbol 'custom-set) 'set-default)
	   symbol
	   (eval (car (get symbol 'standard-value)))))

(defun surmulot-use-system-csound (&optional binary doc-dir)
  "Redefine all appropriate settings so that the version of Csound
shipped as part of Surmulot is ignored, and make the system-wide Csound
be used by Csound-x.
This can be reversed by invoking function `surmulot-use-bundled-csound'"
  (interactive)
  (require 'csound-csd)
  (require 'csound-doc)
  (custom-set-default 'cscsd-csound-binary (or binary (csound-find-binary)))
  (if doc-dir
      (custom-set-default 'csdoc-html-directory doc-dir)
    (custom-initialize-setting 'csdoc-html-directory))
  (custom-initialize-setting 'csdoc-html-entry-point)
  (cscsd-open-to-environment
   '("SFDIR" "SADIR" "SSDIR" "INCDIR" "MFDIR"))
  (message "Surmulot settings now target the system Csound installation"))

(defun surmulot-use-bundled-csound ()
  "Redefine all appropriate settings so that the version of Csound
shipped as part of Surmulot is the one used by Csound-x.
This can be reversed by invoking function `surmulot-use-system-csound'"
  (interactive)
  (dolist (symbol '(cscsd-csound-binary
		    csdoc-html-directory
		    csdoc-html-entry-point
		    csdoc-winhelp-file))
    (set symbol (car (get symbol 'saved-value))))
  (dolist (var cscsd-hidden-environment-variables)
    (let* ((symbol (intern (concat "cscsd-" var)))
	   (value (car (get symbol 'saved-value))))
      (message "setting env variable %s to \"%s\"" var value)
      (set symbol value)
      (setenv var (expand-file-name (substitute-in-file-name value)))))
  (message "Surmulot settings now target the bundled Csound installation"))

(defcustom surmulot-always-use-system-csound 
  (not (eq system-type 'windows-nt))
  "When not nil, ignore by dedault the csound distribution bundled with 
Surmulot and instead use the existing installation, if any."
  :set (lambda (option value)
	 (set-default option value)
	 (if value (surmulot-use-system-csound)
	   (surmulot-use-bundled-csound)))
  :type 'boolean
  :group 'surmulot)

(when (and surmulot-always-use-system-csound  
	   (not (featurep 'surmulot)))
  (surmulot-use-system-csound))	

(defun surmulot-use-bundled-csound-p ()
  (string-match "^\\$SURMULOTDIR" cscsd-INCDIR))

(defun surmulot-display-welcome-buffer ()
  (interactive)
  (if (get-buffer "about surmulot.org")
      (switch-to-buffer (get-buffer "about surmulot.org"))
    (let ((about (expand-file-name "emacs/about surmulot.org" 
				   surmulot-directory))
	  (image-file (expand-file-name "emacs/images/surmulot.jpg" 
					surmulot-directory)))
      (if (not (file-exists-p about))
	  (info "(Surmulot)Top.")
	(find-file about)
	(when (file-exists-p image-file)
	  (goto-char (point-min))
	  (insert-image (create-image image-file)))
	(set-buffer-modified-p nil)
	(toggle-read-only)))))

(defvar surmulot-do-not-compile '("calc-stef.el")
  "emacs lisp code files which should not be compiled")

(defun surmulot-byte-compile-all ()
  "byte-compile all code for surmulot"
  (interactive)
  (dolist (dir '("emacs/site-lisp/stef-elisp" 
		 "emacs/site-lisp/stef-elisp/csound-x"))
    (dolist (file (directory-files 
		   (expand-file-name dir surmulot-directory) t "\\.el$"))
      (unless (member (file-name-nondirectory file)
		      surmulot-do-not-compile)
	(byte-compile-file file)))))

(defun surmulot-go ()
  "Start the full surmulot system via emacs"
  (save-window-excursion
    (with-temp-buffer
      (cd (file-name-directory (squeak-tcpip-launch-command)))
      (shell-command 
       (format "%s &"
	       (shell-quote-argument (squeak-tcpip-launch-command))))))
  (save-window-excursion
    (with-temp-buffer
      (cd (kk-tcpip-key-start-directory))
      (call-process (kk-tcpip-key-command) nil 0))))


;;========================= searching Surmulot code

(defun surmulot-code-files ()
  (append
   (remove-if-not
    (lambda (f) (member (file-name-directory f) load-path))
    (deep-directory-files 
     (expand-file-name "emacs/site-lisp/stef-elisp" surmulot-directory)
     "\\.el$"))
   (mapcar
    (lambda (f) (expand-file-name f surmulot-directory))
    '("emacs/surmulot.emacs" "emacs/surmulot-manager.el"))))

(defun surmulot-querysheet ()
  (new-querysheet (surmulot-code-files) "Surmulot code search"))

(defun surmulot-display-querysheet ()
  (interactive)
  (switch-to-buffer
   (qsheet-get-buffer-create-sheet (surmulot-querysheet))))


;;========================= automatic deconnection upon killing

(defadvice save-buffers-kill-emacs (before deconnect-manager)
  "first deconnect emacs from its surmulot manager"
  (if (surman-connected-p)
      (surman-disconnect)))

(ad-activate 'save-buffers-kill-emacs)


;;========================= surmulot info

(when (require 'info nil t)
  (add-to-list 'Info-additional-directory-list 
	       (expand-file-name "emacs/" surmulot-directory))
  (add-to-list 'Info-additional-directory-list 
	       (substitute-in-file-name "$SURMULOTDIR/info")))


;;========================= surmulot menu

(winner-mode t)

(defun surmulot-spfa-p ()
  "Tells weither we are in the development version, SPFA's Surmulot."
  (file-exists-p (concat surmulot-directory "/allow.publication")))

(defconst surmulot-documentation-odt-files
   '("Surmulot overview.odt"
     "The Mixing Algebra of Musical Elements in muO.odt" 
     "String representation of musical phrases in muO.odt"
     "The Representation of Rhythmic Structures in muO.odt"
     "The Representation of Dynamics in muO.odt"
     "Modes and Scales in muO.odt"
     "Harmony in muO.odt"
     "Usages of CompositeMix in muO.odt"
     "Working with Csound in Surmulot.odt"
     "High-level Musical Concepts in muO.odt"
     "Surmulot perspectives.odt"))

(defun surmulot-make-global-menu ()
  (easy-menu-define surmulot-menu global-map
    "surmulot menu"
    `("<Surmulot>"
      ["Welcome to Surmulot" surmulot-display-welcome-buffer t]  
      ("Documentation"
       ["Surmulot documentation" (info "surmulot") t]
       ["muO documentation" (info "muO") t]
       ["muO doc books" (call-interactively 'muo-doc) t]
       ["Csound-x documentation" (info "csound-x") t] 
       ["Csound realtime examples"
	(dired (substitute-in-file-name 
		"$SURMULOTDIR/csound/library/CsoundRealtimeExamples")) t]
       "--"
       ["CMask documentation" 
	(browse-url-of-file (substitute-in-file-name 
			     "$SURMULOTDIR/bin/cmask03manual.pdf")) t]
       ["athenaCL documentation" 
	(browse-url-of-file
	 (substitute-in-file-name 
	  "$SURMULOTDIR/python/athenaCL/doc/athenaclManual.htm")) t]
       ["music21 documentation"
	(browse-url-of-file 
	 (substitute-in-file-name 
	  "$SURMULOTDIR/python/music21/doc/music21.html")) t]
       ["abc standard"
	(browse-url-of-file 
	 (substitute-in-file-name 
	  "$SURMULOTDIR/documentation/abc standard v2.0.htm")) t]
       ["abc2midi guide"
	(browse-url-of-file 
	 (substitute-in-file-name 
	  "$SURMULOTDIR/documentation/abc2midi_guide.html")) t]
       ,@(when (surmulot-spfa-p)
	   '("--"
	     ["Ricci Adams' musictheory.net" 
	      (browse-url-of-file 
	       (substitute-in-file-name
		"$SURMULOTDIR/documentation/musictheory.net/START.html")) t]))
       "--"
       ["Known bugs" 
	(find-file (substitute-in-file-name "$SURMULOTDIR/bugs.txt")) t]) 
      "--"
      ["Back to previous buffers" winner-undo winner-mode]
      ["(cancel)" winner-redo winner-mode]
      "--"
      ("Editing"
       ["CD to file directory" 
	(cd (file-name-directory (buffer-file-name))) (buffer-file-name)]
       ["Remove all ^M characters"
	(save-excursion (goto-char (point-min)) 
			(while (re-search-forward "\r+$" nil t)
			  (replace-match "" t t))) t]
       ["Select all"                mark-whole-buffer t]
       ["Untabify region"           untabify t]
       "--"
       ("Major modes"
	["Csound CSD" csound-csd-mode t]
	["Csound Orc" csound-orc-mode t]
	["Csound Sco" csound-sco-mode t]
	["Keykit" keykit-mode t]
	["Emacs lisp" (emacs-lisp-mode) t]
	["Text" text-mode t])
       ("Minor modes"
	["Eldoc" eldoc-mode :style toggle 
	 :selected  (condition-case nil eldoc-mode (error nil))])
       "--"
       ["Display search buffer"     qsheet-display-search-buffer t]
       ["Get clipboard"    (progn (switch-to-buffer
				   (get-buffer-create "*from clipboard*"))
				  (clipboard-yank)) t])
      "--"
      ("Environment"
       ["Start Squeak" (with-temp-buffer (require 'squeak)
					 (squeak-start)) t] ;-and-connect)) t]
       ["Start Keykit" kk-tcpip-launch-key t]
       "--"
       ["Start manager" surman-start-manager (not (surman-connected-p))]
       ["Connect to manager" surman-connect (not (surman-connected-p))]
       ["Disconnect from manager" (progn (surman-disconnect)
					 (surman-cancel-daemon))
	(surman-connected-p)]
       ["Start manager daemon" surman-start-daemon 
	(and
	 (not (surman-daemon-waiting-p))
	 (not (surman-connected-p)))]
       ["Kill manager daemon" surman-cancel-daemon surman-is-daemon]
       "--"
       ["List all processes" list-processes t]
       "--"
       ["Kill all processes" (mapcar 'kill-buffer
				     (mapcar 'process-buffer (process-list)))
	(process-list)]
       ["Kill Emacs abruptly (no hook)" 
	(when (y-or-n-p "really kill emacs right now ?") 
	  (setq kill-emacs-hook nil) (kill-emacs)) t])
      ("Interaction"
       ["Surmulot Eshell" (with-temp-buffer
		   (cd (substitute-in-file-name "$SURMULOTDIR"))
		   (eshell)) t]
       ["Open Squeak console" (with-temp-buffer 
				(require 'squeak)
				(unless (squeak-connected-via-surman-p)
				  (squeak-start)
				  (while (not (squeak-connected-via-surman-p))
				    (sit-for 1)))
				(squeak-eval "EmacsInteraction restart")
				(display-squeak-tcpip-console)) t]
       ["Open Keykit console" (with-temp-buffer 
				(require 'keykit-mode) (kk-tcpip)) t]
       "--"
       ["System shell"         shell t]
       ["Python shell"         python t]
       ["Clojure" surmulot-start-clojure (featurep 'csound-clj)]
       ["athenaCL (Python)" 
	(progn 
	  (require 'python)
	  (python)
	  (set-buffer "*Python*")
	  (rename-buffer "*athenaCL (Python)*")
	  (add-to-list 'comint-output-filter-functions
		       'surmulot-athenaCL-output-filter)
	  (comint-send-string (get-buffer-process (current-buffer))
			      "import athenaCL.athenacl\nn\n"))
	t]
       ["music21 (Python)"
	(progn
	  (require 'python)
	  (python)
	  (set-buffer "*Python*")
	  (rename-buffer "*music21 (Python)*")
	  (add-to-list 'comint-output-filter-functions
		       'surmulot-music21-output-filter)
	  (comint-send-string (get-buffer-process (current-buffer))
			      "from music21 import *\n"))
	t]
     ,@(when (surmulot-spfa-p)
	 '("--"
	   ["hsc3 (Haskell)" (progn
			     (require 'haskell-mode)
			     (require 'hsc3)
			     (hsc3-start-haskell)) t]
	   ["racket" (progn
		       (add-to-list 'Info-additional-directory-list 
				   (concat surmulot-directory
					   "/emacs/site-lisp/geiser-0.3/doc/"))
		       (setq geiser-racket-binary 
			     "c:/program files/Racket/racket.exe")
		       (load-file
			(concat surmulot-directory
				"/emacs/site-lisp/geiser-0.3/elisp/geiser.el"))
		       (run-geiser 'racket)) t])))
      "--"
      ("Settings"
       ["Customize Surmulot" (customize-group 'surmulot) t]
       ["Customize paths" (customize-group 'spfa-paths) t]     
       ["Customize Csound-x" (progn (require 'csound-sco)
				    (require 'csound-mx)
				    (require 'csound-ft)
				    (require 'csound-ses)
				    (customize-group 'csound-x)) t]
       "--"
       ["Set local ports numbers" 
	(progn
	  (find-file (substitute-in-file-name "$SURMULOTDIR/localports.ini"))
	  (find-file-other-window 
	   (substitute-in-file-name 
	    "$SURMULOTDIR/csound/include/surmulot-OSC-ports.orc")))
	t]
       "--"
       ["Use system Csound" surmulot-use-system-csound 
	:style toggle
	:selected (not (surmulot-use-bundled-csound-p))]
       ["Use bundled Csound" surmulot-use-bundled-csound 
	:style toggle
	:selected (surmulot-use-bundled-csound-p)]
       ["Use Cog VM" (setq squeak-tcpip-use-cog-vm 
			   (not squeak-tcpip-use-cog-vm))
	:style toggle
	:selected squeak-tcpip-use-cog-vm]
       "--"
       ["Visit Timidity configuration file" surmulot-visit-timcfg t])
      ("Emacs code"
       ["Byte-compile all code" surmulot-byte-compile-all t]
       ["Search all code" surmulot-display-querysheet t]
       ["Visit init-file" (find-file user-init-file) t]
       ["Edit Surmulot menu" (find-function 'surmulot-make-global-menu) t])
      ("Csound code"
       ["Refresh DSP effects library" 
	csfx-install-library (featurep 'csound-fx)]
       ["Edit OSC controls" 
	(find-file (substitute-in-file-name surmulot-OSC-controls-source)) t]
       ["Refresh OSC controls list" surmulot-OSC-controls t])
      ("Testing/Debugging"
       ["Run all tests" surmulot-run-all-comment-tests t]
       ["Known bugs" 
	(find-file (substitute-in-file-name "$SURMULOTDIR/bugs.txt")) t]
       ["Contact the author"
	(let ((url
	       "mailto:hepta@zogotounga.net?subject=about surmulot"))
	  (case system-type
	    (windows-nt (w32-shell-execute "open" url))
	    (gnu/linux (call-process "xdg-open" nil nil nil url))
	    (t (browse-url url))))
	t])
      "--"
      ["Save desktop on exit"
       (customize-variable 'desktop-save-mode) 
       :style toggle :selected desktop-save-mode]
      ["Erase saved desktop" (delete-file (desktop-full-file-name))
       (file-exists-p (desktop-full-file-name))]

      ,@(when (surmulot-spfa-p)
	  (require 'makeinfo)
	  (setq makeinfo-run-command
		(substitute-in-file-name "$SURMULOTDIR/bin/makeinfo.exe"))
	  (list
	   "--"
	   '("Development"
	     ["Browse Csound-x code"
	      (dired (substitute-in-file-name
		      "$SURMULOTDIR/emacs/site-lisp/stef-elisp/csound-x")) t]
	     ["Browse Surmulot code"
	      (dired (substitute-in-file-name
		      "$SURMULOTDIR/emacs/site-lisp/stef-elisp/surmulot")) t]
	     "--"
	     ["Edit Csound-x documentation" 
	      (find-file
	       (concat
		surmulot-directory 
		"/emacs/site-lisp/stef-elisp/csound-x/csound-x.texi")) t]
	     ["Edit Surmulot documentation" 
	      (find-file (concat surmulot-directory "/emacs/surmulot.texi")) t]
	     ["Edit muO documentation" 
	      (find-file (concat surmulot-directory "/emacs/muo.texi")) t]
	     "--"
	     ["Edit Surmulot deployment scripts" 
	      (find-file
	       (concat surmulot-directory "/emacs/surmulot-scripts.el")) t]
	     "--"
	     ["Refresh opcode database and typology cache files" 
	      csdoc-refresh-opcode-database t])
	   (append '("Edit reference documentation")
		   (mapcar
		    (lambda (odt) 
		      `[,odt (browse-url-of-file 
			      (substitute-in-file-name 
			       (concat "$SURMULOTDIR/documentation/" ,odt))) t])
		    surmulot-documentation-odt-files))
	   "--"
	   ["Update Csound databases"
	    (progn
	      (csdoc-refresh-opcode-database)
	      (csdoc-save-opcode-database)) t]
	   "--"
	   ["* release Surmulot *"
	    (progn
	      (require 'surmulot-scripts
		       (concat surmulot-directory "/emacs/surmulot-scripts"))
	      (surmulot-publish)) t]
	   ["* release stef-elisp *"
	    (progn
	      (require 'surmulot-scripts
		       (concat surmulot-directory "/emacs/surmulot-scripts"))
	      (script-publish-stef-elisp)) t])))))

; (surmulot-make-global-menu)

(defun surmulot-start-squeak (&optional image-file ignored)
  (interactive)
  (let ((image-file (if (and (stringp image-file)
			     (string-match "^file:.*" image-file))
			(dnd-get-local-file-name image-file t)
		      image-file)))
    (with-temp-buffer
      (require 'squeak)
      (squeak-start nil (or image-file "")))))

; muO images can be opened by drag-n-drop into emacs:
(add-to-list 'dnd-protocol-alist
	     '("^file:.*\\.image$" . surmulot-start-squeak))

;;; ==============================================================


(defun surmulot-visit-timcfg ()
  (interactive)
  (find-file (surmulot-timidity-cfg)))

; just a draft:
(defun surmulot-insert-sf2 (sf2-file ignored)
  (let* ((sf2 (dnd-get-local-file-name sf2-file t))
	 (sf (file-name-nondirectory sf2))
	 (n 0))
    (insert ?\n)
    (dolist (p (timcfg-soundfont-presets sf2))
      (insert (format "%s %%font %s %s %s  # %s\n" 
		      (incf n) sf (second p) (third p) (first p))))))
;
(add-to-list 'dnd-protocol-alist
	     '("^file:.*\\.sf2$" . surmulot-insert-sf2))


(defcustom surmulot-keykit-man "$SURMULOTDIR/keykit/index.html"
  "HTML manual for Keykit"
  :type 'file
  :group 'spfa-paths)

(defun surmulot-keykit-man ()
  (expand-file-name (substitute-in-file-name surmulot-keykit-man)))


;;; ========================= autoloads

(autoload 'abc-run-text "surmulot-abc" nil t)
(autoload 'abc-run-file "surmulot-abc" nil t)

;;; ========================= clojure and csnd (java)

(require 'csound-clj)

;;; ========================= CDP

(setenv "CDP_SOUND_EXT" "wav")


;;; --------------------------- End  -----------------------------

(provide 'surmulot)

;;; surmulot.el ends here








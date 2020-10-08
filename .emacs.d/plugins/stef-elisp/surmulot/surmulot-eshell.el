;;; -*- auto-recompile: t -*-

;; This file is not part of GNU Emacs.
;; 
;; surmulot-eshell.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; surmulot-eshell.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;-------------
;;             Surmulot in Eshell 

;; last modified April 19, 2011
;;; --------------------------------------------------------------------------

(require 'spfa-eshell)

;; TO DO: 
;;  mix
;;  drums
;;  mode
;;  abc
;;  clear eshell/bindings <-> eshell/last confusion
;;  refactoring of context/namespace, variable initialization
;;  (e.g. ensure kphrase, tabla, synth always exists in #eshell namespace
;;  ... see #initializeEshellDictionary)
;;  warning on the Squeak side when quitting without saving 
;;  emacs flap management, edit in flap
;;  panic or silence: reset all midi, kill all csound and timidity jobs
;;  do not allow too long output (such as long phrases)


(defun surmulot-eshell-file (str &optional dir)
  (let ((file-name (expand-file-name (substitute-in-file-name str)
				     default-directory)))
    (if (file-exists-p file-name)    
	file-name
      (setq file-name
	    (expand-file-name (substitute-in-file-name str) 
			      (substitute-in-file-name (or dir ""))))
      (if (or (file-exists-p file-name)
	      dir)
	  file-name
	str))))

;(surmulot-eshell-file "beuh.mid" surmulot-midi-directory)
;(surmulot-eshell-file "beuh.mid")

;(add-to-list 'eshell-mode-hook 'surmulot-new-eshell)

(defun surmulot-new-eshell ()
  (make-local-variable 'eshell-complex-commands)
  (add-to-list 'eshell-complex-commands "sscript")
  (set (make-local-variable 'squeak-namespace) '(eshell)))

(defun eshell/surmulot (&rest options)
  (eshell-eval-using-options
   "surmulot" options
   '((?h "help" nil nil "show this usage screen")
;     (?v "version" nil version "display version information")
     (?i "info" nil info "browse Eshell info")
     (?l "list" nil list "list all commands defined by Surmulot")
     (?d "document" nil document "document all commands defined by Surmulot")
     (?f "find" t find "find code for COMMAND")
     :show-usage
     :usage "[option]"
     :post-usage
"Surmulot settings entry point in Eshell.")
   (when info
     (info-other-window "(Surmulot)Eshell."))
   (when find
     (find-function-other-frame (intern (concat "eshell/" find))))
   (if list 
       (surmulot-eshell-commands)
     (when document
       (surmulot-document-commands)))))

(defun surmulot-document-commands ()
  (interactive)
  (switch-to-buffer-other-frame 
   (get-buffer-create "*Surmulot eshell commands*"))
  (erase-buffer)
  (require 'outline)
  (require 'make-regexp)
  (outline-minor-mode)
  (set (make-local-variable 'outline-regexp) 
       (make-regexp (mapcar 'prin1-to-string (surmulot-eshell-commands))))
  (local-set-key "\t" 'hide-body)
  (local-set-key "\r" 'show-entry)
  (insert
   (propertize "Type <TAB> for summary, <RETURN> to expand an entry\n"
	       (quote face) (quote (:slant italic)))
   (mapconcat
    '(lambda (s) 
       (replace-regexp-in-string "^usage: \\(.*\\)" 
	(lambda (s)
	  (propertize (match-string 1 s)
		      'face '(:weight bold :foreground "blue"))) s))
    (loop for command in (surmulot-eshell-commands)
	  collect (eshell-command-result (format "%s -h" command))
	  into all
	  finally return all) "\n\n\n"))
  (goto-char (point-min))
  (setq buffer-read-only t)
  (current-buffer))

(defvar surmulot-eshell-commands '()
  "List of all Eshell commands defined by Surmulot")

(defun surmulot-eshell-commands ()
  "Return the sorted list of all Eshell commands defined by Surmulot"
  (sort (copy-list surmulot-eshell-commands) 'string<))


;;; ===========================================================================
;;;              eshell/sfs
;;; ===========================================================================

(defvar surmulot-eshell-directories
  '(("csound" surmulot-csound-directory)
    ("keykit" surmulot-keykit-directory)
    ("tmp" surmulot-tmp-directory)
    ("ssdir" (lambda () (surmulot-csound-directory "samples")))
    ("sfdir"(lambda () (surmulot-csound-directory "rendered")))
    ("sadir" (lambda () (surmulot-csound-directory "analysis")))
    ("incdir" (lambda () (surmulot-csound-directory "include")))
    ("csoundlib" (lambda () (surmulot-csound-directory "library")))
    ("csd" surmulot-csd-directory)
    ("midi" surmulot-midi-directory)
    ("abc" surmulot-abc-directory)
    ("scripts" surmulot-scripts-directory)
    ("squeak" surmulot-squeak-directory)
    ("bin" surmulot-bin-directory )
    ("doc" surmulot-doc-directory)
    ("emacs" surmulot-emacs-directory)
    ("scales" surmulot-scales-directory)
    ("timidity" surmulot-timidity-directory)
    ("surmulot" surmulot-directory)
    ("soundfonts" surmulot-soundfonts-directory)))

(defun eshell/sfs (&rest rest)
  (eshell-eval-using-options
   "sfs" rest
   '((?h "help" nil nil "show this usage screen")
     (?a "all" nil all "display all known directories")
     (?l "list" nil list "ls DIRECTORY")
     (?b "browse" nil browse "browse FILE")
     (?B "browse-directory" nil browse-dir "browse DIRECTORY")
     (?f "find-file" nil find-file "find-file FILE")
     (?c "cd" nil cd "cd to DIRECTORY")
     (?p "print" nil print "print DIRECTORY")
     :show-usage
     :usage "[options] [DIRECTORY] [FILE]"
     :post-usage
"Access Surmulot directories via DIRECTORY keyword.
Do sfs -a to see all valid values for DIRECTORY.")
   (if all
       (mapconcat (lambda (ea)
		    (format "%-12s %s\n"
			    (car ea)
			    (funcall (cadr ea))))
		    surmulot-eshell-directories "")
     (let* ((dir-set (cadr (assoc (car args) surmulot-eshell-directories)))
	    (dir (if dir-set (funcall dir-set) default-directory))
	    (glob (if dir-set (cadr args) (car args))))
       (when browse-dir (browse-url dir))
       (if print
	   (line-concat-stringify dir)
	 (if list
	     (eshell-command-result 
	      (concat "ls " (expand-file-name (or glob "") dir)))
	   (when cd (cd dir))
	   (when glob
	     (let ((file (expand-file-name glob dir)))
	       (when browse (browse-url file))
	       (when find-file (find-file-other-frame file))
	       file))))))))

(add-to-list 'surmulot-eshell-commands 'sfs)

; sfs -b doc indian.pdf
; sfs soundfonts -l "*guitar*"

(defun eshell/sscript (&rest args)
  "Source or edit an eshell script."
  (eshell-eval-using-options
   "sscript" args
   '((?h "help" nil nil "show this usage screen")
     (?e "edit" nil edit "edit script")
     :show-usage
     :usage "SCRIPT [ARGS]
Invoke the Eshell commands in file SCRIPT  within the current shell
environment, binding ARGS to $1, $2, etc.
When SCRIPT is a relative file name, expand it relatively to the 
Surmulot \"script\" directory.")
   (let ((script-file (surmulot-scripts-directory (car args))))
     (if edit
	 (find-file-other-window script-file)
       (eshell-source-file script-file (cdr args))))))

(put 'eshell/sscript 'eshell-no-numeric-conversions t)
(add-to-list 'surmulot-eshell-commands 'sscript)


;;; ===========================================================================
;;;              eshell/bindings, eshell/last
;;; ===========================================================================

(defun eshell/bindings (&rest rest)
  (eshell-eval-using-options
   "bindings" rest
   '((?h "help" nil nil "show this usage screen")
     (?l "list" nil list "list all bindings keys (symbols)")
     (?v "values" nil values "display values")
     (?g "graphic" nil graphic "display graphical representations")
     (?u "unbind" t unbind "unbind a key")
     (?p "push" t push "push a key in its stack")
     (?o "pop" t pop "pop a key from its stack")
; (?s "stack" nil stack "have other commands apply on ?? ")
     :show-usage
     :usage "[options]"
     :post-usage
"Display all bound symbols and optionally their values.")
   (if pop
        ($$ `[SurmulotManager bindings eshellPop: ',(intern pop)])
     (if push
	 ($$ `[SurmulotManager bindings eshellPush: ',(intern push)])
       (if unbind
	   ($$ `[(SurmulotManager bindings at: 'eshell)
		 removeKey: ',(intern unbind)])
	 ($$ `[String streamContents: [:stream |
		 (SurmulotManager bindings at: 'eshell) associations do: [:b |
	    stream nextPutAll: b key \; cr
	    ,@(when graphic
		'(\; nextPutAll: b value viewForEmacs \; cr))
	    ,@(when values
		'(\; nextPutAll: b value printString \; cr))
	    ,@(when (or values graphic) '(\; cr))]]]))))))

(add-to-list 'surmulot-eshell-commands 'bindings)

(defun eshell/last (&rest rest)
  (eshell-eval-using-options
   "last" rest
   '((?h "help" nil nil "show this usage screen")
     (?b "bind" t bind "bind to a new symbol")
     (?c "copy" t copy "bind copy to a new symbol")
     (?p "print" nil print "display printed representation")
     (?d "display" nil display "display graphical representation")
;     (?s "store" nil store "display serialized representation")
     :show-usage
     :usage "SYMBOL [options]"
     :post-usage
"Recall the object currently bound to SYMBOL; some commands automatically
define bindings so e.g. \"last kphrase\" will return the last musical phrase
generated by command \"kphrase\".")
   (let ((last-object ($$ `[SurmulotManager bindings under: ',(car args)])))
     (when (or copy bind)
       ($$ `[SurmulotManager
	     bindings under: ',(or copy bind)
	     put: (SurmulotManager bindings under: ',(car args))
	          ,(if copy 'veryDeepCopy 'yourself)]))
     (if (or print display)
	 (line-concat-stringify
	  (when display
	    ($$ `[(SurmulotManager bindings under: ',(car args)) viewForEmacs]))
	  (when print
	    ($$ `[(SurmulotManager bindings under: ',(car args)) printString])))
       last-object))))

(add-to-list 'surmulot-eshell-commands 'last)

;;; ===========================================================================
;;;              eshell/tabla
;;; ===========================================================================

(defun eshell/tabla (&rest bols)
  (eshell-eval-using-options
   "tabla" bols
   '((?h "help" nil nil "show this usage screen")
     (?b "bols" nil list-bols "display all known bols")
     (?v "vilambit" nil vilambit "play slowly")
     (?d "drut" nil drut "play fast")
     (?p "parse" nil parse-bols "parse bols")
     (?x "expand" nil expand-bols "parse into basic bols")
     (?s "set" t player "set tabla player")
     (?a "all" nil all "display available tabla player")
     (?w "wav" nil wav "render bols as WAV file")
;     (?r "rewrite" nil rewrite-bols "rewrite bols in standard format")
;     (?c "count" nil count "count beats")
     :show-usage
     :usage "[options] BOLS..."
     :post-usage
"Play indian BOLS with a TablaBolPlayer")
   (when player
     ($$ `[tablaplayer <-
		       ,@(case (intern player)
			   ('sf2 '(TablaBolPlayer forSurmulot))
			   ('basic '(TablaBolPlayer new))
			   (t '(TablaBolPlayer new)))]))
   (if all
       "basic        basic WAV-based sampler
sf2          soundfont-based Csound sampler"
     (if list-bols
	 ($$ [tablaplayer> allBols])
       (let ((bols-string (mapconcat 'identity args " ")))
	 (if parse-bols
	     ($$ `[tablaplayer> parse: ,bols-string])
	   (if expand-bols
	       ($$ `[tablaplayer> read: ,bols-string
				  among: TablaBolPlayer new basicBols])
	     (if wav
		 ($$ `[wav <- (tablaplayer> ,(cond
					      (vilambit 'vilambitRender:)
					      (drut 'drutRender:)
					      (t 'render:))
					    , bols-string)])
	       ($$ `[tablaplayer> ,(cond
				    (vilambit 'vilambitPlay:)
				    (drut 'drutPlay:)
				    (t 'play:))
				  , bols-string])))))))))
 
(put 'eshell/tabla 'eshell-no-numeric-conversions t)

; tabla thun na thun

(add-to-list 'surmulot-eshell-commands 'tabla)

;;; ===========================================================================
;;;              eshell/kphrase
;;; ===========================================================================

(defun eshell/kphrase (&rest str)
  (eshell-eval-using-options
   "kphrase" str
   '((?h "help" nil nil "show this usage screen")
     (?x "hide" nil hide "do not print phrase")
     (?p "play" nil play "play phrase")
     (?P "synth-named" t synth-name "play phrase with named synthesizer")
     (?S "synth" nil synth "play phrase with synth")
     (?w "wav" t wav "convert phrase as WAV file")
     (?W "synth-wav" t synth-wav "convert phrase as WAV file with synthesizer")
     (?d "display" nil display "display phrase")
     (?m "modifiers" nil modifiers "display valid modifiers")
     (?e "edit" nil edit "edit phrase")
     (?f "format" nil format "display kphrase format")
     (?M "midi" nil midi "read MIDI file")
;     (?F "file" t file "write MIDI file")
;     (?k "keep" nil keep "do not set variable `kphrase'")
;     (?K "keep" nil keep "do not set any variable")
     :show-usage
     :usage "[options] [MUSICAL PHRASE | MIDIFILE]..."
     :post-usage
"Read/play/display/edit a musical phrase.
Do 'kphrase -f' for details about the input format.
Variable `kphrase' is always set as a side effect; note that variable
`rcanvas' will also be set when MUSICAL PHRASE defines a rhythmic canvas
along the musical phrase.
Alternatively, a MIDIFILE can be read; in that case variable `midifile'
is set as a side effect.")
   (let ((str (mapconcat 'identity (or args "") " ")))
     (unless midi
       (setq str (replace-regexp-in-string ":/" ":" str)))
     (when format
       (muo-doc "notes"))
     (with-squeak-child-namespace (readObject)
       (when args
	 (if midi
	     ($$ `[midifile <- MIDIFile named: 
			 ,(surmulot-eshell-file str surmulot-midi-directory)])
	   ($$ `[readObject <- Mode major printer
			    readMusicalPhrase: (ReadStream on: ,str)
			    context: 
			    (SurmulotManager bindings at: 'eshell) copy])
	   (if ($$ [readObject> isMetered])
	       ($$ [rcanvas <- readObject> rhythmicCanvas]
		   [kphrase <- readObject> asMusicalPhrase])
	     ($$ [kphrase <- readObject>]))))
       (when midi
	 ($$ [kphrase <- midifile> asMusicalPhrase]))
       (if modifiers
	   ($$ [MusicalPhrase modifiersList])
	 (when edit
	   ($$ [SurmulotManager emacsSend: kphrase> editorMorph]))
	 (when play ($$ [kphrase> play]))
	 (when wav ($$ [wav <- kphrase> asWAVFile]))
	 (when synth ($$ [synth> playPhrase: kphrase>]))
	 (when synth-wav ($$ [wav <- (synth> compileMusicalPhrase: kphrase>)]))
	 (when synth-name
	   ($$ `[,(intern (concat synth-name ">")) playPhrase: kphrase>]))
	 (line-concat-stringify
	  (when display ($$ `[,(if (and args (not midi))
				   'readObject> 'kphrase>) viewForEmacs]))
	  (unless hide ($$ [kphrase> printString allButFirstAndLast]))))))))

(add-to-list 'surmulot-eshell-commands 'kphrase)

(put 'eshell/kphrase 'eshell-no-numeric-conversions t)

;; mettre un -k au test !
;TEST (eshell-command-result "kphrase /fractal/ a,e,f") => "ad32,e,f,e,bo2,co3,f,c,c+"
; kphrase /fractal/ a,e,f > /dev/clip
; kphrase -dMx ${cadr ${sfs midi -l "Chopin\*"}}
; kphrase -d /fractal/ ${query "musical phrase:"}

;;; ===========================================================================
;;;              eshell/synth
;;; ===========================================================================


(defun eshell/synth (&rest str)
  (eshell-eval-using-options
   "synth" str
   '((?h "help" nil nil "show this usage screen")
     (?D "default" nil default "use current synthesizer as default")
     (?W "wav" nil wav "use current synthesizer as default for WAV")
     (?b "bind" t bind "bind current synthesizer")
     (?l "list" nil list "list all bound synthesizers")
     (?w "who" nil who "tells name of current synthesizer, if any")
     (?s "set" nil set "set current synthesizer")
     :show-usage
     :usage "[options] [default|wav|named|tpb|fmsound|csd] ..."
     :post-usage
"
Manage phrase and drums synthesizers.")
   (with-squeak-child-namespace (argSynth)
     (if (car args)
       (case (intern (car args))
	 ('tpb
	  (let ((ins (read (cadr args)))
		(bank (or (read (caddr args)) 0)))
	    ($$ `[argSynth <- (Timidity program: ,ins bank: ,bank)])))
	 ('named
	  ($$ `[argSynth <- ,(intern (concat (cadr args) ">"))]))
	 ('default
	   ($$ [argSynth <- MIDISynthesizerInteraction default]))
	 ('wav
	  ($$ [argSynth <- MIDISynthesizerInteraction toWAV]))
	 ((fmsound fm-sound)
	  (error "Not yet implemented")
	  )
	 ('buffer
	  ($$ `[argSynth <- SurmulotSynthesizer buffer: ,(cadr args)]))
	 ('csd
	  (let ((csd-file (surmulot-csd-directory (cadr args))))
	    ($$ `[argSynth <- CsoundSynthesizer csdFileNamed: ,csd-file])))
	 (midi-out
	  (error "Not yet implemented")
	  )
	 (t ;; see if an implicit 'named does the job

 (error "Invalid synthesizer specification")))
       ($$ [argSynth <- synth>]))
     (when set
       ($$ [synth <- argSynth>]))       
     (when bind
       ($$ `[,(intern bind) <- argSynth>]))
     (when default
       ($$ [MIDISynthesizerInteraction default: argSynth>]))
     (when wav
       ($$ [MIDISynthesizerInteraction defaultToWAV: argSynth>]))
     (if who
	 ($$ [(SurmulotManager bindings at: 'eshell) 
	      associations select: [:ea | (ea value == argSynth>)
					and: [(ea key == 'synth) not]]
	      thenCollect: [:ea |ea key]])
       (if list
	   ($$ [(((SurmulotManager bindings at: 'eshell) 
		  select: [:ea | ea isKindOf: MIDISynthesizerInteraction]) 
		 keys copyWithout: 'synth) sort]))))))


; synth tpb 20 30

 
(add-to-list 'surmulot-eshell-commands 'synth)

(put 'eshell/synth 'eshell-no-numeric-conversions t)

 

;;; ===========================================================================
;;;              eshell/nfunction
;;; ===========================================================================

(defun eshell/nfunction (&rest rest)
  (eshell-eval-using-options
   "nfunction" rest
   '((?h "help" nil nil "show this usage screen")
     (?p "parameters" nil show-parameters "list parameters")
     (?l "last" t last-operation "operate on last nfunction")
     (?x "x0" t x "set x offset for display")
     (?y "y0" t y "set y offset for display")
     (?w "width" t width "set x range for display")
     (?v "heigth" t heigth "set y range for display")
     (?d "display" nil display "display function")
     (?x "hide" nil hide "do not print function")
     (?e "edit" nil edit "edit function")
     :show-usage
     :usage "[options] FUNCTION..."
     :post-usage
"Display/convert a numerical function.
Always set variable `nfunction' as a side effect.")
     (let ((selector (when args (intern (car args))))
	   (modifiers (append nil
			      (if width `(xSpan: ,width asNumber \;))
			      (if heigth `(ySpan: ,heigth asNumber \;))
			      (if x `(x0: ,x asNumber \;))
			      (if y `(y0: ,y asNumber \;))))
	   (parameters-values
	    (let ((plist (cdr args)))
	      (loop for p in plist
		    for i from 0
		    if (evenp i)
		    append `(,@(unless (zerop i) '(\;))
			      parametrize: \# ,p
			      default: ,(read (nth (1+ i) plist)))
		    into values
		    finally return values))))
       (when (and last-operation
		  (not ($$ [lastNfunction == nfunction>])))
	 ($$ [lastNfunction <- nfunction>]))
       (when selector
	 (if (eq selector 'last)
	     ($$ `[nfunction <- nfunction> ,@parameters-values])
	   ($$ `[nfunction <- NFunction ,selector ,@parameters-values])))
       (when last-operation
	 (case (intern last-operation)
	   (comp ($$ [nfunction <- nfunction> o: lastNfunction>]))
	   (sub ($$ [nfunction <- nfunction> - lastNfunction>]))
	   (add ($$ [nfunction <- nfunction> + lastNfunction>]))
	   (mult ($$ [nfunction <- nfunction> * lastNfunction>]))))
       (when edit
	   ($$ [SurmulotManager emacsSend: nfunction> editor]))
       (line-concat-stringify
	(when display
	  ($$ `[nfunction> editor ,@modifiers imageFormForEmacs]))
	(unless hide ($$ [nfunction> printString]))
	(when show-parameters
	  ($$ [nfunction> parameters
			  collect: [:p | {p id \. p default}]]))))))

(add-to-list 'surmulot-eshell-commands 'nfunction)
 
(put 'eshell/nfunction 'eshell-no-numeric-conversions t)

; nfunction sineWithPoint point 0.3@-1 -w 16
; nfunction expBump decayRate 10 -y -0.1 radius 0.1 -x -0.1


;;; ===========================================================================
;;;              eshell/soundfont
;;; ===========================================================================

(defun eshell/soundfont (&rest str)
  (eshell-eval-using-options
   "soundfont" str
   '((?h "help" nil nil "show this usage screen")
     (?d "presets" nil presets "display presets")
     (?p "preset" t preset "set preset")
     (?b "bank" t bank "set bank")
     (?m "midifile" nil midi "play last midifile")
     (?k "kphrase" nil kphrase "play last kphrase")
     (?w "wav" nil wav "render to WAV, don't play")
     (?r "reverb" t reverb "set reverb (default 1)")
     (?c "chorus" t chorus "set chorus (default 1)")
     (?S "synth" nil synth "make it the current synthesizer")
     :show-usage
     :usage "[options] SOUNDFONT..."
     :post-usage
"Provides soundfont inspection utilities.
Always set variable `midifile' as a side effect.
May also set variable `synth' (see option -S)")
   (if (null args)
       "Missing SOUNDFONT argument."
   (let ((sf2 (surmulot-eshell-file 
	       (concat (file-name-sans-extension (car args)) ".sf2")
	       surmulot-soundfonts-directory))
	 (preset (or preset "0"))
	 (bank (or bank "0"))
	 musical-phrase)
     (unless (file-exists-p sf2) ;; rely on csound INC path
       (setq sf2 (file-name-nondirectory sf2)))

     (when synth
       (let ((csd-file (surmulot-csd-directory "microtonal soundfont.csd")))
	 ($$ `[synth <- (CsoundSynthesizer csdFileNamed: ,csd-file)
		     orchestraMacros: {
		       'SOUNDFONT -> ,(file-name-nondirectory sf2) \.
		       'BANK -> ,bank \.
		       'PRESET -> ,preset \. }])))
     (when midi 
       (setq musical-phrase 
	     ($$ [midifile> 
		  asMusicalPhrase keyPrintString allButFirstAndLast])))
     (when kphrase
       (setq musical-phrase ($$ [kphrase> keyPrintString allButFirstAndLast])))
     (when musical-phrase
       (if wav
	   ($$ `[wav <- WAVFile named: ,(surmulot-render-soundfont 
					 sf2 musical-phrase
					 :bank bank :preset preset
					 :chorus (or chorus 1)
					 :reverb (or reverb 1))])
	 (surmulot-play-soundfont sf2 musical-phrase
				  :bank bank :preset preset
				  :chorus (or chorus 1)
				  :reverb (or reverb 1))))
     (when presets
       (timcfg-soundfont-presets sf2))))))

(add-to-list 'surmulot-eshell-commands 'soundfont)

(put 'eshell/soundfont 'eshell-no-numeric-conversions t)

; soundfont CampbellsBass -k -p 3

(defun surmulot-eshell-test-1 ()
  (or (not (surmulot-spfa-p))
      (string= (eshell-command-result "for sf2 in ${ls ${sfs soundfonts -p}/*trumpet*.sf2} {echo $sf2 ; soundfont -d $sf2}")
	       "((\"Trumpet metallic\" 0 56))((\"Melodic Trumpet\" 0 0))((\"Soft Trumpet\" 0 0)\n (\"Hard Trumpet\" 0 1)\n (\"Fast Falls\" 0 2)\n (\"Trumpet Doiks\" 0 3)\n (\"Trumpet Shakes\" 0 4)\n (\"Trumpet Layer\" 0 5)\n (\"Soft Dark Tpt\" 0 6)\n (\"Hard Dark Tpt\" 0 7)\n (\"DarkTpt Layer\" 0 8)\n (\"Falls & Doiks\" 0 9))((\"Muted Trumpet\" 0 59))((\"Cup Mute      NC\" 0 0)\n (\"Straight Mute NC\" 0 1)\n (\"Harmon Mute   NC\" 0 2)\n (\"Wah-Growls    NC\" 0 3)\n (\"Cup/Strght Layer\" 0 4)\n (\"Cup/Harmon Layer\" 0 5)\n (\"Strght/HrmnLayer\" 0 6)\n (\"Cup Mute\" 0 7)\n (\"Straight Mute\" 0 8)\n (\"Harmon Mute\" 0 9)\n (\"Wah-Growls\" 0 10)\n (\"Cup Mute   NC/BV\" 0 11)\n (\"Strt Mute  NC/BV\" 0 12)\n (\"Hrmn Mute  NC/BV\" 0 13)\n (\"Wah-Growls NC/BV\" 0 14))")))	 

;TEST  (surmulot-eshell-test-1) => t


;;; ===========================================================================
;;;              eshell/wav
;;; ===========================================================================

(defun eshell/wav (&rest str)
  (eshell-eval-using-options
   "wav" str
   '((?h "help" nil nil "show this usage screen")
     (?e "edit" nil edit "edit WAV file")
     :show-usage
     :usage "[options] [WAV-FILE] ..."
     :post-usage
"Draft...")
   (when args
     ($$ `[wav <- WAVFile named:
	       ,(surmulot-eshell-file 
		 (concat (file-name-sans-extension (car args)) 
			 ".wav"))]))
   (if edit
       ($$ [wav> edit]))))

(add-to-list 'surmulot-eshell-commands 'wav)

(put 'eshell/wav 'eshell-no-numeric-conversions t)


;;; ===========================================================================
;;;              eshell/rcanvas
;;; ===========================================================================

(defun eshell/rcanvas (&rest str)
  (eshell-eval-using-options
   "rcanvas" str
   '((?h "help" nil nil "show this usage screen")
     (?d "display" nil display "display rhythmic canvas")
     (?x "hide" nil hide "do not print rhythmic canvas")
     (?f "format" nil format "display time signature format")
     (?a "append" nil append "append to current rcanvas")
     (?p "prepend" nil prepend "prepend to current rcanvas")
     (?e "edit" nil edit "edit canvas in muO")
     :show-usage
     :usage "[options] SIGNATURES ..."
     :post-usage
"Define a RhythmicCanvas.
Each SIGNATURE needs to be a string, enclosed in double quotes.
See rcanvas -f for valid time signature formats.
The variable `rcanvas' is always set as a side effect.")
   (if edit
       ($$ [SurmulotManager emacsSend: rcanvas> editorMorph])
     (if format (muo-doc "rhythmic")
       (unless (or append prepend) ;; or NO canvas> ?!
	 ($$ `[rcanvas <- \# ,(read (car args)) sig]))
       (if prepend
	   (dolist (sig args)
	     ($$ `[rcanvas <- (\# ,(read sig) sig) + rcanvas>]))
	 (dolist (sig (if append args (cdr args)))
	   ($$ `[rcanvas <- rcanvas> + (\# ,(read sig) sig)])))
       (line-concat-stringify
	(when display ($$ [rcanvas> viewForEmacs]))
	(unless hide ($$ [rcanvas> printString])))))))

(add-to-list 'surmulot-eshell-commands 'rcanvas)

(put 'eshell/rcanvas 'eshell-no-numeric-conversions t)

;; mettre un -k au test !
;TEST (eshell-command-result "rcanvas \"(3 ((2 3 -3) 8))\" \"(2 ((2 -3 3) 5))\"") => "RC[R(S0.0 t0.25 T0.5 t0.75 t1.0 v1.25 t1.5 t1.75)D2.0 R(S6.0 t6.4 v6.8 t7.2 t7.6 T8.0 t8.4 t8.8)D9.2 R(S12.4 t12.8 v13.2 t13.6 t14.0 T14.4 t14.8 t15.2)D15.6]"

;;; ===========================================================================

(provide 'surmulot-eshell)

;;; surmulot-eshell.el ends here








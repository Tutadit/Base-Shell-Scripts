;;; -*- auto-recompile: t -*-

;;; csound-fluid.el --- Csound fluid opcodes utilities

;; Keywords: csound

;; This file is not part of GNU Emacs.
;; 
;; csound-fluid.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; csound-fluid.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Author: Stéphane Rollandin <hepta@zogotounga.net>
;;---------

(require 'surmulot-csd)

;; ====================== examples
'(
 
  (defCSD one-soundfont (sf2 channel phrase)
    :SF2 (:soundfont sf2 :select-channels (list channel))
    :do (cscsd-read-phrase phrase))
  
  (csl-play-composition
   'one-soundfont "NylonGuitar1.sf2" 3 "/fractal/ ac3,e,f")

  (csl-play-composition
   (csound-composition
    :SF2 (:soundfont "NylonGuitar1.sf2" :select-channel 2)
    :do (cscsd-read-phrase "ac2,e,f")))

  (csl-render-edit-composition nil
   (csound-composition
    :SF2 (:soundfont "NylonGuitar1.sf2" :select-channel 2 :reverb 0 :chorus 0)
    :SF2 (:soundfont "psaltry.sf2" :select-channel 3 :reverb 0 :chorus 0)
    :do (cscsd-read-phrase "ac2,ec3,fc2,dc3")))

  (csl-play-composition 
   (csound-composition
    :SF2 (:soundfont "NylonGuitar1.sf2" :select-channel 2 :reverb 0 :chorus 0)
    :SF2 (:soundfont "ns_kit7free.sf2" :select-channel 10 :reverb 0 :chorus 0  :bank 128 :preset 0)
    :do (cscsd-read-phrase "ac2 p35c10v127,fc2v64 p40c10v127")))

     
)
;; =================================

(defstruct soundfont-instrument
  soundfont 
  (bank 0) 
  (preset 0)
  (reverb 1) 
  (chorus 1)
  (volume 70000)
  (pbrange 24)
  (dispatch-channels 16) 
  (select-channel nil)
  (select-channels '(1)))

(defun insert-soundfont-init-code (ins number)
  (insert
   (format 
    "\ngipbrange%s init %s\ngiengine%s fluidEngine %s, %s\ngisfnum%s fluidLoad \"%s\", giengine%s\n"
    number (soundfont-instrument-pbrange ins) number
    (soundfont-instrument-reverb ins) (soundfont-instrument-chorus ins)
    number (soundfont-instrument-soundfont ins) number))
  (dotimes (c (soundfont-instrument-dispatch-channels ins))
    (insert
     (format "fluidProgramSelect giengine%s, %s, gisfnum%s, %s, %s\n"
	     number (+ 1 c) number 
	     (soundfont-instrument-bank ins)
	     (soundfont-instrument-preset ins)))))

(defun insert-soundfont-instrument-code (ins number)
  (insert 
   (format "
instr FluidSynth%s
            ;; p4   base pitch (cps)
            ;; p5   velocity
            ;; p6   pitch bend envelope over p3 (in cents)
            ;; p7   MIDI channel
            ;; p8   expression envelope over p3 (range 0-1)
	    fluidControl  giengine%s, 176, p7, 100, 0
	    fluidControl  giengine%s, 176, p7, 101, 0
	    fluidControl  giengine%s, 176, p7, 6, gipbrange%s  
;	    fluidControl  giengine%s, 176, p7, 11, 127 
  imfloat   =  (17.31234049066757 * log(p4)) - 36.376316562296
  ikey      =  round(imfloat)
  ipbend    =  (imfloat - ikey) * 100
  ivel      init      p5
  kpbend    =  0
if p8=0 goto noVolumeEnvelope ; expression curve (MIDI controller 11)
  kndxa	    line      0, p3, 1
  kamp	    table     kndxa, p8, 1
	    fluidControl  giengine%s, 176, p7, 11, 127*kamp 
noVolumeEnvelope:
if p6=0 goto noPBEnvelope ; pitch-bend curve
  kndx      line      0, p3, 1
  kpbend    table     kndx, p6, 1 
noPBEnvelope:
  kfullbend =  round(8192 * (1 + 0.01 * (ipbend + kpbend) / gipbrange%s))
  kdata1    =  kfullbend & 127
  kdata2    =  kfullbend >> 7
	    fluidControl  giengine%s, 224, p7, kdata1, kdata2  
            fluidNote   giengine%s, p7, ikey, ivel
endin
" number number number number number number number number number number)))

(defun soundfont-instrument-format (ins)
  `(,(if (soundfont-instrument-select-channel ins)
	 (list 'selectChannel: (soundfont-instrument-select-channel ins))
       (list 'selectChannels: (soundfont-instrument-select-channels ins)))
    (dispatchField: 7)
    (dispatchGap: 0.1)
    (pitchField: 4)
    (pitchFormat: cps)
    (pitchInflexionField: 6)
    (ampModulationField: 8)
    (ampField: 5)
    (ampMin:max: (0 127))
    (iTemplate: "i 1 0 0.5 440 80 0 0 0")))

(defun insert-soundfont-instrument-format (ins number)
  (cscsd-insert-itemplate
   (format "FluidSynth%s" number)
   (soundfont-instrument-format ins)))

(defun insert-soundfont-instruments-output (soundfont-instruments)
  (insert "
instr FluidOutput
/*|effect i \"FluidOutput\" 0 1|*/
")
  (let ((ol "") (or ""))
    (loop for ins in soundfont-instruments
	  for n upfrom 1
	  do (insert
	      (format "imvol%s init %s\n" n
		      (soundfont-instrument-volume ins))
	      (format "asigl%s, asigr%s fluidOut giengine%s\n" n n n))
	  do (setq ol (concat ol (format "+ asigl%s * imvol%s " n n)))
	  do (setq or (concat or (format "+ asigr%s * imvol%s " n n))))
    (insert (format "outs%s,%s\n"
		    (substring ol 1)
		    (substring or 1))))
  (insert "endin\n"))

;;; ===========================================================================
;;;              Surmulot soundfont utilities
;;; ===========================================================================

(defun* surmulot-play-soundfont (soundfont phrase 
					   &key ((:bank bank) 0)
					   &key ((:preset preset) 0)
					   &key ((:vol volume) 70000)
					   &key ((:reverb reverb) 1)
					   &key ((:chorus chorus) 1))
  (csl-play-composition
   (csound-composition
    :SF2 (:soundfont soundfont 
	  :bank bank
	  :preset preset
          :select-channels '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16)
	  :reverb reverb
	  :chorus chorus
	  :volume volume)
    :do (cscsd-read-phrase phrase))))

(defun* surmulot-render-soundfont (soundfont phrase 
					   &key ((:bank bank) 0)
					   &key ((:preset preset) 0)
					   &key ((:vol volume) 70000)
					   &key ((:reverb reverb) 1)
					   &key ((:chorus chorus) 1))
  (csl-render-composition nil
   (csound-composition
    :SF2 (:soundfont soundfont
	  :bank bank
	  :preset preset
          :select-channels '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16)
	  :reverb reverb
	  :chorus chorus
	  :volume volume)
    :do (cscsd-read-phrase phrase))))

;(surmulot-play-soundfont "NylonGuitar1.sf2" "/r4/ bd50,d,g" :reverb 0)

;;; ===========================================================================
;;;              Timidity configuration interface
;;; ===========================================================================

;; highly experimental, temp. functions & names

(defun soundfont-spec (channel bank program &optional reverb chorus volume)
  (let ((patch (timcfg-find-patch :bank bank :prog program)))
    `(:SF2 (:soundfont ,(file-name-nondirectory (plist-get patch :sf2))
           :bank ,(plist-get patch :sf2bank)
	   :preset ,(plist-get patch :sf2preset)
	   :select-channels ',(if (listp channel) channel (list channel))
	   :reverb ,(or reverb 1)
	   :chorus ,(or chorus 1)
	   :volume ,(or volume 70000)))))

;TEST (soundfont-spec 3 60 10 0) => '(:SF2 (:soundfont "bottleblow.sf2" :bank 0 :preset 0 :select-channels (quote (3)) :reverb 0 :chorus 1 :volume 70000))

(defun soundfont-patch (&rest args)
  (eval `(csound-composition
	  ,@(apply 'soundfont-spec args))))

; (csl-edit-composition (soundfont-patch 1 60 10 0))
    
; (with-temp-file (cscsd-make-temp-file "tmp" nil ".csd") (funcall (soundfont-patch 1 60 10 0)))

(defun soundfont-drums-spec (channel drumset &optional reverb chorus volume)
  `(:SF2 (:soundfont ,(drumset-sf2 drumset)
           :bank 128
	   :preset 0
	   :select-channels ',(if (listp channel) channel (list channel))
	   :reverb ,(or reverb 1)
	   :chorus ,(or chorus 1)
	   :volume ,(or volume 70000))))

(defun soundfont-patches (args &optional drumset)
   (eval `(csound-composition
	  ,@(loop for spec in args
		  append (apply 'soundfont-spec spec) into all
		  finally return all)
	  ,@(when drumset (apply 'soundfont-drums-spec drumset)))))

;(csl-edit-composition (soundfont-patches '((1 60 10 0) (2 50 1 0 1)) '(10 78)))

;; temp
(defun csl-write-composition (composition &rest parameters)
  (let ((tempfile (cscsd-make-temp-file "tmp" nil ".csd")))
    (with-temp-file tempfile
      (apply composition parameters))
    tempfile))
      

(defun csl-register-composition-as-synthesizer 
  (address label composition &rest parameters)
  "Register COMPOSITION at ADDRESS in the CsoundSynthesizer library.
COMPOSITION is either a lambda form returned by `csound-composition' or a
symbol fbound via `defCSD', in which case it possibly accepts PARAMETERS.
ADDRESS is a string defining the access path of the new synth, such as
\"my-synths/specials/example soundfont-based synth\"."
  (with-temp-buffer
    (apply composition parameters)
    (muo-register-csd-as-synthesizer address label)))
    
; (csl-register-composition-as-synthesizer "test/bottleblow" "bottle blow" (soundfont-patch 1 60 10 0))

;;; used by MIDI>>#asCsoundSynthesizer in muO
(defun soundfont-drumset (&rest args)
  (eval `(csound-composition
	  ,@(apply 'soundfont-drums-spec args))))

; (csl-edit-composition (soundfont-drumset 10 78))


;======================== to be refactored

;(sf2-play "uninstalled/StratMarshall.SF2" "/fractal/ a&^,e!\",b,c&.")
;(sf2-play "uninstalled/5773_marocfiddle.sf2" "/fractal/ a&&&^,e!\",f,c&.")

;(sf2-play "uninstalled/RuckusAcousticDrums.sf2" "/r5/ +(eSnare)c1v127")

(defun sf2-play (sf2 phrase)
  (let ((preset (car (soundfont-presets sf2))))
    (surmulot-play-soundfont sf2 phrase 
			     :bank (cadr preset) :preset (caddr preset))))

(defun soundfont-presets (soundfont)
  (let ((tmpfile (cscsd-make-temp-file "tmp" nil ".csd")))
    (with-temp-file tmpfile
      (insert (format 
"<CsoundSynthesizer>
<CsInstruments>
sr = 44100
ksmps = 100
giengine  fluidEngine
isfnum    fluidLoad \"%s\", giengine, 1
instr dummy
endin
</CsInstruments>
<CsScore>
e
</CsScore>
</CsoundSynthesizer>" soundfont)))
    (unwind-protect
	(with-temp-buffer
	  (insert (cscsd-call-csound-to-string "$csound -d %s" tmpfile))
	  (goto-char (point-min))
	  (loop 
	   while (re-search-forward 
		  "^SoundFont:.*?Bank:\\(.*?\\)Preset: +\\([^ ]+\\) +\\(.*?\\) *$" 
		  nil t)
	   collect (list (match-string 3) 
			 (read (match-string 1)) 
			 (read (match-string 2))) into presets
	   finally return presets))
      (delete-file tmpfile))))

;TEST (soundfont-presets "Doumbek-Faisal.sf2") => '(("Doumbek1" 0 0) ("Doumbek2" 128 0))

;; === not used yet: downloading soundfonts


(defun surmulot-load-soundfont (file-name)
  (url-copy-file 
   (expand-file-name file-name "http://www.zogotounga.net/surmulot/sf2/")
   (expand-file-name (concat "soundfonts/" file-name) (surmulot-directory))))


;; === this is it.
(provide 'csound-fluid)

;; csound-fluid.el ends here


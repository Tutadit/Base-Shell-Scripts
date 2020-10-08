;;; -*- auto-recompile: t -*-

;; This file is not part of GNU Emacs.
;; 
;; surmulot-python.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; surmulot-python.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;-------------
;;             Python/Pymacs integration with Surmulot

;; last modified September 25, 2011
;;; --------------------------------------------------------------------------

;; adding Surmulot directory to PYTHONPATH

(defcustom surmulot-python-path-append nil
  "When non-nil, the Surmulot python directory is appended to environment
variable PYTHONPATH.
When nil, it is prepended instead \(giving it priority)"
  :type 'boolean
  :group 'spfa-paths)

(setenv
 "PYTHONPATH" 
 (if surmulot-python-path-append
     (concat  (getenv "PYTHONPATH") path-separator
	      (substitute-in-file-name "$SURMULOTDIR/python"))
   (concat (substitute-in-file-name "$SURMULOTDIR/python")
	   path-separator (getenv "PYTHONPATH"))))


;; Pymacs support

(autoload 'pymacs-apply "pymacs")
(autoload 'pymacs-call "pymacs")
(autoload 'pymacs-eval "pymacs" nil t)
(autoload 'pymacs-exec "pymacs" nil t)
(autoload 'pymacs-load "pymacs" nil t)

(defcustom surmulot-pymacs-python (condition-case nil
				     (progn
				       (require 'python-mode)
				       python-command)
				    (error "python.exe"))
  "Python executable to be used by Pymacs."
  :type 'string
  :group 'surmulot-paths)

(defun surmulot-pymacs-python ()
  (substitute-in-file-name surmulot-pymacs-python))

(unless (getenv "PYMACS_PYTHON")
  (setenv "PYMACS_PYTHON" (surmulot-pymacs-python)))

;; music21 support (draft)

(defun surmulot-athenaCL (&rest commands)
  (require 'python-mode)
  (save-window-excursion
    (run-python)
    (rename-buffer " *athenaCL (Python)*" t)
    (add-to-list 'comint-output-filter-functions
		 'surmulot-athenaCL-output-filter)
    (comint-send-string (get-buffer-process (current-buffer))
			"import athenaCL.athenacl\nn\n")
    (dolist (command commands)
      (comint-send-string (get-buffer-process (current-buffer))
			  (concat command "\n")))
    (comint-send-eof)))

(defun surmulot-music21 (&rest commands)
  (require 'python-mode)
  (save-window-excursion
    (run-python)
    (rename-buffer " *music21 (Python)*" t)
    (add-to-list 'comint-output-filter-functions
		 'surmulot-music21-output-filter)
    (comint-send-string (get-buffer-process (current-buffer))
			"from music21 import *\n")
    (dolist (command commands)
      (comint-send-string (get-buffer-process (current-buffer))
			  (concat command "\n")))
(comint-send-eof)
;    (comint-send-string (get-buffer-process (current-buffer))
;			"quit()\n")
 ;   (setq comint-output-filter-functions nil)
 
  ;  (let (kill-buffer-query-functions)
 ;    (kill-buffer))
))





(defun surmulot-load-music21 ()
  "experimental"
  (interactive)
  (pymacs-exec "from music21 import *"))

; (surmulot-load-music21)

; (setq Bach (pymacs-eval "corpus.parse('bach/bwv7.7')"))
; (pymacs-call "len" Bach)

;(pymacs-exec "sBach = corpus.parse('bach/bwv7.7')")
;(pymacs-eval "len(sBach)")
;(pymacs-eval "[part.id for part in sBach.parts]")


;(pymacs-exec "midif = converter.parse('d:/devel/surmulot/midi/Haydn/hay_cel_hobviib_1_2.mid')")
;(pymacs-eval "len(midif)")
;(pymacs-eval "[part.id for part in midif.parts]")
;(pymacs-eval "midiff = midif.midiFile")
;((pymacs-eval "midiff.open('d:/devel/surmulot/midi/testMusic21.mid','wb')")
;(pymacs-eval "midif.midiFile.write()")
;(pymacs-eval "midif.midiFile")

;(pymacs-load "music21" "music21::")
;(pymacs-load "music21.common" "music21::")
;(pymacs-load "music21.note" "music21::")
;(setq B1 (music21::parse "d:/devel/surmulot/midi/Haydn/hay_cel_hobviib_1_2.mid"))
;(pymacs-call "len" B1)

;(pymacs-load "__builtin__" "py::")
;(py::len B1)

;(py::len (music21-parse "d:/devel/surmulot/midi/Haydn/hay_cel_hobviib_1_2.mid"))



;(pymacs-load "music21.midi.base" "music21-midi::")
;(pymacs-load "music21.midi.translate" "music21-midi::")
; (py::type (music21-midi-MidiFile))
;(py::type 5)

;(music21::spaceCamelCase "opus23402no219235")
;(music21::decimalToTuplet 1.5)
;(music21::fromRoman "viii")


;(pymacs-load "mingus.core.intervals" "mingus-intervals-")
;(mingus-intervals-determine "Gbb" "Ab")

;(pymacs-load "mingus.containers" "mingus-nc-")
;(pymacs-load "mingus.containers.NoteContainer" "mingus-nc-")
;(py-len (mingus-nc-NoteContainer '("A-3" "C-5" "E-5")))

;;; --------------------------- End  -----------------------------

(provide 'surmulot-python)

;;; surmulot-python.el ends here








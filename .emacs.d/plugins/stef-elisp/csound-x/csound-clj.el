;;; -*- auto-recompile: t -*-

;;; csound-clj.el --- csound API with Clojure

;; Keywords: csound

;; This file is not part of GNU Emacs.
;; 
;; csound-clj.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; csound-clj.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Author: Stéphane Rollandin <hepta@zogotounga.net>
;;---------

(require 'clojure-mode)

(require 'nrepl)
(defalias 'cider-jack-in 'nrepl-jack-in)
;(require 'cider) ;; does not work. "No nREPL connection"
(defun cider--library-version ()
  "Get the version in the nrepl library header."
  ;; (-when-let (version (pkg-info-library-version 'cider))
  ;;   (pkg-info-format-version version))
  "0.7.0-SNAPSHOT")

(defun csound-clj-hide-eol ()
 "Do not show ^M in files containing mixed UNIX and DOS line endings."
 (interactive)
 (setq buffer-display-table (make-display-table))
 (aset buffer-display-table ?\^M []))

(when (eq system-type 'windows-nt)
  (add-hook 'nrepl-mode-hook 'csound-clj-hide-eol ))

(defvar clojure-home (surmulot-directory "clojure")) 

(defvar clojure-connected-p nil)

(defvar clojure-leiningen-standalone 
  (expand-file-name "leiningen-2.3.4-standalone.jar"
		    (surmulot-directory "lein"))
  "Leiningen standalone jar file")

(defvar clojure-environment-defined-p nil)
(defun surmulot-setup-clojure-environment ()
  (unless clojure-environment-defined-p
    (setenv "PATH" (concat (surmulot-directory "lein") ";" (getenv "PATH")))
    ;; (setenv "CLASSPATH"
    ;; 	    (concat (mapconcat 'identity
    ;; 			       (csclj-surmulot-jars) ";")
    ;; 		    ";" (getenv "CLASSPATH")))

    (setenv "_JAVA_OPTIONS" ;; redefine user.home
	    (concat "-Duser.home=" 
		    (cscsd-safe-file-name (surmulot-directory))))

    (setenv "CLASSPATH" 
	    (concat (concat (cscsd-safe-file-name clojure-leiningen-standalone))
		    ";" (getenv "CLASSPATH")))

    (setenv "LEIN_JAR" (cscsd-safe-file-name clojure-leiningen-standalone))
    (unless (eq system-type 'gnu/linux)
      (setenv "PATH" 
	      (concat (cscsd-safe-file-name (csclj-csound-path)) ";" 
		      (getenv "PATH"))))
    (setq clojure-environment-defined-p t)))

(add-hook 'nrepl-connected-hook 'surmulot-clojure-load-init-file)
(add-hook 'nrepl-connected-hook 'surmulot-clojure-note-connected)
(add-hook 'nrepl-disconnected-hook 'surmulot-clojure-note-disconnected)

(defun surmulot-clojure-note-connected ()
  (setq clojure-connected-p t))

(defun surmulot-clojure-note-disconnected ()
  (setq clojure-connected-p nil))

(add-to-list 'special-display-buffer-names "*nrepl*")

(defun surmulot-start-clojure (&optional form)
  (interactive)
  (unless clojure-connected-p
    (when form
      (add-hook 'nrepl-connected-hook 
		`(lambda ()
		   (surmulot-clojure-eval ',form t)
		   (setq nrepl-connected-hook (butlast nrepl-connected-hook 1)))
		t))
    (with-temp-buffer
      (surmulot-setup-clojure-environment)
      (cider-jack-in))))

(defun surmulot-clojure-load-init-file ()
 (when (string= (second (nrepl-send-string-sync 
			 "(find-var 'user/surmulot-clj-loaded)"))
		"nil")
  (surmulot-clojure-eval 
   `(do
	(load-file ,csclj-init-file)
	(user/add-surmulot-jars)))))

(defun surmulot-clojure-eval (form &optional no-test)
  (if clojure-connected-p
      (nrepl-send-string-sync (prin1-to-string form))
    (unless no-test
      (surmulot-start-clojure form))))

(defun surmulot-slider-demo ()
  (interactive)
  (surmulot-clojure-eval 
   '(do
	(load-file (surmulot-file ["clojure" "SliderDemo.clj"]))
	(def gui (slider-demo)))))


; 2)
;(surmulot-clojure-eval2 '(load-file (surmulot-file ["clojure" "draft.clj"])))

; (surmulot-clojure-eval2 '(csound-play (surmulot-file ["csound" "library" "examples" "Study for Computer (John Endicott).csd"])))

;(surmulot-clojure-eval2 '(emacs-do "(new-frame)"))

;; NOTE:
;; there is a CLASSPATH=%CLASSPATH% in lein.bat  Needed !



;; ------- settings to be improved 

(defun csclj-csound-path ()
  (if (eq system-type 'gnu/linux) 
      "/usr/share/java/" ;; ???
    (file-name-directory (cscsd-csound-binary))))

;; Unused: currently broken for linux
(defun csclj-csnd-jar ()
 (if (eq system-type 'gnu/linux) 
      "/usr/share/java/csnd-5.08.0.jar"  ;;; make this dynamic or customizable
   (expand-file-name "csnd.jar" (csclj-csound-path))))

;; (defvar csclj-csnd-library-path 
;;   (if (eq system-type 'gnu/linux) 
;;       "/usr/lib/jni/")) ;"/usr/lib/jni/lib_jcsound.so"))

(defun csclj-surmulot-jars ()
  (list
   clojure-leiningen-standalone
   ;; (expand-file-name "clojure-1.6.0.jar" clojure-home)
   (expand-file-name "csnd.jar" (csclj-csound-path))
   (expand-file-name "csnd6.jar" (csclj-csound-path))

 ;  (surmulot-directory "lein/Cadejo/")

   (surmulot-directory "jmusic/jmusic1.6.4.jar")
   (surmulot-directory "jfugue/jfugue.jar")))

;; --------


(defvar csclj-init-file 
  (surmulot-directory "clojure/surmulot.clj"))

;;; --------------------------- experimental  -----------------------------


;(surmulot-clojure-eval '(load-file "draft.clj"))
; (csound-play "../csound/library/examples/study.csd")
; (csound-play "d:/devel/surmulot/csound/library/examples/study.csd")

;(surmulot-clojure-eval '(emacs-do "(new-frame)"))
;(surmulot-clojure-eval `(emacs-do ,(prin1-to-string '(new-frame))))



;; test: repl in a specific project (Overtone)

(defun surmulot-overtone ()
  (interactive)
  (with-temp-buffer
    (require 'csound-clj)
    (cd "d:/devel/surmulot/lein/leintest")
    (surmulot-start-clojure '(start-overtone))))

;; test muO code (once Overtone is up):
;; SurmulotManager askClojureFor: ('(user/trem %s)' sformat: Mode E5 root)
;; test Clojure code (from Overtone REPL):
;; (trem (read-string (squeak-eval "Mode E4 root")))


(defun surmulot-cadejo ()
  (interactive)
  (with-temp-buffer
    (require 'csound-clj)
    (cd "d:/devel/surmulot/lein/Cadejo")
    (surmulot-start-clojure)))

;; ================== this is it.
(provide 'csound-clj)

;; csound-clj.el ends here

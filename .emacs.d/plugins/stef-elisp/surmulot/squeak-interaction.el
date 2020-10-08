;;; -*- auto-recompile: t -*-

;; This file is not part of GNU Emacs.
;; 
;; squeak-interaction.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; squeak-interaction.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:
;;-------------
;;             interacting with Squeak via TCP/IP

;; last modified March 18, 2011
;; for Emacs 23.2
;;; ---------------------------------------------------------------------------

(defun squeak-connected-somehow-p ()
  (or (squeak-tcpip-process)
      (squeak-connected-via-surman-p)))

(defun squeak-connected-via-surman-p ()
  (and (featurep 'surman)
       (surman-squeak-connected-p)))

(defun squeak-eval (string &optional port)
  "Have Squeak evaluate STRING as smalltalk code and return the result.
Optionally use PORT to communicate with a specific widget."
  (if (and (null port)
	   (squeak-connected-via-surman-p))
    (surman-ask-squeak string)
    (squeak-eval-with-return string port)))


;;; ===========================================================================
;;;                          Smalltalk as Lisp
;;; ===========================================================================

(defun print-smalltalk-to-string (smalltalk-code)
  "Convert list SMALLTALK-CODE into a string of proper Smalltalk code."
  (let (diese)
    (loop for token in smalltalk-code
	  collect 
	  (case (type-of token)
	    ('cons 
	     (if (and (eq (car token) 'quote)
		      (or (symbolp (cadr token))
			  (stringp (cadr token))))
		 (format "#'%s'" (cadr token)) ;; symbols
	       (format "(%s)"
		       (print-smalltalk-to-string token)))) ;; nesting
	    ('vector (format "[%s]" 
			     (print-smalltalk-to-string
			      (append token nil)))) ;; blocks
	    ('string 
	     (format "'%s'";; strings
		     (replace-regexp-in-string
		      "'" "''" 
		      (encode-coding-string token 'compound-text-mac)))) 
	    ('symbol
	     (if (eq token 'nil)
		 (if diese "_Empty_Array_" ;; #()
		   "nil") ;; nil
	       (let ((tns (symbol-name token)))
		 (setq diese (string= tns "#"))
		 (if (string-match "^\\(.*[^-]\\)>$" tns) ;; variable reading
		     (format "(SurmulotManager bindings under:#'%s')"
			     (match-string 1 tns))
		   tns)))) ;; word (class name, selector)
	    (otherwise (prin1-to-string token))) ;; direct transcription  
	  into form
	  finally return (replace-regexp-in-string
			  "# _Empty_Array_" "(Array new)"
			  (mapconcat 'identity form " ")))))

(defvar squeak-errors-regexp
  "^\\(MessageNotUnderstood\\|ZeroDivide\\|Key not found\\|SyntaxErrorNotification\\|Error\\|FileDoesNotExistException\\):")

(defvar squeak-auto-connection-attempts 30)

(defun squeak-eval-smalltalk (smalltalk-code &optional no-retry)
  (declare (indent 0))
  (let* ((sfe-code (print-smalltalk-to-string 
		    `(,smalltalk-code printStringForEmacs)))
	 (val nil)
	 (str-value ""))
    (condition-case some-error
	(setq str-value (surman-ask-squeak sfe-code))
      (error
       (if (or no-retry
	       (squeak-connected-via-surman-p))
	   (error (cadr some-error))
	 (squeak-start)
	 (loop for i from 1 to squeak-auto-connection-attempts
	       until (squeak-connected-via-surman-p) 
	       do (sleep-for 0.1))
	 (setq val (squeak-eval-smalltalk smalltalk-code t)))))
    (if val
	val
      (setq val (substring str-value 1 -1))
      (if (string-match squeak-errors-regexp str-value)
	  (error str-value)
	(condition-case nil
	    (read val)
	  (error val))))))

(defmacro $<- (var &rest expression)
  "Bind symbol VAR to Smalltalk EXPRESSION within the current
`squeak-namespace'"
  `($: SurmulotManager bindings under: ',var put: ,expression))

(defmacro $: (&rest body)
  "Have BODY evaluated by Squeak as Smalltalk code"
  `(squeak-eval-smalltalk ',body))

(defun $$ (&rest vectors)
  "Have VECTORS contents sequentially evaluated by Squeak as Smalltalk code.
The `$<-' operator can be used in a vector with format [var <- ...] "
  (loop for vector in vectors
	with val = nil 
	if (and
	    (> (length vector) 2)
	    (eq (elt vector 1) '<-))
	do (setq val (let ((vl (append vector nil)))
		       (eval `($: SurmulotManager bindings under: \# ,(car vl) 
				  put: ,(cddr vl)))))
	else do (setq val (squeak-eval-smalltalk (append vector nil)))
	finally return val))
 
;TEST ($: 3 > 2)  => t
;TEST ($$ [3 > 2]) => t
;TEST ($$ `[1 + ,(* 2 2)]) => 5
;TEST ($$ ["yo"] `[1 + ,(* 2 2)]) => 5
;TEST ($$ [n <- 10] `[m <- (n> * ,(+ 1 1))] [m> * 4]) => 80

;TEST ($: \#(1 2 3)) => [1 2 3]
;TEST ($: \#()) => []

;TEST ($$ [Morph new position: 5@6 \; center]) => "#<30@26>"
;TEST ($$ [{1 \. 2 \. 3} second]) => 2
;TEST ($$ [\#(1 2 3)]) => [1 2 3]
;TEST ($$ [{6}]) => [6]
;TEST ($$ [{6 \. (3 + 4)}]) => [6 7]
;TEST ($$ [\#(1 3) with: \#(-1 -3) collect: [:i :j | i + j]]) => [0 0]
;TEST (print-smalltalk-to-string '("bouh")) => "'bouh'"
;TEST (print-smalltalk-to-string '("'a' knote")) => "'''a'' knote'"
;TEST ($$ [\#beuh]) => 'beuh
;TEST ($$ ['beuh]) => 'beuh
;TEST ($$ [\#beuh asString]) => "beuh"
;TEST ($$ [1 = 1]) => t
;TEST ($$ [1 = 2]) => nil
;TEST ($$ [true]) => t
;TEST ($$ [false]) => nil
;TEST ($$ [[:t | t + 1] value: 7]) => 8
;TEST (funcall (lambda (x) ($$ `[,x > 0 ifTrue: [,x negated]])) 5) => -5
;TEST ($$ ["beuh" \, "gah"]) => "beuhgah"
;TEST ($$ ["beuh" parse: [yo]]) => '(error "MessageNotUnderstood: ByteString>>parse:")
;TEST ($$ [1 / 0]) => '(error "ZeroDivide: ")
;TEST ($$ [{2->3 \. (2+4)}]) => "[#<2->3> 6]"
;TEST (squeak-eval "{2->3 . (3+3)}") => "{2->3 . 6}"

;TEST ($<- Gloup 56 / 2) => 28
;TEST ($: 1 + Gloup>) => 29
;TEST ($: Gloup> class) => "#<SmallInteger>"
;TEST ($: Glap>) => '(error "Key not found: Glap")

(defvar smalltalk-operators 
 '($: progn$ let$ $$)
  "A list of macros or functions names operating on Smalltalk code")

(defmacro progn$ (&rest statements)
  "Evaluate STATEMENTS sequentially, return the last value.
STATEMENTS are lists beginning with a symbol registered in variable 
`smalltalk-operators'. 
Any list in STATEMENTS that do not begin with such a symbol will have the `$:'
operator automatically prepended.
As syntactic sugar, the `<-' operator is allowed to appear in second position
and stands there for a `$<-' macro call."
  (append '(progn)
	  (mapcar (lambda (s) 
		    (if (eq (cadr s) '<-)
			(append (list '$<- (car s)) (cddr s))
		      (if (memq (car s) smalltalk-operators)
			  s
			(append '($:) s))))
		  statements)))

(defmacro with-squeak-child-namespace (variables &rest statements)
  "Define VARIABLES local to a new namespace, child of the current one,
then evaluate STATEMENTS via `progn'"
  (declare (indent 1))
  (let ((bound-vars (remove-if 'symbolp variables))
	(unbound-vars (remove-if 'consp variables)))
  `(let* ((namespace ($: SurmulotManager bindings
			initializeNamespaceWith:
			\# ,(append unbound-vars (mapcar 'car bound-vars))))
	  (squeak-namespace (append squeak-namespace (list namespace)))
	  (let$-val (progn
		      ,@(mapcar
			 (lambda (bv)
			   (append '($$) (list (apply 'vector bv))))
			 bound-vars)
		      ,@statements)))
     ($$ `[SurmulotManager bindings removeNamespace: ,namespace])
     let$-val)))

(defmacro let$ (variables &rest statements)
  "Define VARIABLES local to a new namespace, child of the current one,
then evaluate STATEMENTS via `progn$'"
  (declare (indent 1))
  (let ((bound-vars (remove-if 'symbolp variables))
	(unbound-vars (remove-if 'consp variables)))
  `(let* ((namespace ($: SurmulotManager bindings
			initializeNamespaceWith:
			\# ,(append unbound-vars (mapcar 'car bound-vars))))
	  (squeak-namespace (append squeak-namespace (list namespace)))
	  (let$-val (progn$ ,@bound-vars ,@statements)))
     ($$ `[SurmulotManager bindings removeNamespace: ,namespace])
     let$-val)))

;TEST (progn$ (n <- 18) (n> * 2)) => 36
;TEST (progn$ (n <- 18) (let$ (n) (n <- 3)) (n> * 2)) => 36
;TEST (progn$ (n <- 18) (let$ (n) (n <- 3) (n> * 2))) => 6
;TEST (progn$ (n <- 18) (let$ (n) (n <- 3) (p <- (n> * 2))) (n> *2 + p>)) => 42
;TEST (let$ ((n <- 10) (p <- 18)) (n> + p>)) => 28

(defun test-progn$-1 ()
  (progn$
   (n <- 18)
   (let$ (n)
     ($$ [n <- 3]
	 `[p <- (n> * ,(+ 1 1))]))
   (n> * 2 + p>)))

;TEST (test-progn$-1) => 42

(defun test-progn$-2 ()
  (progn$
   (n <- 18)
   (let$ (n)
     (n <- 3)
     ($$ `[p <- (n> * ,(+ 1 1))]))
   (n> * 2 + p>)))

;TEST (test-progn$-2) => 42

(defun test-progn$-3 ()
  (progn$
   (n <- 18)
   (let$ ((n <- 3)) 
     ($$ `[p <- (n> * ,(+ 1 1))]))
   (n> * 2 + p>)))

;TEST (test-progn$-3) => 42


;;; --------------------------- End  -----------------------------

(provide 'squeak-interaction)

;;; squeak-interaction.el ends here








;;; csound-mode.el --- A major mode for interacting and coding Csound
;;  Copyright (C) 2017  Hlöðver Sigurðsson

;; Author: Hlöðver Sigurðsson <hlolli@gmail.com>
;; Version: 0.2.0
;; Package-Requires: ((emacs "25") (shut-up "0.3.2") (multi "2.0.1"))
;; URL: https://github.com/hlolli/csound-mode

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;  This file stores mode-specific bindings to `csound-mode`,
;;  "offline" csound-interactions and major-mode definition,
;;  syntax table.

;;; Code:


(require 'font-lock)
(require 'cl)
(require 'csound-eldoc)
(require 'csound-font-lock)
(require 'csound-repl)
(require 'csound-indentation)
(require 'csound-score)
(require 'csound-skeleton)
(require 'csound-util)
(require 'shut-up)


(defgroup csound-mode nil
  "Tiny functionality enhancements for evaluating sexps."
  :prefix "csound-mode-"
  :group 'csound-mode)

(defvar csound-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?_ "w" st)
    ;; (modify-syntax-entry ?+ "w" st)
    ;; (modify-syntax-entry ?- "w" st)
    (modify-syntax-entry ?. "w" st)
    (modify-syntax-entry ?! "w" st)
    (modify-syntax-entry ?% "-" st)    
    (modify-syntax-entry ?\" "\"\"" st)
    ;; (modify-syntax-entry ?| "\"" st) 
    (modify-syntax-entry ?\\ "\\" st)
    ;; Comment syntax
    ;; good read: https://www.lunaryorn.com/posts/syntactic-fontification-in-emacs.html
    (modify-syntax-entry ?\/ ". 124b" st)
    (modify-syntax-entry ?* ". 23b" st)
    (modify-syntax-entry ?\; "<" st
    			 )
    (modify-syntax-entry ?\n ">" st
    			 )
    st)
  "Syntax table for csound-mode")

(defun csound-play ()
  "Play the csound file in current buffer."
  (interactive)
  (compile (format "csound -odac %s" (buffer-file-name))))

(defun csound-render (bit filename)
  "Render csound to file."
  (interactive
   (list
    (read-string "File bit-value(16/24/32), defaults to 16: ")
    (read-string (format "Filename, defaults to %s.wav: " (file-name-base)))))
  ;;(compile (format "csound -o %s" (buffer-file-name)))
  ;; (message "var1: %s var2: %s" var1 var2)
  (let ((filename (if (string= "" filename)
		      (concat (file-name-base) ".wav")
		    filename)))
    (compile (format "csound %s -o %s --format=%s %s"
		     (buffer-file-name)
		     filename 
		     (-> (split-string filename "\\.")
			 rest first)
		     (case bit
		       ("32" "-f")
		       ("24" "-3")
		       (t "-s"))))))


(defun csound-repl-start ()
  "Start the csound-repl."
  (interactive)
  (if (executable-find "csound")
      (csound-repl--buffer-create)
    (error "Csound is not installed on your computer")))

(defvar csound-mode-map nil)

(setq csound-mode-map
      (let ((map (make-sparse-keymap)))
	;; Offline keybindings
	(define-key map (kbd "C-c C-p") 'csound-play)
	(define-key map (kbd "C-c C-r") 'csound-render) 
	;; REPL Keybindings
	(define-key map (kbd "C-c C-z") 'csound-repl-start)
	(define-key map (kbd "C-M-x")   'csound-repl-evaluate-region)
	(define-key map (kbd "C-c C-c") 'csound-repl-evaluate-region)
	(define-key map (kbd "C-x C-e") 'csound-repl-evaluate-line)
	(define-key map (kbd "C-c C-l") 'csound-repl-interaction-evaluate-last-expression)
	;; Utilities
	(define-key map (kbd "C-c C-s") 'csound-score-align-block)
	(define-key map (kbd "M-.")     'csound-score-find-instr-def)
	;; (define-key map (kbd "C-c C-f") 'csound-repl-plot-ftgen)
	map))

;;;###autoload
(define-derived-mode csound-mode
  fundamental-mode "Csound Mode"
  "A major mode for interacting and coding Csound"
  :syntax-table csound-mode-syntax-table
  (setq-local eldoc-documentation-function 'csound-eldoc-function)
  (setq-local comment-start ";; ")
  ;; (setq-local comment-end "")
  (setq-local indent-line-function 'csound-indentation-line)
  
  (setq-local compilation-scroll-output t)
  (setq-local ad-redefinition-action 'accept)
  (setq-local font-lock-comment-end-skip "\n")
  (add-hook 'completion-at-point-functions #'csound-util-opcode-completion-at-point nil t)
  ;; (add-hook 'skeleton-end-hook #'csound-font-lock-flush-buffer nil t) 
  (font-lock-add-keywords nil csound-font-lock-list t)
  (setq-local font-lock-fontify-region-function 'csound-font-lock-fontify-region)
  (setq-local font-lock-fontify-buffer-function 'csound-font-lock-flush-buffer)
  ;; (setq-local jit-lock-mode t)
  ;; (setq-local jit-lock-contextually t)
  (shut-up
    (with-silent-modifications
      (csound-font-lock--flush-score))))


(add-to-list 'auto-mode-alist `(,(concat "\\." (regexp-opt '("csd" "orc" "sco" "udo")) "\\'") . csound-mode))

(provide 'csound-mode)

;;; csound-mode.el ends here

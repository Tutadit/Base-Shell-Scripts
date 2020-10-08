
;; No clutter
(setq backup-directory-alist
      `((".*" . ,"~/.emacs.d/emacs-saves/")))
(setq auto-save-file-name-transforms
      `((".*" ,"~/.emacs.d/emacs-saves/" t)))

;; Wat Mode
(add-to-list 'load-path "/home/jp/.emacs.d/plugins/wat-mode-master")
(require 'wat-mode)

;; Mutt support.
(setq auto-mode-alist (append '(("/tmp/mutt.*" . mail-mode)) auto-mode-alist))

(setq backup-directory-alist `(("." . "~/.saves")))

;; Remote file access
(setq tramp-default-method "ssh")
(setq tramp-terminal-type "tramp")
(defun connect-uc ()
  (interactive)
  (dired "/ssh:juanpablo.lozanosarm@linuxlab.cpsc.ucalgary.ca:~/"))


;; Show them colors on them buffers
(require 'ansi-color)
(defun my/ansi-colorize-buffer ()
  (let ((buffer-read-only nil))
    (ansi-color-apply-on-region (point-min) (point-max))))
(add-hook 'compilation-filter-hook 'my/ansi-colorize-buffer)

;; Git with Magit
(global-set-key (kbd "C-x g") 'magit-status)

;; Javadoc
(setq browse-url-generic-program "min")
(setq browse-url-browser-function 'browse-url-generic )

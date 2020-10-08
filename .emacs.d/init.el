(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl
    (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives (cons "gnu" (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("c5c582274784125603ea03dcd67c1ed377e57ea4decfd04ad11e9351628444a9" "2e0ed51df4c3be3c89ad1cd9954c4c9ac3a2776da852e2b3cf3ae345f6c899dd" "c74e83f8aa4c78a121b52146eadb792c9facc5b1f02c917e3dbb454fca931223" default))
 '(package-selected-packages
   '(csv-mode qml-mode javadoc-lookup ag projectile magit git es-mode rjsx-mode hide-lines smartparens php-mode mutt-mode bison-mode powerthesaurus smart-mode-line)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(load "~/.emacs.d/settings/csound.el")
(load "~/.emacs.d/settings/general.el")
(load "~/.emacs.d/settings/eye_candy.el")
(load "~/.emacs.d/settings/org_mode.el")
(load "~/.emacs.d/settings/folding.el")
(load "~/.emacs.d/settings/highlight-indentation.el")

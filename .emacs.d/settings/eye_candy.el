;;
;; Make it pretty
;;

;; Hide menu bar
(menu-bar-mode -1)

;; Change footer bar
(setq sml/theme 'respectful)
(sml/setup)

;; Show me them numbers
(global-linum-mode t)

;; Margin that up
(set-window-margins (selected-window) 3)

;; Themes
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")
(load-theme 'monokai)

;; Make it see through
(set-frame-parameter (selected-frame) 'alpha '(00 . 00))
(add-to-list 'default-frame-alist '(alpha . (00 . 00)))

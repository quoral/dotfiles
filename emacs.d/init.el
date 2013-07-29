(require 'package)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/") t)

(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)

(package-initialize)

(when (not package-archive-contents)
  (package-refresh-contents))

;; Important packages
(defvar my-pkgs '(starter-kit
                  puppet-mode 
                  starter-kit-bindings
                  magit
                  evil
                  solarized-theme
                  rainbow-delimiters
                  )
  "A list of packages to install at launch.")

(dolist (p my-pkgs)
  (when (not (package-installed-p p))
    (package-install p)))

(require 'erc)
(load "~/.emacs.d/init-functions.el")
(load "~/.emacs.d/init-irc.el")
(load "~/.emacs.d/init-eshell.el")

;; Things that need to be downloaded manually
(custom-download-script "https://raw.github.com/dimitri/switch-window/master/switch-window.el"
                        "switch-window.el")

(custom-download-theme "https://raw.github.com/rexim/gruber-darker-theme/master/gruber-darker-theme.el"
                       "gruber-darker-theme.el")

;; Generic settings for Mac (Expecting emacs to be run in Cocoa wrapper)

(menu-bar-mode 1)
(setq x-select-enable-clipboard t)
(setq ns-use-native-fullscreen nil)


;; Swedish!
(set-language-environment 'Swedish)

(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

(load-theme 'gruber-darker t)

;; Seed RNG
(random t)

;; Start server for emacsclient
(server-start)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("854dc57026d3226addcc46b2b460034a74609edbd9c14e626769ac724b10fcf5" "2ff493cb70e33443140cd5286553d994f25478182a8c20382895f452666c20c6" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" "ea0c5df0f067d2e3c0f048c1f8795af7b873f5014837feb0a7c8317f34417b04" default)))
 '(erc-modules
   (quote
    (autojoin button completion irccontrols list match menu move-to-prompt netsplit networks noncommands notifications readonly ring scrolltobottom stamp track)))
 '(frame-brackground-mode (quote dark))
 '(ns-alternate-modifier (quote none))
 '(ns-command-modifier (quote meta)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

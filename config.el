(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
    (defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
    (defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
    (defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                                  :ref nil
                                  :files (:defaults (:exclude "extensions"))
                                  :build (:not elpaca--activate-package)))
    (let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
           (build (expand-file-name "elpaca/" elpaca-builds-directory))
           (order (cdr elpaca-order))
           (default-directory repo))
      (add-to-list 'load-path (if (file-exists-p build) build repo))
      (unless (file-exists-p repo)
        (make-directory repo t)
        (when (< emacs-major-version 28) (require 'subr-x))
        (condition-case-unless-debug err
            (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                     ((zerop (call-process "git" nil buffer t "clone"
                                           (plist-get order :repo) repo)))
                     ((zerop (call-process "git" nil buffer t "checkout"
                                           (or (plist-get order :ref) "--"))))
                     (emacs (concat invocation-directory invocation-name))
                     ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                           "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                     ((require 'elpaca))
                     ((elpaca-generate-autoloads "elpaca" repo)))
                (kill-buffer buffer)
              (error "%s" (with-current-buffer buffer (buffer-string))))
          ((error) (warn "%s" err) (delete-directory repo 'recursive))))
      (unless (require 'elpaca-autoloads nil t)
        (require 'elpaca)
        (elpaca-generate-autoloads "elpaca" repo)
        (load "./elpaca-autoloads")))
    (add-hook 'after-init-hook #'elpaca-process-queues)
    (elpaca `(,@elpaca-order))

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable :elpaca use-package keyword.
  (elpaca-use-package-mode)
  ;; Assume :elpaca t unless otherwise specified.
  (setq elpaca-use-package-by-default t))

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Block until current queue processed.
(elpaca-wait)

;;When installing a package which modifies a form used at the top-level
;;(e.g. a package which adds a use-package key word),
;;use `elpaca-wait' to block until that package has been installed/configured.
;;For example:
;;(use-package general :demand t)
;;(elpaca-wait)

    ;;Turns off elpaca-use-package-mode current declartion
    ;;Note this will cause the declaration to be interpreted immediately (not deferred).
    ;;Useful for configuring built-in emacs features.
    (use-package emacs :elpaca nil :config (setq ring-bell-function #'ignore))

    ;; Don't install anything. Defer execution of BODY
    ;;(elpaca nil (message "deferred"))

;; Expands to: (elpaca evil (use-package evil :demand t))
(use-package evil
    :init ;; tweak evil's configuration before loading it
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-vsplit-window-right t) ;;maybe change this
  (setq evil-split-window-below t)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))
(use-package evil-collection
:after evil
:config
(setq evil-collection-mode-list '(dashboard dired ibuffer))
(evil-collection-init))
(use-package evil-tutor)

(use-package general
          :config
          (general-evil-setup)

          ;; set up 'spc' as the global leader key
          (general-create-definer zd/leader-keys
            :states '(normal insert visual emacs)
            :keymaps 'override
            :prefix "SPC" ;; set leader
            :global-prefix "C-SPC") ;; access leader in insert mode

      (zd/leader-keys
          "f" '(:ignore t :wk "Find")
          "f f" '(counsel-find-file :wk "Find file")
          "f c" '((lambda () (interactive) (find-file "~/.config/emacs/config.org")) :wk "Edit emacs config")
          "f r" '(counsel-recentf :wk "Find recent files")
          "TAB TAB" '(comment-line :wk "Comment lines"))

          (zd/leader-keys
            "b" '(:ignore t :wk "Buffer")
            "b b" '(switch-to-buffer :wk "Switch buffer")
            "b k" '(kill-this-buffer :wk "Kill this buffer")
            "b n" '(next-buffer :wk "Next buffer")
            "b p" '(previous-buffer :wk "Previous buffer")
            "b r" '(revert-buffer :wk "Reload buffer")
            "b i" '(counsel-ibuffer :wk "Ibuffer"))

        (zd/leader-keys
          "e" '(:ignore t :wk "Eval")    
          "e b" '(eval-buffer :wk "Evaluate elisp in buffer")
          "e d" '(eval-defun :wk "Evaluate defun containing or after point")
          "e e" '(eval-expression :wk "Evaluate an elisp expression")
          "e l" '(eval-last-sexp :wk "Evaluate elisp expression before point")
          "e r" '(eval-region :wk "Evaluate elisp in region"))

    (zd/leader-keys
        "E" '(:ignore t :wk "Eshell")
        "E h" '(counsel-esh-history :wk "Eshell history")
        "E s" '(eshell :wk "Eshell"))

    (zd/leader-keys
        "h" '(:ignore t :wk "Help")
        "h f" '(describe-function :wk "Describe function")
        "h v" '(describe-variable :wk "Describe variable"))

        ;; Makes ESC quit prompts
        (global-set-key (kbd "<escape>") 'keyboard-escape-quit)


   (zd/leader-keys
    "t" '(:ignore t :wk "Toggle")
    "t l" '(display-line-numbers-mode :wk "Toggle line numbers")
    "t t" '(visual-line-mode :wk "Toggle truncated lines")
    "t v" '(vterm-toggle :wk "Toggle vterm"))

 (zd/leader-keys
    "w" '(:ignore t :wk "Windows")
    ;; Window splits
    "w c" '(evil-window-delete :wk "Close window")
    "w n" '(evil-window-new :wk "New window")
    "w s" '(evil-window-split :wk "Horizontal split window")
    "w v" '(evil-window-vsplit :wk "Vertical split window")
    ;; Window motions
    "w h" '(evil-window-left :wk "Window left")
    "w j" '(evil-window-down :wk "Window down")
    "w k" '(evil-window-up :wk "Window up")
    "w l" '(evil-window-right :wk "Window right")
    "w w" '(evil-window-next :wk "Go to next window")
    ;; Move Windows
    "w H" '(buf-move-left :wk "Buffer move left")
    "w J" '(buf-move-down :wk "Buffer move down")
    "w K" '(buf-move-up :wk "Buffer move up")
    "w L" '(buf-move-right :wk "Buffer move right"))
)

(use-package hydra)
;; For setting up quick cycle keybind

(use-package which-key
  :init
    (which-key-mode 1)
  :config
  (setq
        which-key-idle-delay 0.8))

(set-face-attribute 'default nil
  :font "JetBrains Mono"
  :height 110
  :weight 'medium)
(set-face-attribute 'variable-pitch nil
  :font "Ubuntu"
  :height 120
  :weight 'medium)
(set-face-attribute 'fixed-pitch nil
  :font "JetBrains Mono"
  :height 110
  :weight 'medium)
;; Makes commented text and keywords italics.
;; Only works in emacsclient not emacs.
;; You gotta have an italic face available.
(set-face-attribute 'font-lock-comment-face nil
  :slant 'italic)
(set-face-attribute 'font-lock-comment-face nil
  :slant 'italic)

;; This sets the defaoult font on all graphical frames created after restarting Emacs
;; Does the same as 'set-face-attribute default' above
;;but fonts on emacsclient don't work without this
(add-to-list 'default-frame-alist '(font . "JetBrains Mono-11"))

;; Just line spacing
(setq-default line-spacing 0.12)

(use-package all-the-icons
  :ensure t
  :if (display-graphic-p))

(use-package all-the-icons-dired
  :hook (dired-mode . (lambda () (all-the-icons-dired-mode t))))

(use-package doom-themes
  :init (load-theme 'doom-palenight t))

(global-set-key (kbd "C-=") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)
(global-set-key (kbd "<C-wheel-up>") 'text-scale-increase)
(global-set-key (kbd "<C-wheel-down>") 'text-scale-decrease)

(require 'windmove)

;;;###autoload
(defun buf-move-up ()
  "Swap the current buffer and the buffer above the split.
If there is no split, ie now window above the current one, an
error is signaled."
;;  "Switches between the current buffer, and the buffer above the
;;  split, if possible."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'up))
	 (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No window above this one")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;;;###autoload
(defun buf-move-down ()
"Swap the current buffer and the buffer under the split.
If there is no split, ie now window under the current one, an
error is signaled."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'down))
	 (buf-this-buf (window-buffer (selected-window))))
    (if (or (null other-win) 
            (string-match "^ \\*Minibuf" (buffer-name (window-buffer other-win))))
        (error "No window under this one")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;;;###autoload
(defun buf-move-left ()
"Swap the current buffer and the buffer on the left of the split.
If there is no split, ie now window on the left of the current
one, an error is signaled."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'left))
	 (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No left split")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

;;;###autoload
(defun buf-move-right ()
"Swap the current buffer and the buffer on the right of the split.
If there is no split, ie now window on the right of the current
one, an error is signaled."
  (interactive)
  (let* ((other-win (windmove-find-other-window 'right))
	 (buf-this-buf (window-buffer (selected-window))))
    (if (null other-win)
        (error "No right split")
      ;; swap top with this one
      (set-window-buffer (selected-window) (window-buffer other-win))
      ;; move this one to top
      (set-window-buffer other-win buf-this-buf)
      (select-window other-win))))

(use-package rainbow-mode
  :hook org-mode prog-mode)

(require 'org
  (setq org-agenda-files
    '("~/org/tasks.org")))

(setq org-agenda-start-with-log-mode t)
(setq org-log-done 'time)
(setq org-log-into-drawer t)

(setq org-refile-targets
  '(("archive.org" :maxlevel . 1)
    ("tasks.org" :maxlevel . 1)))

;; Saves Org buffers after refiling
(advice-add 'org-refile :after 'org-save-all-org-buffers)

(require 'org-tempo)

(use-package toc-org
  :commands toc-org-enable
  :init (add-hook 'org-mode-hook 'toc-org-enable))

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory "~/org/RoamNotes")
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert))
  :config
  (org-roam-setup))

(use-package org-roam-ui
  :after org-roam
  :hook (after-init . org-roam-ui-mode)
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(add-hook 'org-mode-hook 'org-indent-mode)
(use-package org-bullets)
(add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))

(electric-indent-mode -1)

(menu-bar-mode -1) ;; Disables menubar
(tool-bar-mode -1) ;; Disables toolbar
(scroll-bar-mode -1) ;; Disables scrollbar
(set-fringe-mode -1) 
(setq inhibit-startup-message t) ;; Disables the startup message

(global-display-line-numbers-mode 1)
 (global-visual-line-mode t)

;; Disables line numbers for shell and term mode
 (dolist (mode '(term-mode-hook shell-mode-hook))
 (add-hook mode (lambda () (display-line-numbers-mode 0))))

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :custom (mode-line-height 10))

(use-package counsel
  :after ivy
  :bind ("M-x" . counsel-M-x)

  :config (counsel-mode)
  (setq ivy-initial-inputs-alist nil))

(use-package ivy
       :bind (("C-s" . swiper)
       :map ivy-minibuffer-map
       ("TAB" . ivy-alt-done)
       ("C-l" . ivy-alt-done)
       ("C-j" . ivy-next-line)
       ("C-k" . ivy-previous-line)
       :map ivy-switch-buffer-map
       ("C-k" . ivy-previous-line)
       ("C-l" . ivy-done)
       ("C-d" . ivy-switch-buffer-kill)
       :map ivy-reverse-i-search-map
       ("C-k" . ivy-previous-line)
       ("C-d" . ivy-reverse-i-search-kill)
       ("C-c C-r" . ivy-resume)
       ("C-x B" . ivy-switch-buffer-other-window))

  :custom 
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d/%d) ")
  :config
  (ivy-mode))

(use-package all-the-icons-ivy-rich
  :ensure t
  :init (all-the-icons-ivy-rich-mode 1))
(use-package ivy-rich
  :after ivy
  :ensure t
  :init (ivy-rich-mode 1)
  :custom
  (ivy-virtual-abbreviate 'full
   ivy-rich-switch-buffer-align-virtual-buffer t
   ivy-rich-path-style 'abbrev)
  :config
  (ivy-set-display-transformer 'ivy-switch-buffer
                               'ivy-rich-switch-buffer-transformer))

(use-package eshell-syntax-highlighting
  :after esh-mode
  :config
  (eshell-syntax-highlighting-global-mode +1))

;; eshell-syntax-highlighting -- adds fish/zsh-like syntax highlighting.
;; eshell-rc-script -- your profile for eshell; like a bashrc for eshell.
;; eshell-aliases-file -- sets an aliases file for the eshell.
  
(setq eshell-rc-script (concat user-emacs-directory "eshell/profile")
      eshell-aliases-file (concat user-emacs-directory "eshell/aliases")
      eshell-history-size 5000
      eshell-buffer-maximum-lines 5000
      eshell-hist-ignoredups t
      eshell-scroll-to-bottom-on-input t
      eshell-destroy-buffer-when-process-dies t
      eshell-visual-commands'("bash" "fish" "htop" "ssh" "top" "zsh"))

(use-package vterm
:config
(setq shell-file-name "/bin/bash"
      vterm-max-scrollback 5000))

(use-package vterm-toggle
  :after vterm
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (setq vterm-toggle-scope 'project)
  (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _)
                     (let ((buffer (get-buffer buffer-or-name)))
                       (with-current-buffer buffer
                         (or (equal major-mode 'vterm-mode)
                             (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                  (display-buffer-reuse-window display-buffer-at-bottom)
                  ;;(display-buffer-reuse-window display-buffer-in-direction)
                  ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                  ;;(direction . bottom)
                  ;;(dedicated . t) ;dedicated is supported in emacs27
                  (reusable-frames . visible)
                  (window-height . 0.3))))

(use-package sudo-edit
  :config
    (zd/leader-keys
      "fu" '(sudo-edit-find-file :wk "Sudo find file")
      "fU" '(sudo-edit :wk "Sudo edit file")))

(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(use-package projectile
    :diminish projectile-mode
    :custom ((projectile-completion-system 'ivy))
    :config (projectile-mode)
    :bind-keymap
    ("C-c p" . projectile-command-map)
    :init
    (when (file-directory-p "~/Projects/Code")
    (setq projectile-project-search-path '("~/Projects/Code")))
    (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :config (counsel-projectile-mode))

(use-package magit
    :ensure t
    :after evil
    :init
    (evil-collection-init))

  (use-package forge)
  ;; Need to authenicate throught GitHub
  
(use-package sqlite3)
<<<<<<< HEAD

(setq backup-directory-alist '(("." . ,(expand-file-name "tmp/backups/" user-emacs-directory))))
=======
>>>>>>> 74b5619 (Added some org function)

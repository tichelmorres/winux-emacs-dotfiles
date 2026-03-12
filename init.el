(package-initialize)

;; -------------
;; --- Start ---
;; -------------

(defvar lwc/config-dir
  (cond
   ((eq system-type 'windows-nt)
    (expand-file-name "~/.emacs.d/"))
   (t
    (expand-file-name "~/.config/emacs/"))))

(defun lwc/config-path (&rest segments)
  (apply #'expand-file-name (mapconcat #'identity segments "/")
         (list lwc/config-dir)))

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(add-to-list 'load-path (lwc/config-path "local"))
(load-file (lwc/config-path "local" "rc.el"))
(load-file (lwc/config-path "local" "ml.el"))
(load-file (lwc/config-path "local" "mo.el"))
(load-file (lwc/config-path "local" "la.el"))

;; | --------------------------------------------
;; |  General
;; | --------------------------------------------

;; Disable warnings at initialization
(setq warning-minimum-level :emergency)

;; Disable auto-saving...
(setq auto-save-default nil)

;; Disable backup shit
(setq backup-directory-alist `((".*" . ,(lwc/config-path "backups"))))
(setq make-backup-files t)
(setq backup-by-copying t)
(setq delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)
(setq create-lockfiles nil)

;; Typefaces
(defun rc/get-default-font ()
  (cond
   ((eq system-type 'windows-nt) "Consolas-15")
   ((eq system-type 'gnu/linux)  "Iosevka Nerd Font Mono-19")))

(add-to-list 'default-frame-alist `(font . ,(rc/get-default-font)))

;; Use space characters, not tabs
(setq-default indent-tabs-mode nil)

;; Disable menu bar, toolbar and scrollbars
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(horizontal-scroll-bar-mode -1)

;; Disable top/bottom padding while scrolling
(setq scroll-margin 0)

;; Disable annoying bell sound
(setq ring-bell-function 'ignore)

;; Disable automatic indentation
(electric-indent-mode -1)

;; Use the uniform line height "latex-mode",
;; insert a literal " instead of smart quotes (`` / ''),
;; enable truncate mode automatically for LaTeX mode
(with-eval-after-load 'latex
  (advice-add 'LaTeX-mode :override #'latex-mode))

(add-hook 'latex-mode-hook
          (lambda ()
            (local-set-key (kbd "\"") #'self-insert-command)
            (setq truncate-lines 1)
            (call-interactively #'toggle-truncate-lines))
          t)

;; Auto-completion
(ido-mode t)
(ido-everywhere t)

(icomplete-mode 1)
(setq icomplete-show-matches-on-no-input t)

(rc/require 'smex)
(global-set-key (kbd "M-x") 'smex)

;; Enable global line numbers
;; (and disable it in some cases)
(global-display-line-numbers-mode t)

(add-hook 'org-mode-hook      (lambda () (display-line-numbers-mode 0)))
(add-hook 'markdown-mode-hook (lambda () (display-line-numbers-mode 0)))
(add-hook 'gfm-mode-hook      (lambda () (display-line-numbers-mode 0)))
(add-hook 'latex-mode-hook    (lambda () (display-line-numbers-mode 0)))

;; Set min number line width to 4 characters
(setq-default display-line-numbers-width 4)

;; Top line
(setq-default header-line-format
	      " onque pewueno dissdy estavfazendo na xelcukadora")

;; Org files config
(rc/require 'org-inline-anim)
(setq org-inline-anim-loop t)

(setq org-startup-with-inline-images t)

(setq ml/dash-file (lwc/config-path "dash.org"))
(defun ml/org-animate-gifs-in-dash ()
  (when (and buffer-file-name
	     (string-equal (file-truename buffer-file-name)
			   (file-truename ml/dash-file)))
    (org-display-inline-images)
    (org-inline-anim-mode 1)
    (when (fboundp 'org-inline-anim-animate-all)
      (org-inline-anim-animate-all))))

(add-hook 'org-mode-hook #'ml/org-animate-gifs-in-dash)

(setq org-startup-indented t)
(setq org-hide-leading-stars t)
(setq org-hide-emphasis-markers t)
(setq org-hide-leading-stars t)

;; Disable automatic line wrapping
(setq-default truncate-lines t)

;; One-line scrolling when pointer hits window edge
(setq scroll-conservatively 101
      scroll-step 1
      scroll-preserve-screen-position t
      scroll-margin 0)

;; Disable splash screen and welcome message
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)

(defun display-startup-echo-area-message ()
  (message ""))

;; Use custom start page (read-only)
(setq initial-buffer-choice ml/dash-file)
(rc/require 'visual-fill-column)
(setq visual-fill-column-center-text t)

(add-hook 'emacs-startup-hook
          (lambda ()
            (when (string-equal (buffer-file-name) ml/dash-file)
              (org-mode)
              (setq-local org-link-elisp-confirm-function nil)
              (setq-local visual-fill-column-width 40)
              (visual-line-mode 1)
              (read-only-mode 1)
              (visual-fill-column-mode 1)
              (goto-char (point-min))
              (forward-line 14)
              (let ((win (get-buffer-window (current-buffer) t)))
                (when win (with-selected-window win (recenter (/ (window-body-height) 2))))))))

;; Also center LaTeX files
;; (add-hook 'latex-mode-hook
;;           (lambda ()
;;             (setq-local visual-fill-column-width 70)
;;             (visual-fill-column-mode 1)))

;; Better ls for dired
(require 'ls-lisp)

(setq ls-lisp-use-insert-directory-program nil)
(setq ls-lisp-dirs-first nil)

(defvar ml/lualatex '("aux" "log" "out"))
(defun ml/dired-extension-priority (filename)
  (let* ((base (directory-file-name (file-name-nondirectory filename)))
         (ext  (downcase (or (file-name-extension base) ""))))
    (cond ((string= base ".")          0)
          ((string= base "..")         1)
          ((string= ext  "tex")        2)
          ((string= ext  "pdf")        3)
          ((member  ext  ml/lualatex)  4)
	  ;; ← other files and dirs come here
          ((string= base ".git")       6)
          ((string= base ".gitignore") 7)
          (t                           5))))

(advice-add 'ls-lisp-handle-switches :filter-return
  (lambda (file-alist)
    (sort file-alist
          (lambda (a b)
            (let ((pa (ml/dired-extension-priority (car a)))
                  (pb (ml/dired-extension-priority (car b))))
              (if (= pa pb)
                  (ls-lisp-string-lessp (car a) (car b))
                (< pa pb))))))
  '((name . ml/dired-extension-priority-sort)))

;; Kill buffers at start

;; scratch
;; (add-hook 'emacs-startup-hook (lambda ()
;;   (when (get-buffer "*scratch*")
;;     (kill-buffer "*scratch*"))))

;; async compile log
;; (add-hook 'emacs-startup-hook (lambda ()
;;     (when (get-buffer "*Async-native-compile-log*")
;;       (kill-buffer "*Async-native-compile-log*"))))

;; | --------------------------------------------
;; |  Binds
;; | --------------------------------------------

;; Enable Common User Access mode to use
;; C-c, C-v, C-z and other default binds
(cua-mode t)

;; Copy without losing selection
(advice-add 'kill-ring-save :after #'ml/keep-region-active-after-copy)

(when (fboundp 'cua-copy-region)
  (advice-add 'cua-copy-region :after #'ml/keep-region-active-after-copy))

;; C-y => redo changes
(global-set-key (kbd "C-y") #'undo-redo)

;; Move line(s) contents Up or Down
;; M-<up> && M-<down>
(global-set-key (kbd "M-<up>")  'ml/move-text-up)
(global-set-key (kbd "M-<down>") 'ml/move-text-down)

;; C-+ => larger window
;; C-- => smaller window
(global-set-key (kbd "C-+")  #'ml/text-scale-increase)
(global-set-key (kbd "C-=")  #'ml/text-scale-increase)
(global-set-key (kbd "C-x C-+") #'ml/text-scale-increase)
(global-set-key (kbd "C-x C-=") #'ml/text-scale-increase)

(global-set-key (kbd "C--")  #'ml/text-scale-decrease)
(global-set-key (kbd "C-_")  #'ml/text-scale-decrease)
(global-set-key (kbd "C-x C--") #'ml/text-scale-decrease)
(global-set-key (kbd "C-x C-_") #'ml/text-scale-decrease)

;; Ctrl + f for search and Ctrl + s for writing
;; Also remove Ctrl + b
(global-set-key (kbd "C-f") #'isearch-forward)
(with-eval-after-load 'isearch
  (define-key isearch-mode-map (kbd "C-f") #'isearch-repeat-forward))

(global-set-key (kbd "C-b") (lambda () (interactive)))
(global-set-key (kbd "C-s") #'save-buffer)

;; Ctrl + a selects all text
(global-set-key (kbd "C-a") #'mark-whole-buffer)

;; Ctrl + l => open link
(global-set-key (kbd "C-l") #'ml/open-link-item)

;; Dedent by one tab
(global-set-key (kbd "<backtab>") #'ml/dedent-rigidly)

;; Overwrite default inden
;; (so selection mark in not unset after use)
(global-set-key (kbd "<tab>") #'ml/indent-more-rigidly)

;; Toggle comment on region or current line
(global-set-key (kbd "C-;") #'ml/toggle-comment)

;; Multiple cursors
(rc/require 'multiple-cursors)

(global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
(global-set-key (kbd "C->")         'mc/mark-next-like-this)
(global-set-key (kbd "C-<")         'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<")     'mc/mark-all-like-this)
(global-set-key (kbd "C-\"")        'mc/skip-to-next-like-this)
(global-set-key (kbd "C-:")         'mc/skip-to-previous-like-this)

;; Duplicate line
(global-set-key (kbd "C-,") 'rc/duplicate-line)

;; Open LaTeX as PDF
(global-set-key (kbd "C-c p p") #'la/latex-compile-and-open)

;; Open GAMES buffer
(global-set-key (kbd "C-c g") #'ml/open-games-buffer)

;; | --------------------------------------------
;; |  Themes
;; | --------------------------------------------

(rc/require 'doom-themes)
;(load-theme 'doom-xcode t)
(load-theme 'doom-henna t)

;; Apply matugen overrides
;(mo/apply-theme-background-overrides)

;; Don't let the theme set a background color on -nw mode
(unless (display-graphic-p)
    (set-face-background 'default "unspecified-bg"))

;; | --------------------------------------------
;; |  Programming
;; | --------------------------------------------

;; Use Simple C instead of C mode
;; Source: https://github.com/rexim/simpc-mode
(require 'simpc-mode)
(add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode))

;; Julia
(rc/require 'julia-mode)
(require 'julia-mode)
(add-to-list 'auto-mode-alist '("\\.j\\(l\\|ulia\\)\\'" . julia-mode))

;; Nix
(rc/require 'nix-mode)
(require 'nix-mode)
(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))

;; Markdown
(rc/require 'markdown-mode)
(require 'markdown-mode)
(add-to-list 'auto-mode-alist '("\\.m\\(d\\|arkdown\\)\\'" . markdown-mode))

;; Rust
(rc/require 'rust-mode)
(require 'rust-mode)
(add-to-list 'auto-mode-alist '("\\.r\\(s\\|lib\\)\\'" . rust-mode))

;; Disable lsp info window at the bottom
(setq lsp-signature-auto-activate nil)

;; Prefer fish for interactive shells,
;; but keep POSIX sh for non-interactive commands
;; (no windows support)
(unless (eq system-type 'windows-nt)
  (let* ((fish-candidates (list (executable-find "fish")
                                (expand-file-name "~/.nix-profile/bin/fish")
                                "/run/current-system/sw/bin/fish"))
         (fish (seq-find #'identity fish-candidates)))
    (when fish
      (setq explicit-shell-file-name fish)
      (setq shell-file-name "/bin/sh")
      (setenv "SHELL" fish)
      (add-to-list 'exec-path (file-name-directory fish)))))

;; | --------------------------------------------
;; |  Others
;; | --------------------------------------------

;; Translation
(rc/require 'google-translate)
(require 'google-translate)
(require 'google-translate-smooth-ui)
(global-set-key (kbd "C-c t") 'google-translate-smooth-translate)

;; -----------
;; --- End ---
;; -----------

(setq custom-file (lwc/config-path "custom.el"))
(load-file (lwc/config-path "custom.el"))

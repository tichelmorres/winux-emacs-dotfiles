(defvar mo/theme-background     "#1f262e")
;; (defvar mo/menu-background      "#101418")
(defvar mo/menu-background      "#1f262e")
(defvar mo/mode-line-background "#101418")
(defvar mo/highlight-background "#29333d")

(defun mo/apply-theme-background-overrides ()
  (when (display-graphic-p)
    (require 'color)
    (set-face-attribute 'default nil :background mo/theme-background)
    (set-face-attribute 'fringe nil :background mo/theme-background)

    (set-face-attribute 'mode-line nil
                        :background mo/mode-line-background
                        :box nil)
    (set-face-attribute 'mode-line-inactive nil
                        :background (color-darken-name mo/mode-line-background 8)
                        :box nil)
    (set-face-attribute 'header-line nil
                        :background mo/menu-background
                        :box nil)

    (set-face-attribute 'menu nil :background mo/menu-background)

    (when (facep 'line-number)
      (set-face-attribute 'line-number nil
                          :background mo/theme-background))
    (when (facep 'line-number-current-line)
      (set-face-attribute 'line-number-current-line nil
                          :background mo/theme-background
                          :weight 'bold))

    (set-face-attribute 'region nil :background mo/highlight-background)
    (when (facep 'secondary-selection)
      (set-face-attribute 'secondary-selection nil :background mo/highlight-background))))

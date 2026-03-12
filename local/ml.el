(defun ml/keep-region-active-after-copy (&rest _args)
  (when (use-region-p)
    (setq deactivate-mark nil)
    (setq mark-active t)))

(defun ml/move-text--line-region-bounds ()
  (if (use-region-p)
      (let ((start (region-beginning))
            (end (region-end)))
        (goto-char start) (beginning-of-line) (setq start (point))
        (goto-char end) (unless (bolp) (end-of-line)) (setq end (point))
        (cons start end))
    (let ((start (line-beginning-position)))
      (goto-char start)
      (end-of-line)
      (if (< (point) (point-max)) (forward-char 1))
      (cons start (point)))))

(defun ml/move-text-internal (arg)
  (let* ((arg (or arg 1))
         (regionp (use-region-p))
         (orig-point (point))
         (orig-mark (when regionp (mark)))
         bounds start end point-offset mark-offset insert-point new-start new-point new-mark text-len)
    (setq bounds (ml/move-text--line-region-bounds))
    (setq start (car bounds) end (cdr bounds))
    (setq point-offset (- orig-point start))
    (when orig-mark (setq mark-offset (- orig-mark start)))
    (if (fboundp 'atomic-change-group)
        (atomic-change-group
         (let ((text (delete-and-extract-region start end)))
           (forward-line arg)
           (setq insert-point (point))
           (insert text)
           (setq new-start insert-point
                 text-len (length text))
           (setq new-point (max new-start (min (+ new-start point-offset) (+ new-start text-len))))
           (setq new-mark (when mark-offset
                            (max new-start (min (+ new-start mark-offset) (+ new-start text-len)))))
           (when new-mark (set-mark new-mark))
           (goto-char new-point)
           (when regionp (setq deactivate-mark nil))))
      (let ((text (delete-and-extract-region start end)))
        (forward-line arg)
        (setq insert-point (point))
        (insert text)
        (setq new-start insert-point
              text-len (length text))
        (setq new-point (max new-start (min (+ new-start point-offset) (+ new-start text-len))))
        (setq new-mark (when mark-offset
                         (max new-start (min (+ new-start mark-offset) (+ new-start text-len)))))
        (when new-mark (set-mark new-mark))
        (goto-char new-point)
        (when regionp (setq deactivate-mark nil))))))

(defun ml/move-text-up (arg)
  (interactive "p")
  (ml/move-text-internal (- (or arg 1))))

(defun ml/move-text-down (arg)
  (interactive "p")
  (ml/move-text-internal (or arg 1)))

(defun ml/text-scale-increase ()
  (interactive)
  (text-scale-increase 1))

(defun ml/text-scale-decrease ()
  (interactive)
  (text-scale-increase -1))

(defun ml/dedent-rigidly ()
  (interactive)
  (let* ((step tab-width)
         (start (if (use-region-p) (region-beginning) (line-beginning-position)))
         (end   (if (use-region-p) (region-end)       (line-end-position))))
    (let ((deactivate-mark nil))
      (indent-rigidly start end (- step)))))

(defun ml/indent-more-rigidly ()
  (interactive)
  (if (use-region-p)
      (let ((start (region-beginning))
            (end   (region-end)))
        (let ((deactivate-mark nil))
          (indent-region start end)))
    (indent-for-tab-command)))

(defun ml/toggle-comment (beg end)
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (line-beginning-position) (line-end-position))))
  (let ((deactivate-mark nil))
    (comment-or-uncomment-region beg end)))

(defun ml/open-link-item ()
  (interactive)
  (require 'subr-x)
  (cond
   ((string= (buffer-name) "*games*")
    (let* ((line  (string-trim (thing-at-point 'line t)))
           (game  (intern-soft line)))
      (if (and game (commandp game))
          (progn
            (kill-buffer "*games*")
            (call-interactively game))
        (message "No game found at point: %s" line))))

   ((derived-mode-p 'org-mode)
    (let* ((el (ignore-errors (org-element-context)))
           (is-link (and el (eq (org-element-type el) 'link)))
           (raw (and is-link (org-element-property :raw-link el)))
           (type (and is-link (org-element-property :type el))))
      (if (and raw (or (string= type "eww") (string-match-p "\\`eww:" raw)))
          (let ((url (replace-regexp-in-string "\\`eww:" "" raw)))
            (require 'eww)
            (eww-browse-url url)
            (delete-other-windows))
        (let ((cmd (key-binding (kbd "C-u C-c C-o C-x 1"))))
          (if (commandp cmd)
              (call-interactively cmd)
            (execute-kbd-macro (kbd "C-u C-c C-o C-x 1")))))))

   ((derived-mode-p 'eww-mode)
    (let ((url (or (and (fboundp 'eww-link-at-point) (eww-link-at-point))
                   (get-text-property (point) 'shr-url)
                   (thing-at-point 'url))))
      (if url
          (progn
            (require 'eww)
            (eww-browse-url (string-trim url))
            (delete-other-windows)))))

   (t
    (let ((url (thing-at-point 'url)))
      (if url
          (browse-url (string-trim url))
        (let ((cmd (key-binding (kbd "C-u C-c C-o C-x 1"))))
          (if (commandp cmd)
              (call-interactively cmd)
            (execute-kbd-macro (kbd "C-u C-c C-o C-x 1")))))))))

(defun ml/open-games-buffer ()
  (interactive)
  (let ((games-list '(
                      ;"5x5"
                      ;"blackbox"
                      ;"bubbles"
                      ;"dunnet"
                      ;"gomoku"
                      ;"hanoi"
                      ;"life"
                      ;"pong"
                      "snake"
                      "solitaire"
                      "tetris"
                      "zone"
                      ))
        (buf (get-buffer-create "*games*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (mapconcat #'identity games-list "\n"))
        (insert "\n"))
      (read-only-mode 1)
      (goto-char (point-min)))
    (switch-to-buffer buf)))

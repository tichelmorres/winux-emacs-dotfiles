(defvar la/pdf-viewer-processes (make-hash-table :test #'equal))

;;;###autoload
(defun la/latex-compile-and-open ()
  (interactive)
  (unless (buffer-file-name)
    (user-error "Buffer is not visiting a file."))
  (when (buffer-modified-p)
    (save-buffer))
  (let* ((tex-file  (buffer-file-name))
         (tex-dir   (file-name-directory tex-file))
         (base      (file-name-sans-extension tex-file))
         (pdf-file  (concat base ".pdf"))
         (engine    (cond ((executable-find "lualatex") "lualatex")
                          ((executable-find "pdflatex") "pdflatex")
                          (t (user-error "Neither lualatex nor pdflatex found on PATH."))))
         (cmd       (format "%s -interaction=nonstopmode -output-directory=%s %s"
                            engine
                            (shell-quote-argument tex-dir)
                            (shell-quote-argument tex-file)))
         (proc      (start-process-shell-command
                     "latex-compile" "*latex-compile*" cmd)))
    (message "Compiling with %s: %s." engine tex-file)
    (process-put proc 'pdf-file pdf-file)
    (set-process-sentinel
     proc
     (lambda (p _event)
       (let* ((pdf-file     (process-get p 'pdf-file))
              (pdf-exists   (file-exists-p pdf-file))
              (zath-proc    (gethash pdf-file la/pdf-viewer-processes))
              (zath-alive   (and zath-proc (process-live-p zath-proc))))
         (cond
          ((not pdf-exists)
           (message "Compilation failed — no PDF produced. See *latex-compile* for details."))
          (zath-alive
           (message "Recompiled successfully: %s." pdf-file))
          (t
           (let ((new-proc (start-process "zathura" nil "zathura" "-c"
                                          (expand-file-name "~/.config/zathura/latex")
                                          pdf-file)))
             (puthash pdf-file new-proc la/pdf-viewer-processes)))))))))

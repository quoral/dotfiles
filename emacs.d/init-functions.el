(defun custom-download-script (url filename)
  "Downloads an Elisp script, places it in ~/.emacs/other and then loads it"
 
  ;; Ensure the directory exists
  (unless (file-exists-p "~/.emacs.d/other")
    (make-directory "~/.emacs.d/other"))

  ;; Download file if it doesn't exist.
  (let ((file
         (concat "~/.emacs.d/" filename)))
    (unless (file-exists-p file)
      (url-copy-file url file))

    (load file)))

(defun custom-download-theme (url filename)
  "Downloads a theme through HTTP and places it in ~/.emacs.d/themes"

  ;; Ensure the directory exists
  (unless (file-exists-p "~/.emacs.d/themes")
    (make-directory "~/.emacs.d/themes"))

  ;; Adds the themes folder to the theme load path (if not already
  ;; there)
  (unless (member "~/.emacs.d/themes" custom-theme-load-path)
    (add-to-list 'custom-theme-load-path "~/.emacs.d/themes"))
 
  ;; Download file if it doesn't exist.

  (let ((file
         (concat "~/.emacs.d/themes/" filename)))
    (unless (file-exists-p file)
      (url-copy-file url file))))

     (eval-after-load 'rcirc
       '(defun-rcirc-command reconnect (arg)
          "Reconnect the server process."
          (interactive "i")
          (unless process
            (error "There's no process for this target"))
          (let* ((server (car (process-contact process)))
                 (port (process-contact process :service))
                 (nick (rcirc-nick process))
                 channels query-buffers)
            (dolist (buf (buffer-list))
              (with-current-buffer buf
                (when (eq process (rcirc-buffer-process))
                  (remove-hook 'change-major-mode-hook
                               'rcirc-change-major-mode-hook)
                  (if (rcirc-channel-p rcirc-target)
                      (setq channels (cons rcirc-target channels))
                    (setq query-buffers (cons buf query-buffers))))))
            (delete-process process)
            (rcirc-connect server port nick
                           rcirc-default-user-name
                           rcirc-default-full-name
                           channels))))

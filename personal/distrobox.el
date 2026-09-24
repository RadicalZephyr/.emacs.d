(use-package tramp
  :config
  (add-to-list 'tramp-default-user-alist '("podman" "^\\(?:dev\\|bwapi\\)$" "zefs"))
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

(defun radz-container--foreign-remote-p (path)
  "Non-nil if PATH is remote over some method other than podman."
  (let ((method (file-remote-p path 'method)))
    (and method (not (equal method "podman")))))

(defun radz-container-for-path (path alist)
  "Return the container ALIST maps PATH to, or nil.
ALIST maps directories to container names.  Both sides are compared
as true names, so symlinks like /home -> /var/home don't matter.
The longest matching directory wins.  A podman PATH is looked up by
its local name; any other remote PATH never matches."
  (unless (radz-container--foreign-remote-p path)
    (let ((target (file-name-as-directory (file-truename (file-local-name path))))
          best best-length)
      (dolist (entry alist)
        (let ((dir (file-name-as-directory (file-truename (car entry)))))
          (when (and (string-prefix-p dir target)
                     (or (null best-length) (> (length dir) best-length)))
            (setq best (cdr entry)
                  best-length (length dir)))))
      best)))

(defun radz-container-tramp-path (path container)
  "Return PATH as a TRAMP path into CONTAINER as the current user.
A podman PATH is re-targeted at CONTAINER; any other remote PATH is
returned unchanged."
  (if (radz-container--foreign-remote-p path)
      path
    (format "/podman:%s@%s:%s" (user-login-name) container (file-local-name path))))

(defcustom radz-container-directory-alist nil
  "Alist mapping directories to the podman container to open files in.
The longest directory containing a file wins.  Used by
`radz-find-file-in-container'."
  :type '(alist :key-type directory :value-type (string :tag "Container"))
  :group 'tramp)

(setopt radz-container-directory-alist
        '(("~/prog" . "dev")
          ("~/prog/bwapi" . "bwapi")))

(defun radz-container--podman (&rest args)
  "Run podman locally with ARGS and return its output lines."
  (let ((default-directory (expand-file-name "~/")))
    (apply #'process-lines "podman" args)))

(defun radz-container--ensure-running (container)
  "Start CONTAINER if it isn't running."
  (unless (equal (radz-container--podman "container" "inspect"
                                         "--format" "{{.State.Running}}" container)
                 '("true"))
    (message "Starting container %s..." container)
    (radz-container--podman "start" container)
    (message "Starting container %s...done" container)))

(defun radz-find-file-in-container (filename)
  "Visit FILENAME in the container `radz-container-directory-alist' maps it to.
Prompts for a container when no directory matches.  Remote files over
anything but podman are visited with plain `find-file'."
  (interactive
   (list (let ((default-directory (file-local-name default-directory)))
           (read-file-name "Find file in container: "))))
  (if (radz-container--foreign-remote-p filename)
      (find-file filename)
    (let* ((local (expand-file-name (file-local-name filename)))
           (container (or (radz-container-for-path local radz-container-directory-alist)
                          (completing-read
                           (format "Container for %s: " (abbreviate-file-name local))
                           (radz-container--podman "ps" "-a" "--format" "{{.Names}}")
                           nil t))))
      (radz-container--ensure-running container)
      (find-file (radz-container-tramp-path local container)))))

(global-set-key (kbd "C-c c c") #'radz-find-file-in-container)

(defun radz-container-local-name (path)
  "Return PATH without its podman TRAMP prefix.
Any other PATH is returned unchanged.  This is safe because every
container mounts the home directory at the same path."
  (if (equal (file-remote-p path 'method) "podman")
      (file-local-name path)
    path))

(defun radz-magit-status-locally (fn &optional directory &rest args)
  "Around advice for `magit-status' that runs it on the host.
Git over TRAMP is slow, and commit signing only works on the host."
  (interactive (lambda (spec)
                 (let ((default-directory (radz-container-local-name default-directory)))
                   (advice-eval-interactive-spec spec))))
  (let ((default-directory (radz-container-local-name default-directory)))
    (apply fn (and directory (radz-container-local-name directory)) args)))

(advice-add 'magit-status :around #'radz-magit-status-locally)

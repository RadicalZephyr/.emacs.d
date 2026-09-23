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

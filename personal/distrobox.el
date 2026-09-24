(defgroup radz-distrobox nil
  "Running tools in distroboxes."
  :group 'processes)

(defun radz-container-for-path (path alist)
  "Return the container ALIST maps PATH to, or nil.
ALIST maps directories to container names.  Both sides are compared
as true names, so symlinks like /home -> /var/home don't matter.
The longest matching directory wins.  A remote PATH never matches:
its processes don't run on the host."
  (unless (file-remote-p path)
    (let ((target (file-name-as-directory (file-truename path)))
          best best-length)
      (dolist (entry alist)
        (let ((dir (file-name-as-directory (file-truename (car entry)))))
          (when (and (string-prefix-p dir target)
                     (or (null best-length) (> (length dir) best-length)))
            (setq best (cdr entry)
                  best-length (length dir)))))
      best)))

(defcustom radz-container-directory-alist nil
  "Alist mapping directories to the distrobox their tools run in.
The longest directory containing a file wins.  Used by
`radz-distrobox-use-shims'."
  :type '(alist :key-type directory :value-type (string :tag "Container"))
  :group 'radz-distrobox)

(setopt radz-container-directory-alist
        '(("~/prog" . "dev")
          ("~/prog/bwapi" . "bwapi")))

(defconst radz-distrobox-shim-script
  (expand-file-name "bin/in-container" (file-name-directory (or load-file-name buffer-file-name)))
  "Script every shim links to.  It runs the tool in the shim's box.")

(defvar radz-distrobox-shims-directory
  (expand-file-name ".distrobox-shims" (file-name-directory (or load-file-name buffer-file-name)))
  "Directory holding one subdirectory of shims per box.")

(defcustom radz-distrobox-tools nil
  "Alist mapping each distrobox to the tools Emacs runs inside it.
Only these get shims, so anything else, git in particular, runs on
the host.  Call `radz-distrobox-sync-shims' after changing it."
  :type '(alist :key-type (string :tag "Box") :value-type (repeat (string :tag "Tool")))
  :group 'radz-distrobox)

(defun radz-distrobox-shim-directory (box)
  "Return the directory of shims for BOX."
  (file-name-as-directory (expand-file-name box radz-distrobox-shims-directory)))

(defun radz-distrobox-sync-shims ()
  "Make the shims in `radz-distrobox-shims-directory' match `radz-distrobox-tools'.
Only symlinks are removed, and a box's directory only once it's empty."
  (dolist (entry radz-distrobox-tools)
    (let ((dir (radz-distrobox-shim-directory (car entry))))
      (make-directory dir t)
      (dolist (tool (cdr entry))
        (let ((link (expand-file-name tool dir)))
          (unless (equal (file-symlink-p link) radz-distrobox-shim-script)
            (make-symbolic-link radz-distrobox-shim-script link t))))))
  (when (file-directory-p radz-distrobox-shims-directory)
    (dolist (dir (directory-files radz-distrobox-shims-directory t "\\`[^.]"))
      (when (file-directory-p dir)
        (let ((tools (cdr (assoc (file-name-nondirectory dir) radz-distrobox-tools))))
          (dolist (link (directory-files dir t "\\`[^.]"))
            (when (and (file-symlink-p link)
                       (not (member (file-name-nondirectory link) tools)))
              (delete-file link)))
          (unless (directory-files dir nil "\\`[^.]")
            (delete-directory dir)))))))

(setopt radz-distrobox-tools
        '(("dev" "rust-analyzer" "cargo" "rustfmt")
          ("bwapi" "cmake" "ctest" "ninja" "make" "clangd" "gdb")))

(radz-distrobox-sync-shims)

(defun radz-distrobox-path-with-shims (shims env)
  "Return a copy of the process environment ENV with SHIMS first on PATH."
  (let ((path (split-string (or (getenv-internal "PATH" env) "") path-separator t)))
    (setenv-internal (copy-sequence env) "PATH"
                     (string-join (cons shims (remove shims path)) path-separator)
                     t)))

(defun radz-distrobox-box-with-shims (directory)
  "Return the box that DIRECTORY maps to, if it has shims."
  (let ((box (radz-container-for-path directory radz-container-directory-alist)))
    (and (assoc box radz-distrobox-tools) box)))

(defun radz-distrobox-use-shims ()
  "Run this buffer's processes through the shims of its box, if any.
Sets `exec-path', which `make-process' and `executable-find' use, and
PATH, which shell commands like `compile' use."
  (when-let* ((box (radz-distrobox-box-with-shims default-directory)))
    (let ((shims (directory-file-name (radz-distrobox-shim-directory box))))
      (setq-local exec-path (cons shims (remove shims exec-path)))
      (setq-local process-environment
                  (radz-distrobox-path-with-shims shims process-environment)))))

(add-hook 'after-change-major-mode-hook #'radz-distrobox-use-shims)

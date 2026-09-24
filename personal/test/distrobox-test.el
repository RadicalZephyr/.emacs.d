;;; distrobox-test.el --- Tests for personal/distrobox.el  -*- lexical-binding: t; -*-

;; Run with:
;;   emacs -Q --batch -l ert -l ~/.emacs.d/personal/test/distrobox-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(load (expand-file-name "../distrobox.el" (file-name-directory (or load-file-name buffer-file-name))) nil t)

(defmacro radz-container-test--with-tree (&rest body)
  "Run BODY with `root' bound to a temp dir holding real/ and link -> real."
  (declare (indent 0))
  `(let ((root (file-name-as-directory (file-truename (make-temp-file "radz-container" t)))))
     (unwind-protect
         (progn
           (make-directory (expand-file-name "real/prog/bwapi" root) t)
           (make-directory (expand-file-name "real/programs" root) t)
           (make-symbolic-link (expand-file-name "real" root) (expand-file-name "link" root))
           ,@body)
       (delete-directory root t))))

(ert-deftest radz-container-for-path/longest-match-wins ()
  (radz-container-test--with-tree
    (let ((alist `((,(expand-file-name "real/prog" root) . "dev")
                   (,(expand-file-name "real/prog/bwapi" root) . "bwapi"))))
      (should (equal (radz-container-for-path (expand-file-name "real/prog/bwapi/main.rs" root) alist)
                     "bwapi"))
      (should (equal (radz-container-for-path (expand-file-name "real/prog/other/main.rs" root) alist)
                     "dev")))))

(ert-deftest radz-container-for-path/order-does-not-matter ()
  (radz-container-test--with-tree
    (let ((alist `((,(expand-file-name "real/prog/bwapi" root) . "bwapi")
                   (,(expand-file-name "real/prog" root) . "dev"))))
      (should (equal (radz-container-for-path (expand-file-name "real/prog/bwapi/main.rs" root) alist)
                     "bwapi")))))

(ert-deftest radz-container-for-path/matches-the-directory-itself ()
  (radz-container-test--with-tree
    (let ((alist `((,(expand-file-name "real/prog" root) . "dev"))))
      (should (equal (radz-container-for-path (expand-file-name "real/prog" root) alist) "dev"))
      (should (equal (radz-container-for-path (expand-file-name "real/prog/" root) alist) "dev")))))

(ert-deftest radz-container-for-path/whole-components-only ()
  (radz-container-test--with-tree
    (let ((alist `((,(expand-file-name "real/prog" root) . "dev"))))
      (should-not (radz-container-for-path (expand-file-name "real/programs/x.rs" root) alist)))))

(ert-deftest radz-container-for-path/symlinks-match-both-ways ()
  (radz-container-test--with-tree
    (should (equal (radz-container-for-path
                    (expand-file-name "real/prog/x.rs" root)
                    `((,(expand-file-name "link/prog" root) . "dev")))
                   "dev"))
    (should (equal (radz-container-for-path
                    (expand-file-name "link/prog/x.rs" root)
                    `((,(expand-file-name "real/prog" root) . "dev")))
                   "dev"))))

(ert-deftest radz-container-for-path/no-match-is-nil ()
  (radz-container-test--with-tree
    (should-not (radz-container-for-path
                 "/etc/hosts"
                 `((,(expand-file-name "real/prog" root) . "dev"))))))

(ert-deftest radz-container-for-path/remote-never-matches ()
  (radz-container-test--with-tree
    (dolist (prefix '("/ssh:server:" "/podman:zefs@dev:"))
      (should-not (radz-container-for-path
                   (concat prefix (expand-file-name "real/prog/x.rs" root))
                   `((,(expand-file-name "real/prog" root) . "dev")))))))

;; Loading distrobox.el syncs the real shims, just like starting Emacs.
;; The tests below bind the shims directory to a temp dir.

(defmacro radz-distrobox-test--with-shims (&rest body)
  "Run BODY with the shims directory and allowlist bound to temp values."
  (declare (indent 0))
  `(let* ((radz-distrobox-shims-directory (make-temp-file "radz-shims" t))
          (radz-distrobox-shells-directory (make-temp-file "radz-shells" t))
          (radz-distrobox-tools nil))
     (unwind-protect
         (progn ,@body)
       (delete-directory radz-distrobox-shims-directory t)
       (delete-directory radz-distrobox-shells-directory t))))

(defun radz-distrobox-test--shims (box)
  "Return BOX's shims as a sorted list of (TOOL . TARGET)."
  (let ((dir (radz-distrobox-shim-directory box)))
    (when (file-directory-p dir)
      (mapcar (lambda (f) (cons f (file-symlink-p (expand-file-name f dir))))
              (directory-files dir nil "\\`[^.]")))))

(ert-deftest radz-distrobox-shim-directory/is-under-shims-directory ()
  (let ((radz-distrobox-shims-directory "/shims"))
    (should (equal (radz-distrobox-shim-directory "dev") "/shims/dev/"))))

(ert-deftest radz-distrobox-sync-shims/links-each-tool-to-the-script ()
  (radz-distrobox-test--with-shims
    (setq radz-distrobox-tools '(("dev" "cargo" "rustfmt") ("bwapi" "clang")))
    (radz-distrobox-sync-shims)
    (should (equal (radz-distrobox-test--shims "dev")
                   `(("cargo" . ,radz-distrobox-shim-script)
                     ("rustfmt" . ,radz-distrobox-shim-script))))
    (should (equal (radz-distrobox-test--shims "bwapi")
                   `(("clang" . ,radz-distrobox-shim-script))))))

(ert-deftest radz-distrobox-sync-shims/is-idempotent ()
  (radz-distrobox-test--with-shims
    (setq radz-distrobox-tools '(("dev" "cargo")))
    (radz-distrobox-sync-shims)
    (radz-distrobox-sync-shims)
    (should (equal (radz-distrobox-test--shims "dev")
                   `(("cargo" . ,radz-distrobox-shim-script))))))

(ert-deftest radz-distrobox-sync-shims/repoints-a-stale-link ()
  (radz-distrobox-test--with-shims
    (setq radz-distrobox-tools '(("dev" "cargo")))
    (make-directory (radz-distrobox-shim-directory "dev") t)
    (make-symbolic-link "/old/script" (expand-file-name "cargo" (radz-distrobox-shim-directory "dev")))
    (radz-distrobox-sync-shims)
    (should (equal (radz-distrobox-test--shims "dev")
                   `(("cargo" . ,radz-distrobox-shim-script))))))

(ert-deftest radz-distrobox-sync-shims/removes-dropped-tools-and-boxes ()
  (radz-distrobox-test--with-shims
    (setq radz-distrobox-tools '(("dev" "cargo" "rustfmt") ("bwapi" "clang")))
    (radz-distrobox-sync-shims)
    (setq radz-distrobox-tools '(("dev" "cargo")))
    (radz-distrobox-sync-shims)
    (should (equal (radz-distrobox-test--shims "dev")
                   `(("cargo" . ,radz-distrobox-shim-script))))
    (should-not (file-exists-p (radz-distrobox-shim-directory "bwapi")))))

(ert-deftest radz-distrobox-sync-shims/leaves-other-files-alone ()
  (radz-distrobox-test--with-shims
    (let ((dir (radz-distrobox-shim-directory "gone")))
      (make-directory dir t)
      (write-region "" nil (expand-file-name "notes" dir))
      (radz-distrobox-sync-shims)
      (should (file-exists-p (expand-file-name "notes" dir))))))

(ert-deftest radz-distrobox-path-with-shims/prepends-once ()
  (let ((env '("HOME=/home/zefs" "PATH=/usr/bin:/shims:/bin")))
    (should (equal (radz-distrobox-path-with-shims "/shims" env)
                   '("HOME=/home/zefs" "PATH=/shims:/usr/bin:/bin")))
    (should (equal env '("HOME=/home/zefs" "PATH=/usr/bin:/shims:/bin")))))

(ert-deftest radz-distrobox-path-with-shims/adds-missing-path ()
  (should (equal (getenv-internal "PATH" (radz-distrobox-path-with-shims "/shims" '("HOME=/h")))
                 "/shims")))

(defmacro radz-distrobox-test--in-buffer (directory &rest body)
  "Run BODY in a temp buffer whose `default-directory' is DIRECTORY."
  (declare (indent 1))
  `(with-temp-buffer
     (setq default-directory ,directory)
     ,@body))

(ert-deftest radz-distrobox-use-shims/sets-exec-path-and-path ()
  (radz-container-test--with-tree
    (let* ((radz-container-directory-alist `((,(expand-file-name "real/prog" root) . "dev")))
           (radz-distrobox-tools '(("dev" "cargo")))
           (radz-distrobox-shims-directory "/shims")
           (exec-path '("/usr/bin"))
           (process-environment '("PATH=/usr/bin")))
      (radz-distrobox-test--in-buffer (expand-file-name "real/prog/" root)
        (radz-distrobox-use-shims)
        (radz-distrobox-use-shims)
        (should (equal exec-path '("/shims/dev" "/usr/bin")))
        (should (equal (getenv "PATH") "/shims/dev:/usr/bin")))
      (should (equal exec-path '("/usr/bin"))))))

(ert-deftest radz-distrobox-use-shims/leaves-other-buffers-alone ()
  (radz-container-test--with-tree
    (let ((radz-container-directory-alist `((,(expand-file-name "real/prog" root) . "dev")
                                            (,(expand-file-name "real/programs" root) . "bare")))
          (radz-distrobox-tools '(("dev" "cargo")))
          (radz-distrobox-shims-directory "/shims"))
      (dolist (dir (list "/etc/"
                         (expand-file-name "real/programs/" root)
                         (concat "/podman:zefs@dev:" (expand-file-name "real/prog/" root))))
        (radz-distrobox-test--in-buffer dir
          (radz-distrobox-use-shims)
          (should-not (local-variable-p 'exec-path))
          (should-not (local-variable-p 'process-environment)))))))

(ert-deftest radz-distrobox-sync-shims/gives-each-box-a-shell ()
  (radz-distrobox-test--with-shims
    (setq radz-distrobox-tools '(("dev" "cargo") ("bwapi" "cmake")))
    (radz-distrobox-sync-shims)
    (should (equal (file-symlink-p (radz-distrobox-shell "dev")) radz-distrobox-shim-script))
    (should (equal (file-symlink-p (radz-distrobox-shell "bwapi")) radz-distrobox-shim-script))
    (should-not (member "sh" (mapcar #'car (radz-distrobox-test--shims "dev"))))
    (setq radz-distrobox-tools '(("dev" "cargo")))
    (radz-distrobox-sync-shims)
    (should-not (file-exists-p (radz-distrobox-shell "bwapi")))))

(ert-deftest radz-distrobox-shell-in-box/binds-the-box-shell ()
  (radz-container-test--with-tree
    (let ((radz-container-directory-alist `((,(expand-file-name "real/prog" root) . "dev")))
          (radz-distrobox-tools '(("dev" "cargo")))
          (radz-distrobox-shells-directory "/shells")
          (shell-file-name "/bin/sh"))
      (radz-distrobox-test--in-buffer (expand-file-name "real/prog/" root)
        (should (equal (radz-distrobox-shell-in-box (lambda (x) (list x shell-file-name)) 1)
                       '(1 "/shells/dev/sh"))))
      (radz-distrobox-test--in-buffer (expand-file-name "real/programs/" root)
        (should (equal (radz-distrobox-shell-in-box (lambda () shell-file-name))
                       "/bin/sh"))))))

(ert-deftest radz-distrobox-typed-shell-in-box/only-for-typed-commands ()
  (radz-container-test--with-tree
    (let ((radz-container-directory-alist `((,(expand-file-name "real/prog" root) . "dev")))
          (radz-distrobox-tools '(("dev" "cargo")))
          (radz-distrobox-shells-directory "/shells")
          (shell-file-name "/bin/sh"))
      (radz-distrobox-test--in-buffer (expand-file-name "real/prog/" root)
        (let ((this-command 'shell-command))
          (should (equal (radz-distrobox-typed-shell-in-box (lambda () shell-file-name))
                         "/shells/dev/sh")))
        (let ((this-command 'projectile-find-file))
          (should (equal (radz-distrobox-typed-shell-in-box (lambda () shell-file-name))
                         "/bin/sh")))))))

;;; distrobox-test.el ends here

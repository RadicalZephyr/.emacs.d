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

(ert-deftest radz-container-for-path/podman-path-uses-local-name ()
  (radz-container-test--with-tree
    (should (equal (radz-container-for-path
                    (concat "/podman:zefs@bwapi:" (expand-file-name "real/prog/x.rs" root))
                    `((,(expand-file-name "real/prog" root) . "dev")))
                   "dev"))))

(ert-deftest radz-container-for-path/other-remote-never-matches ()
  (radz-container-test--with-tree
    (should-not (radz-container-for-path
                 (concat "/ssh:server:" (expand-file-name "real/prog/x.rs" root))
                 `((,(expand-file-name "real/prog" root) . "dev"))))))

(ert-deftest radz-container-tramp-path/local-path ()
  (should (equal (radz-container-tramp-path "/home/zefs/prog/x.rs" "dev")
                 (format "/podman:%s@dev:/home/zefs/prog/x.rs" (user-login-name)))))

(ert-deftest radz-container-tramp-path/podman-path-is-retargeted ()
  (should (equal (radz-container-tramp-path "/podman:root@bwapi:/home/zefs/prog/x.rs" "dev")
                 (format "/podman:%s@dev:/home/zefs/prog/x.rs" (user-login-name)))))

(ert-deftest radz-container-tramp-path/other-remote-is-unchanged ()
  (should (equal (radz-container-tramp-path "/ssh:server:/etc/hosts" "dev")
                 "/ssh:server:/etc/hosts")))

(ert-deftest radz-container-local-name/podman-path-becomes-local ()
  (should (equal (radz-container-local-name "/podman:zefs@dev:/home/zefs/prog/")
                 "/home/zefs/prog/")))

(ert-deftest radz-container-local-name/other-paths-are-unchanged ()
  (should (equal (radz-container-local-name "/home/zefs/prog/") "/home/zefs/prog/"))
  (should (equal (radz-container-local-name "/ssh:server:/etc/") "/ssh:server:/etc/")))

(ert-deftest radz-magit-status-locally/localizes-directory-and-default-directory ()
  (let ((default-directory "/podman:zefs@dev:/home/zefs/prog/")
        seen)
    (radz-magit-status-locally
     (lambda (&optional directory cache) (setq seen (list directory default-directory cache)))
     "/podman:zefs@dev:/home/zefs/other/" 'cache)
    (should (equal seen '("/home/zefs/other/" "/home/zefs/prog/" cache)))))

(ert-deftest radz-magit-status-locally/nil-directory-stays-nil ()
  (let ((default-directory "/podman:zefs@dev:/home/zefs/prog/")
        seen)
    (radz-magit-status-locally
     (lambda (&optional directory) (setq seen (list directory default-directory))))
    (should (equal seen '(nil "/home/zefs/prog/")))))

;; Loading distrobox.el syncs the real shims, just like starting Emacs.
;; The tests below bind the shims directory to a temp dir.

(defmacro radz-distrobox-test--with-shims (&rest body)
  "Run BODY with the shims directory and allowlist bound to temp values."
  (declare (indent 0))
  `(let* ((radz-distrobox-shims-directory (make-temp-file "radz-shims" t))
          (radz-distrobox-tools nil))
     (unwind-protect
         (progn ,@body)
       (delete-directory radz-distrobox-shims-directory t))))

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

;;; distrobox-test.el ends here

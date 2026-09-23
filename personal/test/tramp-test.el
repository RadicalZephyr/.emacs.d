;;; tramp-test.el --- Tests for personal/tramp.el  -*- lexical-binding: t; -*-

;; Run with:
;;   emacs -Q --batch -l ert -l ~/.emacs.d/personal/test/tramp-test.el -f ert-run-tests-batch-and-exit

(require 'ert)
(load (expand-file-name "../tramp.el" (file-name-directory (or load-file-name buffer-file-name))) nil t)

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

;;; tramp-test.el ends here

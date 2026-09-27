# 2026-09-26: Rust LSP and the `/var/home` symlink

## Three symptoms, one cause

- No squiggles while typing unless `lsp-diagnostics-mode` was off. Code
  actions offered no fixes. Every Rust file asked to import its project root.
- `/home` is a symlink to `/var/home`. Buffers visited `/home/...`, but
  rust-analyzer (through the box shim), cargo and projectile all report
  `/var/home/...`. lsp-mode compares paths with `expand-file-name`, which
  doesn't resolve symlinks (`lsp-f-canonical`, `lsp--path-to-uri-1`).
- Diagnostics were stored under paths no buffer had. The squiggles with
  `lsp-diagnostics-mode` off came from flycheck's own `rust-cargo` checker,
  which lsp-mode doesn't know about, so code actions had nothing to fix.
- Imported roots came from projectile, which does resolve symlinks, so
  they were saved as `/var/home/...` and never matched a `/home/...` buffer.

## Fix: `find-file-visit-truename`

- Buffers visit `/var/home/...` now, so everything agrees.
- Cost: no `~` in buffer names, because `$HOME` is `/home/zefs`.
- Not `directory-abbrev-alist` to get `~` back. Emacs applies it while
  working out `buffer-file-name`, so the name goes back to `/home/...`.
  Tested in `emacs -Q --batch`.
- Not a path mapping in the rust-analyzer client. That fixes diagnostics,
  but projectile would still disagree with buffers about project roots.

## Cleanup in `personal/rust.el`

- `C-c C-l d/e/r` in `rust-mode-map` were shadowed by `lsp-ui-mode-map`,
  so they were never used. Removed. `lsp-rust-analyzer-expand-macro` is
  `M-x` only now.
- `C-c C-c C-e` was shadowed by `cargo-minor-mode`'s `cargo-process-bench`.
  File expand is `C-c C-c e` now.
- Dropped settings prelude-rust already sets: format on save, proc macros,
  `cargo-minor-mode` on `rust-mode-hook`, the `executable-make-...`
  hook removal. They now depend on the module staying loaded.
- `lsp-rust-analyzer-cargo-load-out-dirs-from-check` was an obsolete alias
  for a setting that defaults to `t`. Dropped.
- Removed the `/podman:` roots left over from TRAMP with
  `lsp-workspace-folders-remove` in the running Emacs. Editing
  `.lsp-session-v1` directly gets overwritten when lsp-mode next saves it.

## Traps

- Buffers restored from a desktop file came up without `cargo-minor-mode`.
  Opening the file fresh is fine. Not looked into.
- `cargo-minor-mode` now runs after `tree-sitter-mode` and
  `tree-sitter-hl-mode` in `rust-mode-hook`. If an earlier hook function
  errors, it gets skipped.

## Open

- Swapping `lsp` for `lsp-deferred` only works because `(require
  'rust-mode)` runs prelude's `with-eval-after-load` block before the
  `remove-hook`. Fragile, but left as is.

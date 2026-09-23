# 2026-09-23: rust-analyzer over TRAMP, and `C-c c c`

## Why rust-analyzer wasn't found

- `/podman:dev:` runs `podman exec` as root, with `HOME=/home/zefs`. Rustup and
  rust-analyzer running as root would have left root-owned files in `~/.cargo`,
  `~/.rustup` and `target/`.
- TRAMP builds the remote PATH from `tramp-remote-path`. The local `exec-path`
  doesn't matter.
- lsp-mode starts the server with a non-login, non-interactive `bash -c`, so it
  reads neither `.bashrc` nor `.bash_profile`. Cargo's env is only sourced from
  `.bash_profile` and `.profile` anyway.
- Fixes: a `tramp-default-user-alist` entry for `dev`/`bwapi` → `zefs`, plus
  `tramp-own-remote-path`, which asks a login `sh -l` for PATH and so picks up
  `~/.profile`. The UI freeze went away along with these fixes; it was lsp-mode
  waiting on a server that had already died.
- `/distrobox:` exists in Emacs 30.2 but only after `(tramp-enable-method
  "distrobox")`. Staying on `/podman:` because the distrobox method has
  `tramp-direct-async` disabled.

## `C-c c c`: find-file into the project's container

Workflow: `C-c c c` opens the first file of a session in the right container,
then `C-x C-f` stays on that connection.

- `radz-container-directory-alist` maps directories to container names:
  `~/prog` → `dev`, `~/prog/bwapi` → `bwapi`. The longest match wins, matching
  is by whole directory components, and both sides are compared as true names
  (Bazzite's `/home` is a symlink to `/var/home`).
- The prompt starts from the local equivalent of `default-directory`. Local and
  `/podman:` paths follow the alist, even if you typed a different container.
  To override, use `C-x C-f`. Any other TRAMP method (`/ssh:` etc.) goes to
  plain `find-file`.
- Always connects as `(user-login-name)`, written into the path, so it never
  depends on `tramp-default-user-alist`.
- No match: pick from `podman ps -a`. Not remembered; the alist stays the only
  source of mappings. Remembering per session, keyed on the project root, is a
  small addition if prompting turns out to be common.
- A stopped container gets a synchronous `podman start`, reported in the echo
  area.
- Key: `C-c c` is my prefix, so the command goes under it. `C-c c f` is
  `desktop-change-dir`. `C-c C-x C-f` was out: `C-c C-<ctrl>` is reserved for
  major modes, and Org binds it to `org-emphasize`.
- Pure functions (`radz-container-for-path`, `radz-container-tramp-path`) have
  ERT tests in `personal/test/`. The command and the podman side are checked by
  hand.

# 2026-09-26: tools in distroboxes through shims, not TRAMP

## Why TRAMP went

- Opening source over `/podman:` put Magit on TRAMP too. It was slow even
  for staging, and signing failed in the box, because `gpg.ssh.program`
  points at the linuxbrew `op-ssh-sign`, which the box can't see.
- The home directory is mounted at the same path in every box, so the files
  never needed TRAMP. Only the tools' processes need to run in the box.
- Now files open locally, and buffers under a directory in
  `radz-container-directory-alist` get their box's shims first on a
  buffer-local `exec-path` and PATH. That's enough for lsp-mode, rustfmt,
  flycheck and `compile`. Magit and git stay on the host because git never
  gets a shim.
- `C-c c c`, the TRAMP config, the remote rust-analyzer client and the
  `magit-status` advice are gone.
- Aside: the 1Password agent socket is reachable from the box, so signing
  in a box would work with `ssh-keygen` and the agent. Not needed now.

## Our shim, not `distrobox-export`

- `distrobox-export` wrappers get almost everything right: stdin, exit
  status, PATH, `$PWD` (Emacs sets it for children) and pty output. They
  also handle being called from another box.
- They don't stop the tool when the host-side client dies. `podman exec`
  doesn't forward signals. So `C-c C-k` on a compile, a flycheck re-check
  or `kill-buffer` all left `cargo` running in the box, holding the target
  dir lock. So did SIGKILL of Emacs with rust-analyzer. lsp-mode's normal
  shutdown is fine, even with rust-analyzer mid-load on Bevy.
- `personal/bin/in-container` is the export's three cases (host, same box,
  other box) plus a watchdog. Boxes share the host's PID namespace, so the
  box polls the client's host PID and kills the tool's process group
  (`setsid`) once it's gone. Tested: SIGKILL/SIGINT/SIGTERM, children too.
- On the host the shim takes itself off PATH before entering, so
  rust-analyzer's own `cargo` calls don't go back through it. The same-box
  case is only a fallback.
- Cost is a flat ~0.3s per call, the same as `distrobox-enter`.

## Traps

- `sh -l` under plain `podman exec` eats stdin. `DISPLAY` and friends are
  unset, so `/etc/profile.d/distrobox_profile.sh` calls `host-spawn`, which
  reads stdin. rustfmt got nothing and printed nothing, exit 0, which with
  format-on-save means an empty file. `distrobox-enter` passes the host env
  through, so it never happens there.
- A background job's stdin is `/dev/null` *before* explicit redirects apply,
  so `"$@" <&0 &` doesn't help. Save it to fd 3 first.
- If a box doesn't exist, `distrobox-enter` asks whether to create it and
  reads the answer from stdin. That would eat the first LSP message. Not
  guarded; it needs a stale allowlist entry.
- `emacs -Q` skips `early-init.el`, so `LSP_USE_PLISTS` is unset and the
  plist-compiled lsp-mode sends payloads rust-analyzer rejects. Set it when
  testing. lsp-mode also doesn't work in `--batch`; use a throwaway
  `--daemon=<name>`.

## Allowlist, not discovery

- `radz-distrobox-tools` lists what *Emacs launches* per box. What cmake
  and ninja call resolves inside the box, so compilers don't need shims.
- Discovering tools from `dnf repoquery --userinstalled` looked possible
  but was wrong both ways: distrobox's setup counts as user-installed, git
  included, and `gcc`/`cc`/`ld` come from dependencies, so it misses them.

## Shell commands

- `compile` runs its command in a host shell, so `cmake --build build &&
  ./build/app` would build in the box and run the app on the host.
  `compile`, `recompile`, `M-!` and `M-&` now use an `sh` shim from
  `personal/.distrobox-shells/`, kept off `exec-path`.
- Not a buffer-local `shell-file-name`: projectile indexing and rg would
  have gone into the box, and `dev` has no `rg`.
- `shell-command-to-string` calls `shell-command`, so that advice only
  applies when `this-command` is `M-!` or `M-&`. `compile` needs no check:
  packages call `compilation-start`.

## Open

- `M-x gdb` and clangd in `bwapi` are untested. `setsid` drops the
  controlling terminal, which gud might mind.
- Left `lsp-enable-file-watchers` off: rust-analyzer watches files itself,
  and lsp-mode's watchers prompt on a Bevy-sized tree.

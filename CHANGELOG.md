# Changelog

Notable changes to reed. Dates are when the work landed, not when it was written up.

The format is loosely [Keep a Changelog](https://keepachangelog.com). reed is pre-1.0: minor versions may
change behaviour, and anything listed under *Unreleased* has not shipped in a binary yet.

## Unreleased

### Added
- `reed doctor` — one screen that says why it isn't working: this binary, the state directory, `$HOME`, the
  service, the daemon, the control protocol, Tailscale, your workspaces and every machine you push to.
- `--json` on every read command, three meaningful exit codes, progress on anything over a second, and
  colour decided per stream so `reed push > log` still shows you something.
- `reed push --dry-run`, which is the real push with the bytes dropped rather than an estimate.
- `reed dismiss` — close a branch you are never going to merge.

### Fixed
- **Upgrading reed no longer breaks `reed merge` on that machine.** A daemon whose binary was replaced
  underneath it now says so and names the fix, instead of reporting that something unknown holds its port.
- **Relative symlinks now resolve on Windows.** Every `.bin` shim in a transferred `node_modules` was
  arriving and pointing at nothing.
- **A build is only current for the lockfile it was made from.** A machine that receives a new lockfile
  without installing is told to install, rather than reporting healthy while missing a dependency.
- Forking a workspace that is being written to no longer fails on Windows.
- The stat cache now sees a tmp-file-plus-rename rewrite on Windows, where NTFS restores both timestamps.

## 0.1.0

First public release.

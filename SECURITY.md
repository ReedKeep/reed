# Security

## Reporting

**Please don't open a public issue for a security problem.**

Use GitHub's [private vulnerability reporting](../../security/advisories/new) on this repository. It goes
straight to us and stays private until there's a fix.

Tell us what you can — what you did, what happened, and what you expected. A reproduction is welcome and not
required; a clear description of the shape of the problem is often enough.

We'll acknowledge within **72 hours** and tell you what we think the impact is and roughly when a fix lands.
If we disagree about severity we'll say so and why, rather than going quiet.

## What we care most about

reed moves your source code between your machines and writes to your disk. In rough order of how badly we
want to hear about it:

1. **Anything that writes outside the workspace.** A path that escapes the folder it was supposed to land
   in, through any route — a name, a symlink, a component in the middle of a path, a rename.
2. **Anything that loses data.** Content that was recorded and can no longer be materialised, or a delete
   that propagates when it shouldn't.
3. **Anything that reaches the daemon without the right token**, or that makes the daemon hand its token to
   something that isn't reed.
4. **Anything that makes one machine's limitation into another machine's edit** — a machine that can't
   express a property publishing a claim about it.
5. **Resource exhaustion from a peer** — a small input that costs a large amount of memory, disk or time.

## The trust model, stated plainly

- **Your tailnet is the boundary.** reed does not implement its own transport security. Machines on your
  tailnet that you have linked can push into your store; Tailscale's ACLs are the control, and that is a real
  decision you're making. Off-tailnet, a token is required.
- **A receiver that creates folders where a sender asks is a write primitive.** Destination paths are
  home-relative and validated on the receiving side; a sender cannot name a path outside your home, and it
  cannot reach one through a symlink either.
- **The state directory is `0700`** and holds your content store, your history and the daemon's token.
  `reed doctor` checks and reports the mode; it deliberately does not silently repair it.
- **Nothing leaves your machines.** No telemetry, no phone-home, no account.

## How the binaries reach you

Stated here rather than on the front page, because it is the whole picture or it is misleading:

- Every release publishes a `SHA256SUMS` generated from the bytes that were uploaded, and both installers
  refuse a download whose hash is not in it.
- The **macOS** build is signed with an Apple Developer ID and notarised by Apple.
- The **Linux** and **Windows** builds are **not** code-signed. On those two, the checksum is the only thing
  standing between you and whatever arrived.
- Releases are cut by hand from a machine with a person at it. No credential of any kind — signing key,
  notarisation password or release token — lives in this repository, in its history, or in CI.

## Supported versions

reed is pre-1.0 and moves quickly. Fixes land on the latest release; there are no backports yet.

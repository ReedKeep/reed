# Changelog

## 0.1.2 — 2026-08-08

### `reed update`

One command, and you are on the newest release.

```sh
reed update            # take it
reed update --check    # is there one? changes nothing
```

It downloads through the same installer the README tells you to pipe into a shell — same checksum list, same
verification — so there is one implementation of *"get the bytes and prove they are the right bytes"* rather
than two. And it does the part an installer cannot: **it restarts the service**, because replacing the file
does not change the running process. On unix the daemon keeps the old inode and goes on running the old code
silently for as long as it lives, which is the worst of both — a terminal reporting the new version and a
machine behaving like the old one.

Three things it will not do:

- **Overwrite a Homebrew install.** That would leave the Cellar and the manifest describing a version that is
  no longer there. It says `brew upgrade reed` instead.
- **Repoint your service at a different copy.** There is one reed service per user, so a `reed update` run
  from a second copy would otherwise stop the real service and reinstall it pointing at that second copy.
- **Leave your machine not syncing.** The service goes back up whether or not the update succeeded.

On Windows it parks the running image with a rename first, because Windows locks a running `.exe` against
being overwritten but not against being renamed.

### Also

- `install.sh` now says when what it installed is **shadowed by another `reed` earlier on your PATH**. Seen
  on a real box: it printed `installed reed 0.1.1` while `reed --version` answered `0.0.1`, because a stale
  copy in `/usr/local/bin` came first. Every symptom after that points at the product instead of the PATH.
- `reed doctor` no longer runs a long machine name into its message
  (`gunna-s-macbook-air100.118.218.123:7380`).

## 0.1.1 — 2026-08-08

**Three fixes, all found by using reed on three real machines rather than by testing it.** If you have pushed
a folder to another computer, upgrade: two of these are about your machines quietly disagreeing about what a
folder contains.

### Work done on the receiving machine now travels back

Push a folder to another computer, then delete a file **there**, and the two machines used to diverge for good:
the sender said `already has it` and `up to date`, the receiver said `in sync`, and the folder was missing
files on one of them. **Both reports were true and neither machine could learn anything else.**

`sent: 0` really does mean *"they hold every object this tree names"* — deleting a file never removes an
object from a content-addressed store, so that stays true for ever. And the receiver had no device record for
its sender, so its own work had nowhere to go.

Now a machine that receives a push **registers whoever sent it**, and a deletion or an edit made over there
comes back on its own. Measured: two of three files deleted on the far machine, both folders identical again,
with nothing typed.

### A push says when the far machine has moved on

`already has it` is now reserved for when that is the whole story. When the other machine has recorded work of
its own:

```
box            has work of its own — nothing was sent
               note: box has recorded changes of its own that this state does not contain — an edit,
                     or a deletion. Nothing was overwritten on either machine.
                     see it here:  reed pull box
```

### The picker's checkboxes now decide where your folder goes

Unticking a machine in `reed push` used to change only that one push. Everything you had *ever* pushed that
folder to kept receiving it automatically, so a machine you had just unticked could get the file seconds
later. The ticks are now read from — and written back to — the actual subscription, and a row that already
receives the folder says so.

- **`reed stop MACHINE`** — the same thing without the picker. Per folder; nothing is deleted on either
  machine, its other folders keep syncing, and `reed push MACHINE` resumes.
- **`reed devices`** now lists which folders each machine receives, which is the line that explains what the
  daemon does next.
- Stopping *this machine → that one* does not stop *that one → this machine*.

### Also

- `reed pull` records the machine you pulled from, so your work can reach it too.
- The hello frame carries a callback port and tolerates fields it does not know, so future versions can add
  one without every machine upgrading on the same day. Older peers still work.

---

## 0.1.0 — 2026-08-07

First public release. macOS (universal), Linux x86_64 and aarch64, Windows x86_64. Signed with a Developer ID
and notarised by Apple.

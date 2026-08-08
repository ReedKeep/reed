<div align="center">

<!-- The white mark on a dark theme, the black one on a light theme. GitHub honours prefers-color-scheme
     inside <picture>, and the <img> is the fallback for anything that does not. -->
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/reed-on-dark.svg">
  <img src="assets/reed-on-light.svg" alt="reed" width="200" height="200">
</picture>

**One folder. Every machine you own. Nothing to think about.**

> ### ⚠️ &nbsp;reed is **not** on npm or npx
>
> There is no `npm install reed` and no `npx reed`. Anything by that name on npm is **not us**.
> Install with one of the commands below — those are the only places reed comes from.

[What you need](#what-you-need) · [Install](#install) · [60 seconds](#60-seconds) · [How it works](#how-it-works) · [Why it's different](#why-its-different)

</div>

---

You edit on your laptop. It's on your desktop and your Linux box before you've alt-tabbed.

Not a copy you have to remember to make. Not a folder that silently overwrites your work to make two
machines agree, either — when you've both been editing, the other machine's work arrives as **something you
look at first**, and you take it when you're ready.

No cloud. No account. No server we run. Your machines talk to each other.

Measured today, between a MacBook Air and an Ubuntu box over Tailscale, with nothing typed after the save:

```
mac → linux   2.8s          linux → mac   2.3s
```

## What you need

Three things, and the first one is the one that matters.

### 1 · Tailscale, on every machine, signed in as you

**This is not optional and it is not a suggestion — it is how reed works at all.**

reed has no server. There is no account to make and nothing of yours passes through us, because there is no
"us" in the path: your machines open a connection directly to each other. Something has to give them a way
to find each other and a way to know who they're talking to, and that something is
**[Tailscale](https://tailscale.com)**.

It has to be **the same tailnet and the same login on every machine.** That single fact is what makes the
whole thing configuration-free: when a machine receives a push, it asks Tailscale *"whose machine is
this?"* — and a machine owned by **you** needs nothing typed, no key exchanged, no token pasted. A machine
owned by anybody else is refused before a byte moves.

Free for personal use, and installing it is the only setup step that isn't `reed`.

```sh
tailscale status      # every machine you want reed on should be in this list
```

> **Not on a tailnet?** There is a manual path — `reed link NAME --addr HOST:PORT --token TOK` — where you
> supply the address and a shared secret yourself. It works, and it is a fallback rather than the product:
> you are doing by hand the two things Tailscale was doing for you.

### 2 · Port 7380, reachable between them

reed listens on **7380**. Over a tailnet that just works — Tailscale carries it. If you have a firewall of
your own between two machines, that's the one to let through.

### 3 · A supported machine, and somewhere to put things

macOS (12+, Intel or Apple Silicon), Linux x86_64 (glibc 2.31+), or Windows 10/11 x86_64. reed keeps its
history in `~/.reed`, so that has to be writable and have room — a workspace's history is roughly the size of
the workspace plus its changes.

**Linux on ARM is not built yet.** The code is portable and there is simply no machine here to build it on;
`cargo install --path crates/reed` works if you have the source.

**Not required:** node, npm, git, Docker, a package manager, or anything else. reed is one binary.

> Every one of these is checked for you. Run **`reed doctor`** and it says which of them is wrong, in one
> screen, with the thing to do about it.

## Install

**macOS · Linux**

```sh
curl -fsSL https://raw.githubusercontent.com/ReedKeep/reed/main/install.sh | sh && reed up
```

**Homebrew**

```sh
brew install ReedKeep/reed/reed && reed up
```

**Windows**

```powershell
irm https://raw.githubusercontent.com/ReedKeep/reed/main/install.ps1 | iex; reed up
```

One line, and `reed up` is the only thing you ever run per machine — it starts at login and survives a
reboot. **Upgrading later is one word:**

```sh
reed update
```

It takes the newest release, (Installed with Homebrew? It will point you at `brew upgrade reed`,
which is brew's job rather than reed's.)

You can read [`install.sh`](install.sh) before you pipe it into a shell. It's short, and it checks the
SHA-256 of everything it downloads against a published list before a byte is written to your disk. The macOS
build is signed with an Apple Developer ID and notarised, so Gatekeeper lets it run without argument.

## 60 seconds

On the machine that has the folder:

```sh
cd ~/code/my-project
reed make       # this folder is now a universal folder
reed push       # pick a machine, press enter
```

It's already on the other machine, at `~/reed/my-project`, with **nothing configured over there**.

After that nobody types anything. Save a file and it's gone. Turn a machine off, work against it, turn it
back on — measured at **16 seconds** from wake to caught up.

### When you've both been editing

```sh
reed peers            # mini   47 files changed, +812 −190
reed diff mini        # read it, file by file
reed merge mini       # take it
```

Three-way merge against the shared ancestor, conflicts named rather than guessed, and the undo printed
before it runs. Every version is kept for 30 days, so `reed restore` puts the folder back the way it was
this morning.

## The whole thing, in six commands

| | |
|---|---|
| `reed up` | turn it on — starts at login, survives a reboot |
| `reed make` | make the folder you're in a universal folder |
| `reed machines` | your machines, straight from Tailscale |
| `reed push` | send this folder to one of them |
| `reed peers` | whose work is waiting for you |
| `reed merge` | take it |

That's the whole product. Four more you'll want eventually:

| | |
|---|---|
| `reed status` | the dashboard — what's here, what's waiting, who's behind |
| `reed doctor` | why it isn't working, in one screen, with the thing to do |
| `reed stop NAME` | stop sending **this** folder to that machine. Nothing there is deleted |
| `reed update` | put this machine on the newest release |

`reed help` is everything else.

## How it works

### Everything is stored by what it is, not where it is

Every file is identified by a hash of its own content. Two identical files anywhere on any machine are one
object. A file you change is a new object; every version that came before it still exists.

That one decision pays for almost everything else:

- **Sending is cheap.** Before a push moves anything, the two machines compare addresses. A 900 KB
  workspace with one line changed sends **284 bytes** — because everything else is already there. Re-pushing
  something unchanged sends nothing at all.
- **History is affordable.** A snapshot of every change would be ruinous if it copied files. Storing
  addresses means an unchanged file costs one entry, so reed can record continuously rather than when you
  remember to.
- **Nothing is ever destroyed.** Deleting a file writes a tombstone into history; the content stays
  addressable. Undo isn't a feature bolted on afterwards, it's a consequence of the shape.

Large files are split into content-defined chunks, so changing one byte in the middle of a 1 GB file sends
the chunk, not the file.

### A daemon watches, and a push is a conversation

`reed up` leaves a small daemon running. It watches the folder, and when something settles it records a
snapshot — locally, immediately, with no network involved. Nothing you do ever waits on another machine.

Delivery happens after. The daemon sends new work to the machines that have received this workspace before,
retries a machine that's asleep, and stops asking politely rather than forever. A machine you have never
pushed to is never sent anything: choosing a destination once is what subscribes it.

### Arriving work is reviewed, not applied

This is the part that makes reed different from a sync folder, and it's deliberate.

If the other machine's work **can't cost you anything** — you haven't touched the folder since, so their
snapshot simply continues yours — it's applied, and the daemon tells you what arrived.

If you've **both** been editing, it does not guess. Their work lands as a branch you can see
(`reed peers`), read (`reed diff`), open as a real folder and build (`reed open`), and take when you decide
(`reed merge`). The merge is three-way against the state you last shared, so a change on their side and a
change on yours in different places both survive. Where they genuinely collide, it says so and names the
file instead of picking.

Every sync tool that has ever lost somebody's work lost it by guessing. reed's answer is to not be in a
position where guessing is required.

### `node_modules` is not one directory, it's one per platform

A build directory cannot be the same bytes on macOS and Linux, and pretending otherwise is how a folder
sync breaks the machine it arrives on.

reed stores that path as **one entry holding a real tree per platform.** Your Mac materialises the Mac
build; the Linux box materialises the Linux one; both are in the same recorded state, so neither machine
overwrites the other and they never ping-pong reinstalls.

A machine that has no build of its own yet doesn't get an empty directory *or* somebody else's binaries. It
gets every file that can be **proven** portable — pure JavaScript, and the `.bin` shims that point at it —
plus a named list of exactly which packages need building locally. It requires affirmative evidence to copy
anything, so anything it can't classify is withheld rather than guessed.

## Why it's different

### `node_modules` travels

Measured on a real project, macOS → Linux → Windows:

```
3,661 of 3,662 files placed        0 foreign executables crossed
tsc, eslint, prettier, webpack — all running on the far machine, no install, no network
```

You run the install **once per platform, ever**. After that a source change is *9 of 2,863 objects,
330 KiB, 97 % already there.*

### It will not lose a byte

That's a claim, so it gets attacked rather than asserted. **5,000 operations across 10 seeds** — 359 pushes
with the link severed at 82 different byte offsets, 20 outages, 54 `SIGKILL`s:

```
90 convergence points        every one byte-identical        macOS and Linux
```

Cut a 500 MB push in half, twenty times: **zero broken states**, and the retry moves only the missing half.
Three machines, four independent links, 2,880 more operations: all three folders identical at every one of
80 checkpoints.

### It's fast because it's local

Nothing routes through a datacenter. Two machines three feet apart talk to each other directly, and a save
is recorded on your own disk before the network is involved at all.

## Worth knowing

- **This is for code directories.** Not general-purpose file sync, and not a backup — reed keeps history on
  each machine, it does not keep a copy somewhere you can reach when the machine is gone.
- **reed has no concept of a secret.** A `.env` sits in your folder and travels with it like anything else.
  Between machines you own that is usually the point; if it isn't, add the name to your exclusions.
- **`.gitignore` isn't read.** Exclusions are a list of names — `.git`, `target`, `node_modules` and other
  sensible defaults — which you can edit.
- **Windows and Linux binaries are not code-signed.** The macOS one is (Developer ID, notarised by Apple).
  On the other two, the SHA-256 check in the installer is what stands between you and whatever arrived.

## Is this open source?

**Not yet. It will be — and it's worth saying exactly why not, because it isn't a moat.**

**Two people build reed.** That's the whole team. Nobody else is working on this, and that single fact
explains both halves of what you're looking at: how much is already here, and why the source isn't yet.

What's shipped is the floor, not the building — and the things going in next change the on-disk format and
the wire. A format is a promise. Opening the source at the exact moment those are landing means asking
people to build on shapes we are still moving, which is a worse gift than waiting.

So: **the source opens.** Not as a favour and not as a maybe. Watch this repo and you'll know the day.

Everything else is already here: releases, the install scripts you can read before you pipe them into a
shell, issues, and the changelog. File a bug and one of the two of us reads it.

## What changed, and when

Every release and what is in it: **[CHANGELOG.md](CHANGELOG.md)**. `reed update` prints the link when it
takes a new version, so you never have to go looking.

## Get in touch

- **Something broken?** [Open an issue](../../issues/new/choose) — run `reed doctor` first and paste what it
  says; it's built to make the answer obvious.
- **Security?** See [SECURITY.md](SECURITY.md). Please don't file a public issue.

---

<div align="center">
<sub>Built by <a href="https://github.com/ReedKeep">ReedKeep</a>.</sub>
</div>

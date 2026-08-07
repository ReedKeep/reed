<div align="center">

# reed

**One folder. Every machine you own. Nothing to think about.**

[Install](#install) · [60 seconds](#60-seconds) · [How it works](#how-it-works) · [Why it's different](#why-its-different) · [Limits](#honest-limits)

</div>

---

You edit on your laptop. It's on your desktop and your Linux box before you've alt-tabbed.

Not a copy you have to remember to make. Not a folder that silently overwrites your work to make two
machines agree, either — when you've both been editing, the other machine's work arrives as **something you
look at first**, and you take it when you're ready.

No cloud. No account. No server we run. Your machines talk to each other.

## Install

```sh
curl -fsSL https://reed.sh/install | sh     # macOS · Linux
```

```powershell
irm https://reed.sh/install.ps1 | iex       # Windows
```

Then, once per machine:

```sh
reed up
```

That's the setup. It starts at login and survives a reboot. Requires [Tailscale](https://tailscale.com) —
that's the network reed runs over, and it's the only dependency.

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

`reed status` is the dashboard. `reed doctor` tells you why it isn't working, in one screen. `reed help` is
everything else.

## How it works

Every version of every file is stored by the hash of its content. Identical states cost nothing, so a
snapshot on every change is affordable — and that one property quietly becomes dedup, delta transfer, undo
and time-travel at the same time.

Nothing is ever deleted. A removed file is a tombstone in history, never a destruction, so undo is free by
construction rather than by feature.

And nothing routes through a datacenter. Two machines three feet apart talk to each other directly over your
own tailnet.

## Why it's different

### `node_modules` travels

Every other sync tool answers this with an ignore rule, which throws away the thing you actually wanted.

reed carries it — **one path holding a real build per platform**. A machine with no build of its own gets
every file that can be *proven* portable, plus a named list of exactly what to install.

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

No round trip to anywhere. On a LAN, a save is on the other machine before you've looked up.

## Honest limits

We'd rather you read these here than find them yourself.

- **Tailscale is the network.** No relay, no NAT traversal of our own, no accounts. Machines that aren't on
  a tailnet can't be reached.
- **Everything is sent.** No lazy materialisation yet, so a first sync moves the whole folder.
- **`.gitignore` isn't read yet.** Exclusions are a name list you can edit; sensible defaults ship.
- **Code directories.** Not general-purpose file sync, and not a backup.
- **macOS and Linux are the daily drivers.** Windows works and is tested; it's the newest of the three.
- **Not notarised on macOS yet**, so Gatekeeper will ask the first time.

## Is this open source?

**Not yet. It will be — and it's worth saying exactly why not, because it isn't a moat.**

**Two people build reed.** That's the whole team. Nobody else is working on this, and that single fact
explains both halves of what you're looking at: how much is already here, and why the source isn't yet.

What's shipped is the floor, not the building. Everything above it is in progress right now:

- **Files that are there before the bytes are.** The folder exists on every machine the instant it's
  created; content arrives when you touch it. That's what makes "it's already on my other box" true across
  an ocean instead of just across a room.
- **Scrub any file to any second.** The engine under it is done — every version of everything is already
  kept. What's left is the part you actually touch.
- **A workspace you can fork.** Branch the whole tree *including uncommitted work*, let something run in it
  for real, keep it or throw the world away. The primitive is built and measured: **256 MiB forked in
  0.3 ms, consuming nothing.**
- **A workspace that knows what changed and what it meant.** Not a byte diff — *this function moved, that
  test now fails*. The thing an agent should be able to ask a folder when it joins on a new machine.

Every one of those changes the on-disk format or the wire, and a format is a promise. Opening the source at
the exact moment those are landing means asking people to build on shapes we're still moving — which is a
worse gift than waiting.

So: **the source opens.** Not as a favour and not as a maybe. Watch this repo and you'll know the day.

Everything else is already here: releases, the install scripts you can read before you pipe them into a
shell, issues, and the changelog. File a bug and one of the two of us reads it.

## Get in touch

- **Something broken?** [Open an issue](../../issues/new/choose) — run `reed doctor` first and paste what it
  says; it's built to make the answer obvious.
- **Security?** See [SECURITY.md](SECURITY.md). Please don't file a public issue.

---

<div align="center">
<sub>Built by <a href="https://github.com/ReedKeep">ReedKeep</a>.</sub>
</div>

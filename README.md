<div align="center">

<!-- The white mark on a dark theme, the black one on a light theme. GitHub honours prefers-color-scheme
     inside <picture>, and the <img> is the fallback for anything that does not. -->
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/reed-on-dark.svg">
  <img src="assets/reed-on-light.svg" alt="reed" width="200" height="200">
</picture>

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

## What's not built yet

Not the launch checklist — the **core**. These are real holes in the product, ranked by how likely they are
to matter to you. We'd rather you read them here than find them at eleven at night.

**Secrets are not special.** reed has no rule for `.env` or anything like it, so those files sync between
your machines like every other file. Between machines you own that is often what you want, and it is
absolutely not what you want by accident. Until there's a real policy, add the name to your exclusions.

**`.gitignore` is not read.** Exclusions are a list of names — `.git`, `target`, `node_modules`, a sensible
default set you can edit. That covers most of it and it is not the same thing, and if you are the kind of
person who curates a `.gitignore` you will notice within a minute.

**Everything is sent.** There's no lazy materialisation, so the first sync of a folder moves all of it. On a
LAN that's fine. Across an ocean it is the difference between *instant* and *four minutes*, and it is the
single biggest thing between reed and what reed is supposed to feel like.

**Time travel has an engine and no handle.** Every version of every file is already kept, and
`reed restore` puts the whole folder back. Putting *one file* back to *one moment* — the thing you actually
want at eleven at night — is not built.

**A forkable workspace is a primitive, not a command.** Copy the whole tree including uncommitted work, let
something run in it for real, keep it or throw the world away. Measured at **256 MiB in 0.3 ms consuming
nothing** — and there is no `reed branch` to reach it with.

**reed tells you what to install; it doesn't install it.** When a `node_modules` arrives from another
platform you get a named list of what needs building. Running it is still your job, once per platform.

**Nothing understands your code.** A folder that could answer *"what changed since I was last here, and what
did it mean"* — a function moved, a test now fails — is the thing that would make this indispensable to
anything automated. It does not exist. It is the most interesting thing on this list and the furthest away.

And the smaller true things: Tailscale is the network, so machines off your tailnet cannot be reached; this
is for code directories and is not a backup; macOS and Linux are the daily drivers and Windows is the
newest of the three; and macOS builds are not notarised yet, so Gatekeeper will ask the first time.

## Is this open source?

**Not yet. It will be — and it's worth saying exactly why not, because it isn't a moat.**

**Two people build reed.** That's the whole team. Nobody else is working on this, and that single fact
explains both halves of what you're looking at: how much is already here, and why the source isn't yet.

What's shipped is the floor, not the building. [What's not built yet](#whats-not-built-yet) is the honest
list, and every item on it changes the on-disk format or the wire. A format is a promise. Opening the
source at the exact moment those are landing means asking people to build on shapes we are still moving,
which is a worse gift than waiting.

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

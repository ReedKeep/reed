#!/bin/sh
# reed — one folder, on every machine you own.
#
#   curl -fsSL https://reed.sh/install | sh
#
# What this does, in order: works out which build you need, downloads it, checks its SHA-256 against the
# signed checksum list, and puts one binary on your PATH. It installs nothing else, writes nothing into your
# home directory, and starts no service — `reed up` is a separate decision you make afterwards.
#
# ## Three things in here are not obvious and all three are scars
#
# 1. **The binary is moved into place, never copied over.** On macOS, overwriting a running executable *in
#    place* leaves the kernel's cached code signature describing pages that have changed, and every later
#    `reed` dies with a bare `Killed: 9` — no message, no cause, nothing to search for. `mv` replaces the
#    directory entry and leaves the old inode alone, so a running daemon keeps the file it started with and
#    the next launch gets the new one. `cp` over the destination is the bug; `mv` is the fix.
# 2. **`sh`, not `bash`.** This is the one file that has to run before anything is installed, on a box whose
#    contents we do not know. Alpine has no bash. So: POSIX only, no arrays, no `[[`, no `local`.
# 3. **The whole script is read before any of it runs.** `curl … | sh` executes what has arrived so far, so a
#    connection that dies mid-transfer runs half a script. Wrapping everything in a function that is called
#    on the last line means a truncated download does nothing at all instead of something partial.

set -eu

REPO="${REED_REPO:-ReedKeep/reed}"
VERSION="${REED_VERSION:-latest}"

main() {
    say "reed installer"

    os=$(uname -s)
    arch=$(uname -m)
    case "$os" in
        Darwin) target="macos-universal" ;;
        Linux)
            case "$arch" in
                x86_64 | amd64) target="linux-x86_64" ;;
                aarch64 | arm64) target="linux-aarch64" ;;
                *) die "reed has no build for $os/$arch yet. Build it from source: cargo install --path crates/reed" ;;
            esac
            ;;
        MINGW* | MSYS* | CYGWIN*)
            die "this is the Unix installer. On Windows, run this in PowerShell instead:
      irm https://reed.sh/install.ps1 | iex"
            ;;
        *) die "reed has no build for $os yet. Build it from source: cargo install --path crates/reed" ;;
    esac

    need curl
    need tar
    # **Checked before anything is downloaded.** Finding out there is no checksum tool after moving 4 MB is
    # a worse experience than finding out first, and the answer is the same either way.
    if command -v shasum >/dev/null 2>&1; then
        sha="shasum -a 256"
    elif command -v sha256sum >/dev/null 2>&1; then
        sha="sha256sum"
    else
        die "neither shasum nor sha256sum is here, so the download cannot be checked. Install one, or take
      the binary yourself from https://github.com/$REPO/releases"
    fi

    if [ "$VERSION" = latest ]; then
        base="https://github.com/$REPO/releases/latest/download"
    else
        base="https://github.com/$REPO/releases/download/$VERSION"
    fi
    file="reed-$target.tar.gz"

    tmp=$(mktemp -d)
    # Cleaned up on every exit including a failure, so a broken install does not leave 8 MB in /tmp.
    trap 'rm -rf "$tmp"' EXIT INT TERM

    say "  downloading  $file"
    fetch "$base/$file" "$tmp/$file" || die "could not download $base/$file
      that release may not exist yet — https://github.com/$REPO/releases lists the ones that do"
    fetch "$base/SHA256SUMS" "$tmp/SHA256SUMS" || die "could not download the checksum list from $base
      reed will not install a binary it cannot check"

    say "  checking     SHA-256"
    want=$(grep " $file\$" "$tmp/SHA256SUMS" | awk '{print $1}')
    [ -n "$want" ] || die "$file is not in that release's SHA256SUMS, so there is nothing to check it against.
      This is a broken release rather than anything you did — please report it."
    got=$($sha "$tmp/$file" | awk '{print $1}')
    if [ "$want" != "$got" ]; then
        die "the download does not match its published checksum.
      expected $want
      got      $got
      Nothing was installed. Try again; if it happens twice, do not run the file."
    fi

    tar -xzf "$tmp/$file" -C "$tmp" || die "that archive did not unpack — the download may be truncated"
    [ -f "$tmp/reed" ] || die "that archive did not contain a 'reed' binary. Broken release; please report it."
    chmod +x "$tmp/reed"

    dir=$(where_to_put_it)
    mkdir -p "$dir"

    # **Moved, never copied over.** See the header — `cp` onto a running macOS binary is a `Killed: 9` with
    # no message attached. Staged inside the destination directory first, because `mv` across filesystems
    # falls back to a copy and would reintroduce exactly that.
    staged="$dir/.reed.incoming.$$"
    mv "$tmp/reed" "$staged" 2>/dev/null || cp "$tmp/reed" "$staged" || die "cannot write to $dir"
    chmod 755 "$staged"
    mv -f "$staged" "$dir/reed" || die "cannot replace $dir/reed"

    version=$("$dir/reed" --version 2>/dev/null || echo "reed")
    say ""
    say "  installed    $version"
    say "               $dir/reed"

    case ":$PATH:" in
        *":$dir:"*) ;;
        *)
            say ""
            say "  $dir is not on your PATH. Add this to your shell profile:"
            say "      export PATH=\"$dir:\$PATH\""
            ;;
    esac

    say ""
    say "  reed up      turn it on — starts at login, survives a reboot"
    say "  reed make    in a folder you want on every machine"
    say "  reed push    send it to one of them"
    say ""
    say "  reed doctor  if anything is not working, this says why"
}

# `/usr/local/bin` if we can write there, `~/.local/bin` otherwise.
#
# **Deliberately never `sudo`.** A one-line installer that asks for your root password is asking you to
# extend it a trust it has not earned, and the fallback costs one line in a profile. `REED_INSTALL_DIR`
# overrides both, for a packager or anybody with an opinion.
where_to_put_it() {
    if [ -n "${REED_INSTALL_DIR:-}" ]; then
        echo "$REED_INSTALL_DIR"
    elif [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
        echo /usr/local/bin
    else
        echo "$HOME/.local/bin"
    fi
}

fetch() {
    curl -fsSL --retry 3 --retry-delay 1 -o "$2" "$1"
}

need() {
    command -v "$1" >/dev/null 2>&1 || die "$1 is needed and is not here"
}

# Everything goes to stderr, so `curl … | sh` inside a script cannot mistake chatter for output.
say() {
    printf '%s\n' "$*" >&2
}

die() {
    printf 'reed: %s\n' "$*" >&2
    exit 1
}

# **The last line, and the reason there is a function at all.** See note 3 in the header: a truncated
# download never reaches this, so it does nothing rather than half of something.
main "$@"

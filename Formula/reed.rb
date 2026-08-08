# The reed formula.
#
# **Written by the release, not by hand.** `dist/release.sh` has already hashed every asset for
# `SHA256SUMS`, so it rewrites the version and the checksums below from those exact bytes. A formula whose
# checksum is typed by a person is one that is eventually wrong, and `brew` answers that by refusing the
# install rather than explaining it in a way that helps.
#
# **This lives in the same repository as everything else** rather than a separate `homebrew-reed` tap. The
# cost is one extra word at install time — `brew tap` needs the URL, because Homebrew's short form only
# resolves a repo literally named `homebrew-<x>`. One repo to find, one place to look.
class Reed < Formula
  desc "One folder, every machine you own"
  homepage "https://github.com/ReedKeep/reed"
  # The source is not published yet. `:cannot_represent` is the honest answer here, not `:proprietary`,
  # which Homebrew does not have.
  license :cannot_represent
  version "0.1.1"

  on_macos do
    # One universal binary: the installer asks `uname -s` and nothing else on Darwin, so Intel and Apple
    # Silicon take the same file and the kernel picks.
    url "https://github.com/ReedKeep/reed/releases/download/v0.1.1/reed-macos-universal.tar.gz"
    sha256 "a7242e5e443702dac14a030b3dc6496ff46c93794d4b2eac46223e2fb70308e5"
  end

  on_linux do
    on_intel do
      url "https://github.com/ReedKeep/reed/releases/download/v0.1.1/reed-linux-x86_64.tar.gz"
      sha256 "c275d4baeb9b81ef74464f43738a88b6dc83434949aa8ff5ea3ec3bcbb1dd762"
    end
    on_arm do
      # No ARM Linux build yet: there is no machine here to build one on. Saying so beats a 404, and
      # `cargo install --path crates/reed` works if you have the source.
      odie "reed has no Linux ARM build yet - build from source, or open an issue and we will prioritise it"
    end
  end

  def install
    bin.install "reed"
  end

  def caveats
    <<~EOS
      reed needs Tailscale, signed in as you, on every machine you want it on.
      That is how your machines find each other and how reed knows a peer is
      yours — there is no server and no account.

        tailscale status      # every machine should be in this list

      Then, once per machine:

        reed up

      If anything is not working, `reed doctor` says which part in one screen.
    EOS
  end

  test do
    # It has to run, not merely land. A formula that only checks the file exists passes for a binary that
    # cannot start on the machine it was just installed on.
    assert_match "reed", shell_output("#{bin}/reed --version")
    # And exit 2 is documented as "misuse: no state of the world would have made this valid", so it is a
    # cheap check that this is really reed and really this vintage.
    assert_match "unknown command", shell_output("#{bin}/reed definitely-not-a-command 2>&1", 2)
  end
end

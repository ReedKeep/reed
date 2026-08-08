# reed — one folder, on every machine you own.
#
#   irm https://raw.githubusercontent.com/ReedKeep/reed/main/install.ps1 | iex
#
# The Windows half of `dist/install.sh`, and it exists as its own file rather than as a branch of that one
# because a single script spanning `sh` and PowerShell is two dialects disagreeing about quoting — which is
# the reason `proof.py` is Python. Same shape, same guarantees: one binary, checked against its published
# SHA-256, and nothing else touched.
#
# ## What is different here, and why
#
# * **The running image is locked, not merely mapped.** Windows refuses to replace a `.exe` that a process
#   has open, so where the Unix installer can rename over a live daemon, this one has to notice and say so.
#   Measured while proving the six directed pairs: `curl` over a running `reed.exe` fails, and the machine
#   quietly keeps the old binary — an upgrade that reports success and changes nothing.
# * **No `sudo` equivalent.** It installs under `%LOCALAPPDATA%`, which needs no elevation, and puts that
#   directory on the user `PATH` if it is not already there.

$ErrorActionPreference = 'Stop'

$repo    = if ($env:REED_REPO)    { $env:REED_REPO }    else { 'ReedKeep/reed' }
$version = if ($env:REED_VERSION) { $env:REED_VERSION } else { 'latest' }
$dir     = if ($env:REED_INSTALL_DIR) { $env:REED_INSTALL_DIR } else { "$env:LOCALAPPDATA\reed\bin" }

function Say($m) { Write-Host $m }
function Die($m) { Write-Host "reed: $m" -ForegroundColor Red; exit 1 }

Say 'reed installer'

if ([System.Environment]::Is64BitOperatingSystem -eq $false) {
    Die 'reed has no 32-bit Windows build. Build it from source: cargo install --path crates/reed'
}

# **Refused before anything is downloaded.** Replacing a locked image fails silently enough that the only
# symptom is an upgrade that did not happen, so this is a refusal with the two commands that fix it rather
# than a warning nobody reads.
$exe = Join-Path $dir 'reed.exe'
if (Test-Path $exe) {
    try {
        $stream = [System.IO.File]::Open($exe, 'Open', 'ReadWrite', 'None')
        $stream.Close()
    } catch {
        Die @"
$exe is running, and Windows will not let it be replaced while it is.
      Stop it, install, and start it again:
          reed down
          irm https://raw.githubusercontent.com/ReedKeep/reed/main/install.ps1 | iex
          reed up
"@
    }
}

$base = if ($version -eq 'latest') {
    "https://github.com/$repo/releases/latest/download"
} else {
    "https://github.com/$repo/releases/download/$version"
}
$file = 'reed-windows-x86_64.zip'
$tmp  = Join-Path ([System.IO.Path]::GetTempPath()) ("reed-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

try {
    Say "  downloading  $file"
    try {
        Invoke-WebRequest -Uri "$base/$file" -OutFile "$tmp\$file" -UseBasicParsing
        Invoke-WebRequest -Uri "$base/SHA256SUMS" -OutFile "$tmp\SHA256SUMS" -UseBasicParsing
    } catch {
        Die "could not download from $base — that release may not exist yet.`n      https://github.com/$repo/releases lists the ones that do"
    }

    Say '  checking     SHA-256'
    $line = Get-Content "$tmp\SHA256SUMS" | Where-Object { $_ -match "\s$([regex]::Escape($file))$" }
    if (-not $line) { Die "$file is not in that release's SHA256SUMS. Broken release; please report it." }
    $want = ($line -split '\s+')[0]
    $got  = (Get-FileHash "$tmp\$file" -Algorithm SHA256).Hash.ToLower()
    if ($want.ToLower() -ne $got) {
        Die "the download does not match its published checksum.`n      expected $want`n      got      $got`n      Nothing was installed."
    }

    Expand-Archive -Path "$tmp\$file" -DestinationPath $tmp -Force
    if (-not (Test-Path "$tmp\reed.exe")) { Die "that archive did not contain reed.exe. Broken release; please report it." }

    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Move-Item -Path "$tmp\reed.exe" -Destination $exe -Force

    $v = & $exe --version
    Say ''
    Say "  installed    $v"
    Say "               $exe"

    # The user PATH, not the machine PATH: no elevation, and it does not touch anybody else's account.
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$dir*") {
        [Environment]::SetEnvironmentVariable('Path', "$userPath;$dir", 'User')
        $env:Path = "$env:Path;$dir"
        Say "               added to your PATH — open a new terminal for it to take"
    }

    Say ''
    # The onboarding block is for somebody who has just met reed. `reed update` runs this same script and
    # already knows what reed is, so telling it to run `reed make` is noise in the middle of an upgrade —
    # and noise in a tool's output is how people learn to stop reading it. Same switch as install.sh.
    if (-not $env:REED_NO_HINTS) {
        Say '  reed up      turn it on — starts at login, survives a reboot'
        Say '  reed make    in a folder you want on every machine'
        Say '  reed push    send it to one of them'
        Say ''
        Say '  reed doctor  if anything is not working, this says why'
    }
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

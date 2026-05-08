# Security Policy

## Scope

This repository (`yolo-labz/homebrew-tap`) is a **Homebrew tap** — it
ships only Ruby formula definitions that point at upstream release
artifacts in other `yolo-labz/*` repositories. It does **not** distribute
compiled binaries itself.

Per-tool security policies, supply-chain provenance, SBOMs, and
disclosure channels live in the **upstream repository for each formula**
(e.g. `yolo-labz/chrome-bridge`, `yolo-labz/wa`, `yolo-labz/kokoro-speakd`,
`yolo-labz/claude-classroom-submit`).

## Reporting a Vulnerability in the Tap Itself

If the issue is with a **formula definition** in this repo (wrong URL,
wrong SHA-256, malformed Ruby), report it privately:

**Please do NOT open public GitHub issues for security vulnerabilities.**

1. **GitHub Security Advisories (preferred)** — open a private advisory at
   https://github.com/yolo-labz/homebrew-tap/security/advisories/new
2. **Email** — contact the maintainer directly via the email listed on
   https://github.com/phsb5321

### What to include

- Affected formula filename and line(s)
- Expected vs. observed `url` / `sha256` / `version`
- Reproduction (e.g. `brew install yolo-labz/tap/<formula>` output)
- Impact assessment

### Response SLA

- **Acknowledgement:** within 72 hours
- **Triage + initial assessment:** within 7 days
- **Fix:** target 30 days for high/critical, 90 days for medium/low

## Reporting a Vulnerability in an Upstream Tool

If the issue is in the **software** a formula installs (not the formula
definition), please report it to that upstream repository's security
policy directly. The tap maintainer will coordinate a formula bump after
the upstream fix ships.

## Verifying Installed Artifacts

Each upstream release publishes Sigstore provenance via
`actions/attest-build-provenance`. After installing a formula:

```bash
brew install yolo-labz/tap/<formula>
gh attestation verify "$(brew --cellar <formula>)/<version>/..." \
  --repo yolo-labz/<upstream-repo>
```

SBOMs (CycloneDX 1.7 + SPDX 2.3) are attached to each upstream GitHub
Release.

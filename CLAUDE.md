
## Release engineering (yolo-labz standards) — repo-scoped canon

<!-- Moved here from the global Claude rules layer (NixOS spec 887 FR-012): policy is repo-scoped, not fleet-global. -->

Release-engineering standards for every self-coded Claude Code plugin in the
yolo-labz GitHub org (claude-mac-chrome, wa, kokoro-speakd, claude-classroom-submit,
homebrew-tap). Derived from ~/NixOS/meta/yolo-labz-release-engineering-research.md —
read it in full before any release-engineering work on these repos. Do NOT apply
these rules to unrelated projects.

## Supply chain (mandatory)

- Use GitHub native attestations: `actions/attest-build-provenance` +
  `actions/attest-sbom`. Current production pin across the yolo-labz rollout is
  v4.1.0, SHA `a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32`. Pin both actions in
  full SHA-with-comment form, e.g.:
    `uses: actions/attest-build-provenance@a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32 # v4.1.0`
    `uses: actions/attest-sbom@a2bbfa25375fe432b6a289bc6b6cd05ecd0c4c32 # v4.1.0`
  (the v2/v3/v4 family is acceptable; v4.1.0 is the current rollout standard).
  Do NOT add `slsa-framework/slsa-github-generator` to new work — only maintain
  it on claude-mac-chrome if the SLSA L3 formal claim is still load-bearing.
  New plugins get L2 + native attestations.
- Primary user verification path is `gh attestation verify` (single command, no
  cosign install). Demote `cosign verify-blob` + `slsa-verifier` to an "advanced
  / offline" README section, never the headline.
- Cosign OIDC issuer is `https://token.actions.githubusercontent.com`. The
  `https://github.com/login/oauth` URL is the interactive human flow, NOT CI.
- Publish BOTH CycloneDX 1.7 AND SPDX 2.3 SBOMs. `syft` emits both in one call:
  `syft . -o cyclonedx-json@1.7=sbom.cdx.json -o spdx-json=sbom.spdx.json`. For
  Go repos, additionally run `cyclonedx-gomod app -licenses -std -json` for a
  richer Go-native SBOM.
- Never re-tag a release. `slsa-verifier` validates against the commit SHA at
  signing time; re-tagging produces stale provenance. Cut `vX.Y.Z+1` on botched
  publishes.
- Always `export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)` before archive or
  build steps so tarballs and wheels are byte-reproducible.

## GitHub Actions hardening (mandatory)

- Pin every action by FULL 40-char commit SHA with a trailing `# vX.Y.Z` comment.
  Tag pins (even "immutable") do NOT satisfy Scorecard's Pinned-Dependencies.
  Dependabot preserves the version comment when bumping SHAs — never strip it.
- Workflow-level `permissions: {}` (deny-all), per-job re-grant. Signing jobs
  need `id-token: write` + `attestations: write` + `contents: read`. Add
  `contents: write` only if the same job cuts a GitHub Release, `packages: write`
  only for OCI pushes.
- Add `step-security/harden-runner@<sha>` in `egress-policy: audit` on every
  release workflow. Flip to `block` after one release cycle once Sigstore egress
  is observed. Linux full-support; macOS/Windows audit-only.
- Use Repository Rulesets, not classic branch protection. Bootstrap required
  checks via `enforcement: disabled` → merge → `active`. Delete classic
  protection AFTER ruleset verification — they stack additively and the stricter
  silently wins.
- Use reusable workflows (`workflow_call`), not composite actions, for shared
  release/signing logic. Caller job must still declare `id-token: write` —
  permissions intersect, not inherit upward.
- Add `zizmor` + `actionlint` as pre-commit hooks. Catches template-injection
  and permission mistakes CodeQL/Sonar miss.
- `persist-credentials: false` on `actions/checkout` unless pushing back.
- `timeout-minutes:` on every job.

## Language-specific (read research.md §3 for full detail)

Go (wa):
- GoReleaser OSS is sufficient; Pro is not needed for this stack.
- `-trimpath`, `-buildvcs=true` (Go 1.24 default), `CGO_ENABLED=0`, `-buildmode=pie`.
- `-ldflags=-X main.date={{.CommitDate}}` — commit timestamp, NEVER `$(date)`.
- Pin toolchain via `go.mod` `toolchain go1.24.x` directive.
- Drop standalone `govulncheck` when adding OSV-Scanner V2 — the latter invokes
  govulncheck internally for Go call-graph reachability; running both is
  redundant.
- `go test -race -shuffle=on -count=1 ./...` in CI; nightly fuzz with committed
  corpus under `testdata/fuzz/`.
- Use `brews:` (not `homebrew_casks:`) for CLIs in the tap.

Python (kokoro-speakd, claude-classroom-submit):
- Publish via PyPI Trusted Publishing (`pypa/gh-action-pypi-publish@release/v1`).
  PEP 740 attestations are auto-generated since v1.11 (Nov 2024). Do NOT add a
  separate `sigstore/gh-action-sigstore-python` step — redundant.
- Build backend: `hatchling` (or `uv_build` for speed). Set `SOURCE_DATE_EPOCH`
  plus `PYTHONHASHSEED=0` before `uv build`.
- Run `pip-audit` + `osv-scanner` + Dependabot in parallel; dedupe on GHSA alias.
- `ruff` replaces flake8/black/isort/pyupgrade/pydocstyle. Use `pyright` over
  mypy unless plugins force the issue.
- CodeQL Python uses `build-mode: none`; add `paths-ignore: ['site-packages/**']`
  for ML-heavy repos.
- kokoro-speakd: declare torch/onnxruntime as `>=` deps — do NOT build/ship your
  own torch wheels. Model weights ship as GitHub Release assets with
  `attest-build-provenance` over the file digest, not via PyPI.
- claude-classroom-submit: publish to PyPI anyway (trusted publishing + PEP 740
  attestations are free benefits even for zero-dep packages).

Shell (claude-mac-chrome):
- `#!/usr/bin/env bash` with bash 3.2 compatibility (macOS). Avoid `declare -A`,
  `mapfile`, `readarray`, `${var^^}`, `${var,,}`.
- CodeQL does NOT support shell in 2026. Upload ShellCheck SARIF separately via
  `github/codeql-action/upload-sarif`.
- Use `bats` + `shellcheck` + `shfmt` (community standard; Anthropic has no
  blessed framework).

## Governance (mandatory)

- `CHANGELOG.md` is auto-generated, never hand-edited. Either tool is acceptable:
  `git-cliff` (single Rust binary, no npm — preferred for Go repos like `wa`) or
  `release-please` (GitHub Action, supports monorepo, preferred for polyglot or
  greenfield plugin repos). Pick one per repo; don't mix. Output format follows
  Keep-a-Changelog 1.1.0.
- Conventional commits enforced via `commitlint` + `@commitlint/config-conventional`
  in `lefthook` (faster than husky; `wa` already uses this — match the pattern).
- Dependency updates: `Dependabot` (native GitHub, preserves `# vX.Y.Z` SHA-pin
  comments) OR `Renovate` (more aggressive, `helpers:pinGitHubActionDigests`
  preset). `wa` uses Renovate — respect existing choice, do not migrate.
- `SECURITY.md` points users at `/security/advisories/new` (GitHub Private
  Vulnerability Reporting). PGP keys are discouraged in 2026.
- `CODEOWNERS` is path-based (documents intent, eases future collaboration).
- DCO sign-off (`git commit -s`) for hygiene; no CLA.
- License: MIT or Apache-2.0, author's choice. `wa` is Apache-2.0 (explicit
  patent grant, matches Anthropic Telegram plugin precedent); other plugins
  are MIT. Do not migrate an existing license without discussion.

## Scorecard optimization

Realistic ceiling for a solo-dev yolo-labz repo is ~8.7/10:

- Fuzzing: `fuzz.yml` is NOT detected by Scorecard. For Go, add one `*_test.go`
  with `func FuzzX(f *testing.F)` — free +10. For shell, restructure to
  `.clusterfuzzlite/` + `.github/workflows/cflite_pr.yml`.
- Contributors: structurally capped ~3/10 for solo devs. Not gameable via
  Co-Authored-By trailers (bots and empty `Company` fields are filtered).
  Accept the loss and document in SECURITY.md.
- Maintained: auto-heals at day 90 with ≥1 commit/week.
- Packaging: add any publishing action (`softprops/action-gh-release`,
  `pypa/gh-action-pypi-publish`, `JS-DevTools/npm-publish`) → 10/10.
- Pinned-Dependencies: use StepSecurity's secure-workflow rewriter
  (https://app.stepsecurity.io/secureworkflow/) for bulk SHA pinning.
- Token-Permissions: `permissions: read-all` at workflow top-level → +2-3.
- Signed-Releases: Sigstore cosign + SLSA provenance assets → 10/10.

## Claude Code plugin ecosystem constraints (informational)

As of April 2026, Anthropic's Claude Code plugin marketplace has NO supply-chain
requirements (no signing, no SBOM, no SLSA, no signature verification on install).
Trust is per-marketplace, not per-plugin. Supply-chain work on yolo-labz plugins
is voluntary — good security hygiene, ahead-of-Anthropic. Do NOT block on
marketplace compliance when planning supply-chain rollouts.

- `plugin.json` lives at `.claude-plugin/plugin.json`; only `name` is required.
- `plugin.json` version field wins over marketplace entry version — pick one home.
- Persistent binary state lives in `CLAUDE_PLUGIN_DATA` (not CLAUDE_PLUGIN_ROOT).
- SessionStart hook pattern: diff a `manifest.lock` against bundled version,
  reinstall binary on drift, `chmod +x`, write new manifest. Do NOT re-download
  every session.
- No plugin-to-plugin dependency field exists; document required sibling plugins
  in README and check via SessionStart hook.
- Shell plugins must use `CLAUDE_PLUGIN_ROOT` for all paths; never bare relative.
- Hooks must exit non-zero with actionable error messages.

## Invariants (never break these)

1. Never re-tag a release. Cut vX.Y.Z+1 on botched publishes.
2. Never commit binaries to the repo (`dist/`, `build/` in `.gitignore`).
3. Never ship a release with failing CI. Tag push must be gated on green main.
4. Never store SonarQube `USER_TOKEN` credentials in CI. Always use
   `PROJECT_ANALYSIS_TOKEN` scoped to one project key.
5. Never use `--certificate-oidc-issuer https://github.com/login/oauth` in cosign
   docs — that is the interactive human flow. Use
   `https://token.actions.githubusercontent.com` for CI-issued OIDC.
6. Never edit `CHANGELOG.md` by hand once `release-please` owns it.
7. Never strip the `# vX.Y.Z` comment from SHA-pinned actions — Dependabot's
   regex needs it to recognize the entry.
8. TRANSITIVE-PIN: a top-level SHA pin is necessary but NOT sufficient. For any
   reusable-workflow / composite-action `uses:`, recursively verify every NESTED
   `uses:` in its call graph is SHA-pinned (it inherits the caller's secrets).
   Enforce with `meta/expand-uses.py --max-depth 5 --fail-on-mutable`.
9. AI-CI-INJECTION self-defense: never combine `pull_request_target`/`workflow_run`
   with a checkout of fork code while secrets are in scope; never interpolate
   `github.event.*` expressions into an agent prompt or a `run:` block (pass via
   `env:`, reference `"$VAR"`); treat agent output as untrusted code (no
   auto-exec/auto-merge). `zizmor --persona=auditor` is a REQUIRED PR gate.
10. OSPS Baseline is the SPEC (Level 1 floor -> Level 2 target); the ~8.7/10
    Scorecard ceiling is only the MEASUREMENT. When they disagree, OSPS wins.
11. AUDIT-BEFORE-BOOTSTRAP: baseline-report -> prioritized plan -> fix-in-PR ->
    re-run Scorecard -> log delta. P0 repo-settings (Code-Review, Branch-Protection,
    Maintained) before P1 automation (SAST, Pinned-Deps, Fuzzing). Fuzzing ships in
    its OWN PR. Never declare a repo "done" on intent — only on a logged delta.
12. Never close the issue/PR yourself (verify + report; the human closes). Frame
    bootstrap/audit runs as an "expert product security engineer"; prefer the `gh`
    CLI over the GitHub MCP on API limits. Weekly drift-audit via `meta/drift-audit.py`
    (a pinned SHA matching no upstream tag, or a SHRINKING tag set, is a probable
    tj-actions-style takeover — treat as P0). Full detail: rules 21-27 of
    `~/NixOS/meta/yolo-labz-release-engineering-research.md`.

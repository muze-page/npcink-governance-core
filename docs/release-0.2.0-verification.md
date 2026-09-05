# 0.2.0 Release Verification

Status: technically verified release candidate; publication operations are
not complete.

## Candidate Revisions

| Repository | Version | Revision | Conventional tag |
| --- | --- | --- | --- |
| Governance Core | `0.2.0` | `e2cbbe1a06154d092473abb5c80aad382cf8388c` | `v0.2.0` available |
| AI Client Adapter | `0.3.3` | `66ad29f044607bb0721d6cf542beae9584420e30` | `v0.3.3` available |
| Abilities Toolkit | `0.5.5` | `459a1b4841e3a93dbf79e6ecd23cd67f0bc68b85` | `0.5.5` available |

## Verified

- Core `composer test:all`, real WordPress smoke, PHPStan, strict packaged
  Plugin Check, release packaging, and ZIP integrity passed.
- The signed Adapter fixture created, approved, executed, read back, and
  cleaned a real draft through the intended Adapter -> Core -> Toolkit chain.
- Toolkit `composer test:all` passed with 6743 assertions and PHPStan reported
  no errors.
- On M4 Docker 29.7.2, the Toolkit candidate passed 441 smoke assertions on
  WordPress 6.9.4/PHP 8.0 and 441 on WordPress 7.0/PHP 8.5.
- The central six-repository `composer quality:matrix:run` gate passed.
- `composer rc:version-matrix -- --require-tag-ready` passed and found all
  three conventional tags available.

## Final Core Artifact

- Path: `build/npcink-governance-core.zip`
- SHA-256: `93349ce414596afb87154da8ba1c908554cd8434fb96f5a20e22a120616c2d8e`
- ZIP integrity: passed.

## Remaining Release Risks

1. The monolithic `composer acceptance:cross-repo-release` command exited in
   Toolkit's duplicate minimum-version smoke because the local Docker daemon
   socket was unavailable. Every earlier gate, including packaging and the
   signed write fixture, passed; both Docker compatibility lanes passed on M4.
2. Workflow Toolbox has 13 unrelated uncommitted paths. Its test gate passed,
   but a clean exact-source stack closeout cannot be claimed until its owner
   resolves those changes.
3. Core and Adapter release branches are ahead of origin, and the Toolkit
   release branch has no upstream. No release tag has been created or pushed.
4. Local WP-CLI under PHP 8.5 emits repeated third-party color-library
   deprecation messages. They did not fail any product assertion, but they make
   release logs noisy and should be isolated or suppressed in CI tooling.
5. Toolkit packaged Plugin Check has no errors but retains known
   translation-loading and bounded database-query warnings. These should stay
   documented and be re-evaluated before a WordPress.org submission.

## Publication Decision

Do not tag or publish yet. First resolve the dirty Toolbox checkout, commit the
final evidence revisions, rerun the strict version matrix, and choose one
explicit Docker gate policy: restore local Docker for a monolithic green run,
or make the M4 compatibility result a revision-bound first-class release lane.
No product workflow, workflow runtime, queue, MCP runtime, provider credential,
or final write execution belongs in Core as part of this closeout.

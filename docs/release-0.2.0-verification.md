# 0.2.0 Release Verification

Status: technically verified release candidate; publication operations are
not complete.

## Candidate Revisions

| Repository | Version | Revision | Conventional tag |
| --- | --- | --- | --- |
| Governance Core | `0.2.0` | `e98f2a90a909acb4fed7614156ecd7019391eecb` M4 smoke candidate; protected merge pending | `v0.2.0` available |
| AI Client Adapter | `0.3.3` | `66ad29f044607bb0721d6cf542beae9584420e30` | `v0.3.3` available |
| Abilities Toolkit | `0.5.5` | `3e237d91cbc1f135c559d47d1e20106aee62c1bb` | `0.5.5` available |

## Verified

- Core `composer test:all`, real WordPress smoke, PHPStan, strict packaged
  Plugin Check, release packaging, and ZIP integrity passed.
- Core release packaging now normalizes timestamps and ZIP metadata, sorts
  archive entries, and has a default-gate regression proving two equivalent
  builds produce the same SHA-256.
- On M4 Docker 29.7.2, the exact Core ZIP was installed and exercised on
  WordPress 7.0/PHP 8.0 and WordPress 7.0/PHP 8.5; both profiles passed 1,426
  Core smoke assertions.
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
- SHA-256: `6b87a88be3b7197d5a67aa4b5fea35764f896fdcf1331b7b0ed7039d2d85a59a`
- ZIP integrity: passed.
- Reproducibility: two equivalent builds passed with the same SHA-256.

## Remaining Release Risks

1. M4 Core evidence is complete for the current candidate, but the smoke log
   exposes a duplicate-key database error from the app rate limiter's first
   request in each profile. The request is handled and assertions pass, but
   release quality requires removing this production-log error before tagging.
2. Workflow Toolbox has unrelated uncommitted paths. Its test gate passed,
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

Do not tag or publish yet. First eliminate the app rate limiter duplicate-key
error and rerun both M4 profiles with clean logs, then publish the candidate
commits through protected pull requests, regenerate exact-merge evidence, and
rerun the strict version and central quality matrices. No product workflow,
workflow runtime, queue, MCP runtime, provider credential, or final write
execution belongs in Core as part of this closeout.

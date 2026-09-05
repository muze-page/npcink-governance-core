# 0.2.0 Release Verification

Status: technically verified release candidate; publication operations are
not complete.

## Candidate Revisions

| Repository | Version | Revision | Conventional tag |
| --- | --- | --- | --- |
| Governance Core | `0.2.0` | `c900022c9d53bb47177c0a347b67daaf0304576e` packaging implementation; protected merge pending | `v0.2.0` available |
| AI Client Adapter | `0.3.3` | `66ad29f044607bb0721d6cf542beae9584420e30` | `v0.3.3` available |
| Abilities Toolkit | `0.5.5` | `e8154ab9db1e0d1f01768f7e97186f31c46fc3ce` | `0.5.5` available |

## Verified

- Core `composer test:all`, real WordPress smoke, PHPStan, strict packaged
  Plugin Check, release packaging, and ZIP integrity passed.
- Core release packaging now normalizes timestamps and ZIP metadata, sorts
  archive entries, and has a default-gate regression proving two equivalent
  builds produce the same SHA-256.
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

1. The M4 Docker compatibility evidence currently installs and exercises the
   Toolkit candidate. Core activation, schema, and REST smoke passed in LocalWP,
   but the Core ZIP has not yet been installed and exercised independently on
   the M4 Docker host.
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

Do not tag or publish yet. First install and smoke the exact Core ZIP on M4,
publish the candidate commits through protected pull requests, regenerate
exact-merge evidence, and rerun the strict version and central quality
matrices. No product workflow, workflow runtime, queue, MCP runtime, provider
credential, or final write execution belongs in Core as part of this closeout.

# 0.2.0 Release Verification

Status: technically verified release candidate; publication operations are
not complete.

## Candidate Revisions

| Repository | Version | Revision | Conventional tag |
| --- | --- | --- | --- |
| Governance Core | `0.2.0` | `35fc4eb6f4847d15a1e9ff70b96ae6c320b32cdc` merged via protected PR #74 | `v0.2.0` available |
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
  Core smoke assertions, with no duplicate-key or WordPress database errors.
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
- SHA-256: `608676d35cc6ea1934513a9a76a822e3e62ca646339c67a62cd73845e5647e48`
- ZIP integrity: passed.
- Reproducibility: two equivalent builds passed with the same SHA-256.

## Post-Merge M4 Evidence

- Source revision: `35fc4eb6f4847d15a1e9ff70b96ae6c320b32cdc`
- Source archive SHA-256: `60e2eed73df9c1d9382301ef877414f007783e95945c660df2ec28b3c6e00230`
- Core package SHA-256: `608676d35cc6ea1934513a9a76a822e3e62ca646339c67a62cd73845e5647e48`
- Toolkit archive SHA-256: `00af0bf9c7775c6722b40a4ba05d060c39afd007da3acb96a656f6be71edc777`
- M4 Docker Server: `29.7.2`
- Profiles: WordPress 7.0/PHP 8.0 and 7.0/PHP 8.5, 1,426 assertions each,
  installed from ZIP.

## Remaining Release Risks

1. Workflow Toolbox has unrelated uncommitted paths. Its test gate passed,
   but a clean exact-source stack closeout cannot be claimed until its owner
   resolves those changes.
2. Core, Adapter, and Toolkit release tags have not been created or pushed;
   final coordinated tagging remains pending.
3. Local WP-CLI under PHP 8.5 emits repeated third-party color-library
   deprecation messages. They did not fail any product assertion, but they make
   release logs noisy and should be isolated or suppressed in CI tooling.
4. Toolkit packaged Plugin Check has no errors but retains known
   translation-loading and bounded database-query warnings. These should stay
   documented and be re-evaluated before a WordPress.org submission.

## Publication Decision

Do not tag or publish yet. Complete the remaining Adapter/Toolkit/Toolbox
protected-repository closeout, rerun the strict version and central quality
matrices, then perform the final coordinated tag and package publication. No product workflow,
workflow runtime, queue, MCP runtime, provider credential, or final write
execution belongs in Core as part of this closeout.

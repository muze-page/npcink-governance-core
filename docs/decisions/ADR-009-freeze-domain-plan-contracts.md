# ADR-009: Freeze Domain-Specific Plan Contracts In Core

Status: Accepted for the 0.2.x release line.

## Context

Core currently validates a growing allowlist of Toolkit and Toolbox planning
abilities. The validator is governance intake code, but the allowlist and its
domain-specific branches increasingly duplicate product contracts owned by
provider and integration repositories.

## Decision

Core will not add new domain-specific plan ids, schemas, previews, or workflow
semantics to `Plan_Contract_Validator`. Existing plan contracts remain
supported only as compatibility adapters while their owners migrate to a
versioned, provider-neutral governance envelope containing ordered actions,
ability ids, input binding, preview evidence, risk, and approval requirements.

Provider or integration repositories own domain schemas, planning behavior, and
their migrations. Core owns only admission, proposal lifecycle, approval,
preflight, audit, and contract-drift rejection.

Any exception requires a new ADR that identifies the provider owner, sunset
condition, and why the envelope cannot represent the required governance
evidence. A request that would add execution, queues, retries, scheduling,
workflow runtime, or product UX remains out of scope regardless of this ADR.

## Consequences

- No new product coupling is added to Core during the 0.2.x release line.
- Existing integrations can migrate incrementally without changing Core's
  approval truth.
- The validator remains large until compatibility adapters are retired; that
  retirement must happen in the owning provider repositories.

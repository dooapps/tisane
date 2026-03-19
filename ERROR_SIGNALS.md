# Error Signals

## Objective

Define one agnostic error channel for the secure mesh.

This channel does not encode Mellis business rules.
It only standardizes how a system reports, routes, and resolves error signals.

## Canonical event type

- `signal.error`

## Required payload fields

- `signal_id`
- `code`
- `summary`
- `source`
- `owner_unit_ref`
- `severity`
- `status`
- `occurred_at`

## Optional payload fields

- `correlation_id`
- `subject_ref`
- `detail_ref`
- `metadata`

## Why this exists

- one place to emit errors
- one place to listen for errors
- one agnostic contract for routing
- no leakage of domain-specific schema into `tisane`
- one growing corpus of operational errors for future analytics and AI prevention

## Golden rule

- expected business state does not enter the agnostic channel
- operational, contractual, or integration failure does

## Regra de ouro

- estado esperado de negocio nao entra no canal agnostico
- falha operacional, contratual ou de integracao entra

## What belongs in this channel

Use `signal.error` for:

- integration failures
- contract validation failures
- authorization failures
- processing failures
- transport failures
- replication failures
- infrastructure failures

Do not use `signal.error` for:

- expected business outcomes
- normal payment refusals that belong to domain state
- offer inactive
- balance unavailable
- hold not yet released

Rule:
- expected domain state stays in the domain state model
- operational or contractual failure enters `signal.error`

## Routing rule

- the producing system emits `signal.error`
- the signal returns through `tisane-relay`
- `tisane` receives the replicated signal back as the single local place of error observation
- `owner_unit_ref` identifies who must react
- `detail_ref` may point to protected detail sealed with `infusion_ffi`
- downstream systems consume only what they are allowed to see

Canonical money-layer return path:

1. Me Inn publishes commercial intent into the secure mesh.
2. `Mellis` consumes what belongs to the money layer.
3. If processing fails operationally, `Mellis` emits `signal.error`.
4. `tisane-relay` replicates that signal to peers.
5. `tisane` receives the signal back and exposes one unified local error surface.

## Status values

- `reported`
- `acknowledged`
- `resolved`

## Severity values

- `info`
- `warning`
- `error`
- `critical`

## Safety rule

`summary` must be safe to replicate.
Sensitive detail must not be placed directly in the replicated payload.
When sensitive context is needed, seal it separately and publish only a reference such as `detail_ref`.

## Why centralize

This channel is intentionally allowed to become a large operational catalogue of failures.

That is useful because it gives the platform:

- one observable history of failure patterns
- one place to classify error nature
- one future dataset for AI-assisted prevention, clustering, and triage

# Sensitive Payment Data

## Objective

Explain how payment can work when Me Inn knows the customer, Mellis handles the money contract, and sensitive data must remain protected.

## Core rule

`Mellis` should not become a general-purpose reader of customer PII.

The normal flow is:

1. Me Inn knows and confirms the customer.
2. `tisane` stores sensitive material protected by `infusion_ffi`.
3. `tisane-relay` transports only signed, agnostic payloads.
4. `Mellis` receives opaque references, attestations, and payment intent.
5. `Mellis` settles money and returns status through the same secure mesh.

## Default payment pattern

`Mellis` should receive:

- `buyer_ref`
- `checkout_ref`
- `customer_projection_ref`
- `legal_entity_ref` when needed
- payment amount and currency
- signed attestations required for settlement

`Mellis` should not persist:

- customer full name in clear
- raw document number in clear
- raw PIX key
- raw bank account

## When raw data is not needed

Prefer derived attestations such as:

- customer was verified by Me Inn
- customer belongs to publication X
- document hash matches previous verification
- billing country is BR
- account status is active

This lets `Mellis` decide settlement logic without reading raw identity.

This is the default target state:

- Me Inn knows the customer
- Me Inn confirms the customer
- `Mellis` knows only the minimum payment-safe projection and attestation
- ITVA remains the merchant-facing identity when that is the contract

## When provider-facing detail is needed

If some provider step strictly requires protected customer detail:

1. keep the source data sealed in `tisane`
2. create a purpose-bound capability using `infusion_ffi`
3. allow only the minimum projection for the purpose `payment:itva:<operation>`
4. let `Mellis` use that projection ephemerally
5. do not store the raw projection in `Mellis`

That means `Mellis` is authorized for a narrow payment purpose, not for general identity access.

In practice, this is "authorized to use" rather than "authorized to know".

`Mellis` may be allowed to trigger a provider-facing payment step with a protected projection,
while still being forbidden from persisting or broadly reading the underlying customer PII.

## Merchant of record note

If ITVA is the only merchant-facing CNPJ that appears:

- that is compatible with this model
- `Mellis` still handles payment orchestration and settlement
- customer identity remains owned by Me Inn and protected by `tisane` + `infusion_ffi`
- downstream provider-facing traces can still use opaque refs and purpose-bound projections

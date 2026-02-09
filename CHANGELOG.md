## 1.2.0

- Refactor: `InfusionManager` is now a Singleton `Infusion` class with dependency injection for storage, improving testability.
- Feature: Added `InfusionStoragePort` allowing custom storage backends (e.g., memory for testing).
- Feature: Metadata retrieval for `Infusion` identity.
- Fix: Enhanced `TTClient.getValue` with better timeout handling and resource cleanup.

## 1.1.2

- Debug: Add detailed Infusion init/seal/open logs to trace vault lifecycle and payload flow.
- Chore: Bump `infusion_ffi` to 1.3.20 for the latest multi-platform binaries and Android loader fixes.

## 1.1.1

- Chore: Remove UI bootstrap entrypoint from package library (`lib/main.dart`).
- Chore: Clean local vault artifacts from the repo and ignore them going forward.
- Chore: Drop unused `cupertino_icons` dependency.

## 1.1.0

- Feature: Full Infusion integration with structured envelopes (INFJ), AAD, policies (private/shared/public), and Cap Tokens.
- Feature: Persist public identity (author/owner) from mnemonic and expose `exportIdentity`.
- Docs: Expanded multilingual documentation with core concepts and usage guides.

## 1.0.2

- Docs: Updated README with multilingual support (PT-BR, EN-US, ES).
- Docs: Added comprehensive documentation for package usage.
- Example: Added `example/` directory with a working demonstration app.
- CI: Enhanced release workflow for dynamic validation.

## 1.0.1

- Fix: Resolved CI/CD pipeline issues.
- Fix: Updated `infusion_crypto_adapter` with correct linter formatting.
- Tests: Added conditional skipping for FFI integration tests in CI environments.

## 1.0.0

- Initial release.

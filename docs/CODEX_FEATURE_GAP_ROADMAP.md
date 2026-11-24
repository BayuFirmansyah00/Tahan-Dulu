# AUTHORITATIVE CODEX FEATURE GAP ROADMAP

**Project**: Tahan Dulu  
**Audit Baseline Date**: November 24, 2026  
**Status**: Authoritative Reference — DO NOT REDEFINE, RENAME, OR RENUMBER FINDINGS

---

## 1. ROADMAP TAXONOMY & LIFECYCLE

| Finding ID | Phase | Finding Title / Scope | Implementation Status | Verification Status |
| :--- | :--- | :--- | :--- | :--- |
| **F01** | Phase 1 | Financial account deletion may destroy transaction history | RESOLVED (Phase 1/1B) | Verified via automated suite |
| **F02** | Phase 1 | Investment balance mutations may execute twice | RESOLVED (Phase 1/1B) | Verified via automated suite |
| **F07** | Phase 1 | Goal metadata updates may overwrite financial ledger values | RESOLVED (Phase 1/1B) | Verified via automated suite |
| **F06** | Phase 1 | Transaction relationship mismatch, incomplete pagination, and incorrect aggregates | RESOLVED (Phase 1/1B) | Verified via automated suite |
| **F03** | Phase 2 | Wishlist purchase UUID becomes zero | RESOLVED (Phase 2/2B) | Verified via automated suite |
| **F04** | Phase 2 | Duplicate UUID entities during onboarding | RESOLVED (Phase 2/2B) | Verified via automated suite |
| **F05** | Phase 2 | Recurring and investment UUID contracts and scheduler idempotency keys | RESOLVED (Phase 2/2B) | Verified via automated suite |
| **F11** | Phase 2 | Financial instrument contract release verification after PR #2 | RESOLVED (Phase 2/2B) | Verified via automated suite |
| **F08** | Phase 3 | Goal withdrawal, signed transaction history, correction, and deletion | RESOLVED (Phase 3) | Flutter deposit/withdrawal UI, signed ledger history, reversal |
| **F09** | Phase 3 | Goal plan persistence for recurring amount, frequency, and source account | RESOLVED (Phase 3) | Laravel migration, model, validation, resources & Flutter roundtrip |
| **F10** | Phase 3 | Hidden recurring and investment routes and broken notification deep links | RESOLVED (Phase 3) | Recurring GoRouter routes registered, Profile entry points, deep links |
| **F12** | Phase 3 | Transaction detail, transaction correction/deletion, and wishlist editing/deletion | RESOLVED (Phase 3) | Detail sheet, atomic reversal, protected transfers/goals/opening balance |
| **F13** | Phase 3 | Transfer history, detail, and reversal | RESOLVED (Phase 3) | History screen, detail modal, atomic rollback, destination overdraft check |
| **F14** | Phase 4 | Complete investment domain, portfolio fields, and investment transaction features | IN PROGRESS (Phase 4) | Target of Phase 4 |
| **F15** | Phase 4 | Persistent receipt attachments and storage contract | IN PROGRESS (Phase 4) | Target of Phase 4 |
| **F18** | Phase 4 | Advanced account and goal fields | IN PROGRESS (Phase 4) | Target of Phase 4 |
| **F16** | Phase 5 | Notification pagination and legacy reminder bridge | IN PROGRESS (Phase 5) | Implementation & Verification |
| **F17** | Phase 5 | Error handling and financial fallback provenance | IN PROGRESS (Phase 5) | Implementation & Verification |
| **F19** | Phase 5 | Report date ranges, outdated help content, and legacy CTA cleanup | IN PROGRESS (Phase 5) | Implementation & Verification |
| **UI-5A**| Phase 5A | Flutter SDK Compatibility & Upgrade Evaluation (Owner-approved UI roadmap) | PENDING (Phase 5A) | Compatibility-driven evaluation of suitable stable SDK without downgrading existing toolchain (Flutter 3.44.4 / Dart 3.12.2) |
| **UI-5B**| Phase 5B | True Clear Liquid Glass Rendering (Owner-approved UI roadmap) | PENDING (Phase 5B) | Post-Phase 5 Shader & Visual Upgrade |
| **F20** | Phase 6 | Release evidence, Android E2E, expired session handling, scheduler, FCM, and production readiness | PENDING (Phase 6) | Awaiting Phase 6 |

---

## 2. DETAILED PHASE SPECIFICATIONS

### Phase 1 — Financial Integrity
- **F01**: Financial account deletion may destroy transaction history.
- **F02**: Investment balance mutations may execute twice.
- **F07**: Goal metadata updates may overwrite financial ledger values.
- **F06**: Transaction relationship mismatch, incomplete pagination, and incorrect aggregates.

### Phase 2 — UUID and API Contracts
- **F03**: Wishlist purchase UUID becomes zero.
- **F04**: Duplicate UUID entities during onboarding.
- **F05**: Recurring and investment UUID contracts and scheduler idempotency keys.
- **F11**: Financial instrument contract release verification after PR #2.

### Phase 3 — User Feature Completion
- **F08**: Goal withdrawal, signed transaction history, correction, and deletion.
- **F09**: Goal plan persistence for recurring amount, frequency, and source account.
- **F10**: Hidden recurring and investment routes and broken notification deep links.
- **F12**: Transaction detail, transaction correction/deletion, and wishlist editing/deletion.
- **F13**: Transfer history, detail, and reversal.

### Phase 4 — Investment and Data Persistence
- **F14**: Complete investment domain, portfolio fields, and investment transaction features.
- **F15**: Persistent receipt attachments and storage contract.
- **F18**: Advanced account and goal fields.

### Phase 5 — Notification, Reports, and Error Handling
- **F16**: Notification pagination and legacy reminder bridge.
- **F17**: Error handling and financial fallback provenance.
- **F19**: Report date ranges, outdated help content, and legacy CTA cleanup.

### Phase 5A — Flutter SDK Compatibility & Upgrade Evaluation (Owner-Approved UI Track)
- Compatibility-driven evaluation of a suitable stable SDK and modern toolchain (Gradle, AGP, Kotlin) without downgrading the existing toolchain (Flutter 3.44.4 / Dart 3.12.2) and ensuring zero regressions in the verified baseline.

### Phase 5B — True Clear Liquid Glass Rendering (Owner-Approved UI Track)
- Advanced backdrop filters, specular highlights, and real-time frosted glass shader pipeline across Tahan Dulu components.

### Phase 6 — Final E2E and Release Readiness
- **F20**: Release evidence, Android E2E, expired session handling, scheduler, FCM, and production readiness.

---

## 3. STRICT GOVERNANCE RULES
1. **Immutable Finding Definitions**: The finding codes F01 through F20 must never be altered, renamed, renumbered, or mapped to different features.
2. **No Unrelated Scope Infiltration**: Do not introduce multi-currency, CAGR calculations, or foreign exchange rate features under these IDs.
3. **Status Transitions**: Findings transition strictly through:
   `PENDING -> IN PROGRESS -> IMPLEMENTED - PARTIALLY VERIFIED -> RESOLVED & VERIFIED`.

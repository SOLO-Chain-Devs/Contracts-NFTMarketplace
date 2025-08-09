### Audit Update Log

This log records every change made during the audit and remediation process. Each entry captures what changed, why, and the impact.

---

### 2025-08-09 — Build configuration: enable optimizer and IR to fix compilation

- **Summary**: Enabled Solidity optimizer and IR-based compilation to resolve a "stack too deep" compiler error in `src/core/NFTMarketplace.sol` during `forge compile`.
- **Files changed**:
  - `foundry.toml`
    ```toml
    [profile.default]
    optimizer = true
    optimizer_runs = 200
    via_ir = true
    ```
- **Reasoning**: Solc codegen hit stack limits at a callsite (reported around `NFTMarketplace.sol:295`). Using IR (`via_ir`) with optimization is the recommended approach when refactoring to reduce locals is undesirable for audit stability.
- **Impact**: `forge compile` now succeeds with Solc 0.8.30. No Solidity source files were modified for this fix.
- **Notes / risks**:
  - IR-based compilation can slightly change bytecode layout and gas profiles; ensure tests and any size constraints still pass.
  - Keep optimizer settings consistent across environments to avoid analysis drift.

---

### How to append future updates

For each change, append a new section using this template:

```markdown
### YYYY-MM-DD — Short title of change

- **Summary**: What was changed.
- **Files changed**: List of files and a brief of edits; include small snippets if helpful.
- **Reasoning**: Why this change was made.
- **Impact**: Behavioral/security/gas/build impacts.
- **Notes / risks**: Any follow-ups, assumptions, or caveats.
```

---

### 2025-08-09 — Security review: `MarketplaceAdmin.sol`

- **Summary**: Performed a focused audit of `src/core/MarketplaceAdmin.sol` and its interactions via `MarketplaceStorage` and `NFTMarketplace`.
- **Findings**:
  - **Missing validator sanity checks (Medium)**: `setCurationValidator` accepts any address without validation. If set to an EOA or non-conforming contract while curation is enabled, marketplace flows using `onlyApprovedCollections` can revert (DoS). The storage defines `InvalidCurationValidator()` but it is unused.
  - **No events for critical param changes (Low)**: `setBidDuration` and `setCancellationFeePercentage` do not emit events, reducing on-chain observability of governance actions.
  - **Currency list gas pattern (Low)**: `setAcceptedCurrencies` removes entries with an O(n) scan per removal; batched calls can be gas-heavy. Owner-only; unlikely exploitable but worth noting for operational limits.
  - **Non-standard ERC20 risks (Medium, cross-file)**: Admin can approve arbitrary tokens; `MarketplaceLibrary.transferPaymentToAddress` does not check the boolean return of `IERC20.transfer`, which can silently fail for non-compliant tokens, potentially trapping funds. Suggest switching to `SafeERC20` or explicit return checks throughout.
  - **Curation enablement semantics (Informational)**: Enabling curation without a validator set is a no-op (guard checks `curationEnabled && curationValidator != address(0)`), which may be surprising operationally but not unsafe.
  - **ETH acceptance hardcoded (Informational)**: ETH is permanently accepted and cannot be disabled via `setAcceptedCurrencies` by design. Confirm this aligns with requirements.
- **Recommendations**:
  - In `setCurationValidator`, enforce `Address.isContract(_validator)` and attempt a bounded `staticcall` to `isApprovedCollection(address(0))` inside `try/catch`; revert with `InvalidCurationValidator()` on failure.
  - Emit events for `setBidDuration` and `setCancellationFeePercentage` changes (e.g., `BidDurationUpdated(old, new)` and `CancellationFeeUpdated(old, new)`).
  - Consider tracking `currencyIndex` mapping for O(1) removals if `currencyList` is expected to be large.
  - Migrate ERC20 interactions in `MarketplaceLibrary` to OpenZeppelin `SafeERC20` and explicitly reject fee-on-transfer tokens if not supported by business logic.
  - Optionally add a dedicated view to enumerate `currencyList` safely for UI/indexers.
- **Impact**: No code changes applied yet; this entry documents findings and proposed remediations.

---

### 2025-08-09 — View scalability improvements in `MarketplaceViews.sol`

- **Summary**: Added paginated and lighter-weight read functions to reduce RPC payload sizes and avoid O(n) scans on-chain for large datasets.
- **Files changed**:
  - `src/core/MarketplaceViews.sol`
    - New: `getActiveListingsPaged(uint256 startId, uint256 pageSize)` — scans a bounded id window and returns compacted active listings.
    - New: `getActiveListingIdsPaged(uint256 startId, uint256 pageSize)` — returns only active listing ids for minimal payloads.
    - New: `getActiveBidsRange(address token, uint256 tokenId, uint256 startAmount, uint256 endAmount)` — bounded scan of bids by amount range.
    - New: `getBid(address token, uint256 tokenId, uint256 tokenAmount)` — targeted single-bid fetch.
    - New: `getAcceptedCurrencies()` — returns `currencyList` for indexers/UIs.
    - Minor: simplified loops in `getActiveBids` and used dynamic array shrink via assembly for efficiency.
- **Reasoning**: Full scans can be expensive for indexers and may breach RPC/ABI response limits. Pagination allows clients to iterate safely.
- **Impact**: Interface additions only; no state changes. Compile remains green.
- **Notes / risks**: The functions still iterate within the provided window; clients should choose reasonable page sizes. Consider off-chain indexing for very large datasets.

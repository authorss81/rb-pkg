# Redblue Package Registry Index (`rb-pkg`)

The official global namespace registry and atomic lease arbitrator for the **Redblue** programming language ecosystem.

## How Namespace Arbitration Works
To prevent duplicate package synthesis across our 10 decentralized organizations (e.g. `rb-pkg-math` vs `rb-pkg-ai`):
1. **Canonical Normalization**: All package names are folded using PEP 503 / crates.io standard (lowercased, `-`, `.`, and spaces collapsed to `_`). `vector-2d` and `Vector2D` both resolve to canonical `vector2d`.
2. **Zero-Token HTTP Availability**: Workers check package availability via a 50ms HTTP `HEAD` request to `raw.githubusercontent.com/authorss81/rb-pkg/main/index/<prefix>/<name>.json`. No tokens or GraphQL queries are burned.
3. **Atomic Git Compare-and-Swap (CAS)**:
   - Workers claim exclusive rights by committing a lease to `leases/<canonical>.json`.
   - If two workers push at the same millisecond, Git's atomic push guarantees only one lands. The loser yields and selects another candidate.
4. **Domain Taxonomy**: Bounded by [`domain_taxonomy.json`](domain_taxonomy.json) so auditors operate strictly within their assigned domains.

## Directory Structure
- `index/`: 2-character sparse registry index holding package metadata.
- `leases/`: Temporary in-flight lease reservations.
- `domain_taxonomy.json`: Strict domain boundary catalog.
- `scripts/`: Tooling for canonical name normalization, availability checking, lease claiming, and package registration.

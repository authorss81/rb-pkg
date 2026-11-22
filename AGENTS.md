# AGENTS.md - Redblue Package Ecosystem (rb-pkg)

Instructions for autonomous coding agents developing, porting, and maintaining packages in the Redblue Package Registry (`rb-pkg`).

## The Bootstrap Philosophy: Battle-Tested Open-Source Porting

**Go, Rust, and Zig bootstrapped their entire ecosystem by porting battle-tested C, Python, and JavaScript/TypeScript libraries into pure native code.**

Redblue follows this exact proven historical playbook:

> **Core Mandate**: Autonomous agents must **prioritize porting proven, battle-tested open-source libraries** (MIT, Apache-2.0, BSD, ISC) into pure native Redblue over inventing custom algorithms or API surfaces from scratch.

### Why Porting Is Prioritized:
1. **Exponential Velocity**: Porting existing algorithms and data structures is 5–10× faster than designing from scratch. Architecture, edge cases, and algorithmic corner cases are already solved.
2. **Production Reliability**: Upstream libraries have millions of hours of production hardening, fuzzing, and bug fixes across global developer bases.
3. **Instant API Familiarity**: Developers migrating to Redblue will immediately feel at home with recognizable APIs (e.g. NumPy/SciPy matrix math, Lodash array utilities, Requests HTTP abstractions, date-fns formatting, Markdown parsers).
4. **Verifiable Test Parity**: Upstream test suites can be directly transcribed into Redblue's native `test` / `expect ... to be` syntax, guaranteeing 100% behavioral equivalence from day one.

---

## Licensing & Upstream Attribution Protocol

All ported packages must respect open-source licensing:
- Only port permissive licenses: **MIT, Apache-2.0, BSD-2/3-Clause, ISC, Unlicense, CC0**.
- **Never port copyleft code (GPL/AGPL)** unless creating an explicitly isolated copyleft project.
- **Mandatory Attribution**: Every ported package must declare its upstream origin in `rb.toml`:

```toml
[package]
name = "math_matrix"
version = "0.1.0"
description = "Pure Redblue matrix algorithms ported from NumPy/LinAlg"
license = "MIT"
authors = ["Redblue Ecosystem Contributors"]

[package.metadata.upstream]
source = "https://github.com/numpy/numpy"
original_project = "NumPy"
original_license = "BSD-3-Clause"
original_authors = ["NumPy Developers"]
port_notes = "Ported pure algorithms for 2D matrix multiplication, inversion, and decomposition."
```

---

## Technical Standards for Package Authors

### 1. Zero-Shim & Pure Native Rule
- Every package must be written in **100% pure Redblue (`.rb`)**.
- **No C shims, no Rust FFI bindings, no unsafe host hooks**. Packages execute directly on the Redblue VM.

### 2. Package Directory Layout
Every package in a category repository must adhere to the standard hierarchy:

```
packages/<pkg_name>/
├── rb.toml             # Package manifest (name, version, dependencies, upstream metadata)
├── README.md           # Documentation, examples, and porting credits
├── src/
│   ├── lib.rb          # Package root entry point
│   └── ...             # Internal submodules
└── tests/
    └── lib_test.rb     # Comprehensive unit tests ported from upstream
```

### 3. Delta Testing Protocol
- Phase and PR CI gates execute **only** the modified package's test suite:
  ```bash
  rb test packages/<pkg_name>/tests/
  ```
- Regression runs must complete within 1–3 seconds to maintain 24/7 autonomous throughput.

### 4. Handling Core Language Gaps (`[BLOCKED_BY_CORE]`)
- If a ported library requires syntax, built-ins, or VM capabilities not yet available in the Redblue compiler, **NEVER hack a workaround in the package repo**.
- Log the blocker in `docs/OUT_OF_SCOPE_FINDINGS_LEDGER.md` with status `[BLOCKED_BY_CORE]`.
- Mark the package phase deferred upstream and proceed to the next package.

---

## Target Capability Priority Matrix

When picking the next package capability from `capabilities/<concept_id>.json`, prioritize porting targets from these industry benchmarks:

| Domain | Benchmark Open-Source Libraries to Port |
| :--- | :--- |
| **Math & Science** | NumPy (array/matrix ops), decimal.js (arbitrary precision), complex.js |
| **Data & Algorithms**| Lodash (collections/arrays), PriorityQueue, Trie, RoaringBitmap, MinHeap |
| **Text & Parsing** | Marked / markdown-it (CommonMark parser), fast-csv, TOML/YAML parser |
| **Cryptography** | Pure Blake3, SHA-256/512, HMAC, ChaCha20, Ed25519 primitives |
| **Time & DateTime** | date-fns / Moment-like duration, timezone, and calendar calculations |
| **Networking & HTTP**| Requests-like HTTP client wrapper, URI/URL parser, QueryString builder |
| **Terminal & CLI** | Chalk / Colorette (ANSI styling), Cli-table (grid formatting), Progress bar |

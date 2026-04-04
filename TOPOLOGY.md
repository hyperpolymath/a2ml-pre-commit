<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> -->
# TOPOLOGY.md — a2ml-pre-commit

## Purpose

Pre-commit hook for validating `.a2ml` manifest files before commit. Checks SPDX headers, required identity fields, version presence, and attestation block structure. Integrates with the standard pre-commit framework.

## Module Map

```
a2ml-pre-commit/
├── hooks/
│   └── validate-a2ml.sh  # Main validation script
├── examples/             # Example .a2ml files (pass/fail)
├── docs/                 # Usage documentation
└── .pre-commit-hooks.yaml
```

## Data Flow

```
[git commit] ──► [pre-commit framework] ──► [validate-a2ml.sh] ──► [pass/fail]
                                                    │
                                          [.a2ml files in repo]
```

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This directory holds `generate_models.py`, a Python script that mechanically generates TypeSpec model files
under `../models-auto/` from `../.spec/draft-ietf-rpp-data-objects.yaml`. It is a code generator, not a
one-off transcription: re-running it after the YAML changes regenerates the output deterministically. See
`../PLAN-GENERATOR.md` at the repo root for the full design/rationale (data-type mapping table, cardinality
mapping, the `.reference`-model convention, the operation input/output modelling rules, and the living
"Upstream fixes needed" gap list).

Generated output is fully isolated from the hand-written spec: it never touches `../models/`,
`../interfaces/`, or `../main.tsp`. A separate root file `../test-auto-models.tsp`
(`import "./models-auto/main.tsp";`) is the only way to compile it, via `tsp compile test-auto-models.tsp`
from the repo root — never `tsp compile .` (that compiles the real service in `main.tsp`).

## Commands

```bash
# one-time setup
python3 -m venv .venv
.venv/bin/pip install -r tools/requirements.txt

# regenerate everything under models-auto/ (idempotent, safe to re-run)
.venv/bin/python3 tools/generate_models.py

# verify the generated output compiles (run from repo root)
tsp compile test-auto-models.tsp
```

There is no test suite for the generator itself — correctness is judged by (a) `tsp compile
test-auto-models.tsp` succeeding with zero diagnostics, and (b) the `WARNING:` lines the script prints to
stderr making sense for the current state of the source YAML.

**Pre-approved commands.** The commands below are allowlisted in `.claude/settings.local.json` for this
project. Stay within this set when iterating on the generator or its output — shape debugging/verification
around them rather than requesting new permissions:

```
python3 -m venv .venv
.venv/bin/pip install*
.venv/bin/python3 tools/generate_models.py*
.venv/bin/python3 -c*
.venv/bin/pip list *
tsp compile*
npx tsp compile*
mkdir -p models-auto*
rm -rf models-auto*
find models-auto*
find tools*
mkdir -p /tmp/tsp-test*
cd /tmp/tsp-test*
```

- Never `pip install` outside `.venv/` — this project requires a local venv for all Python tooling (never
  the system Python).
- Use `/tmp/tsp-test` as scratch space for isolated TypeSpec syntax experiments (e.g. checking whether some
  construct compiles) that shouldn't touch `models-auto/` or trigger the real `main.tsp` service compile.
- To regenerate from a clean slate, either `rm -rf models-auto` first or just re-run
  `generate_models.py` — it overwrites in place.

## Warnings are the point, not noise

**The generator prints a `WARNING:` line to stderr for every normalization, fuzzy name match, or
magic-value interpretation it applies**, plus a summary count at the end of the run. This is by design (the
plan's "no silent inference" principle): the source YAML is prose-derived and under-structured in several
places (see the "Upstream fixes needed" table in `PLAN-GENERATOR.md`), so the generator has to guess in
those places, and every guess must stay visible rather than being silently papered over. A clean run still
prints ~100+ warnings on the current YAML — that is expected. Scan the warnings after every run, especially
after the source YAML changes, to catch new content that hits an existing guess in an unexpected way (e.g.
a newly-added object whose name doesn't fuzzy-match anything, or an operation whose `input`/`output` prose
doesn't match any of the known patterns and falls through to `unknown`).

Do not add code that silently "fixes up" an inconsistency instead of warning about it — that defeats the
entire point of this generator existing before the upstream YAML-generation script
(`check_iana_consistency.py`) can be improved to carry the same information structurally.

## Architecture of `generate_models.py`

The script is a single flat module, organized top-to-bottom as: warning collection → file writer → naming
helpers → cardinality/visibility mappers → `ObjectGraph` → name resolution → `data_type` → TypeSpec type
resolution → field emission → per-kind emitters (component / reference / object model / operation
input-output) → static building blocks (common scalars, association wrappers, external placeholders) →
`main.tsp`/`test-auto-models.tsp` emission → `main()` driver. Read it in that order; each section only
depends on what comes before it.

Things that aren't obvious from a single function in isolation:

- **`ObjectGraph.namespace_for(id)` vs. `ObjectGraph.model_ref_for(id)`** are not interchangeable.
  `namespace_for` returns the `rpp.gen.<id>` namespace path, used when appending `.reference` or an
  operation name (`rpp.gen.<id>.create.input`). `model_ref_for` returns the *type reference to the bare
  full-object model* — `rpp.gen.<id>` for components (plain `model <id>` directly in `rpp.gen`), but
  `rpp.gen.<id>.Model` for processes/resources. The split exists because TypeSpec forbids a model and a
  sibling namespace sharing a name, so the plain full-object model for every process/resource is named
  `Model` and nested inside that object's own namespace (alongside `reference` and each operation's
  namespace) rather than living directly in `rpp.gen`. Getting this wrong produces a `duplicate-symbol` or
  `invalid-ref` compile error, not a silent wrong type.
- **`emit_field` returns unindented text**; every caller splices it into a template and must call
  `indent_block(text, level)` to indent it to the right nesting depth before splicing. Don't hand-indent
  field text inline in a new template — use `indent_block` so nesting depth changes stay correct
  automatically.
- **The Update-operation default** (`resolve_operation_input_fields`, `op_id == "update"`) spreads
  `.reference` (the unique-id field) plus every `read-write` element — except the unique-id field itself
  when it also happens to be `read-write` on that object (e.g. `host.hostName`), which is excluded from the
  second spread to avoid a `duplicate-property` compile error. This exclusion fires conditionally and
  prints its own `WARNING` only when the collision actually applies (e.g. not for `domainName`, whose
  unique-id field `name` is `create-only`, not `read-write`).
- **`UNIQUE_ID_TABLE`** is a hardcoded Python dict, not derived from the YAML — the YAML has no
  `unique_identifier` field (see gap #1 in `PLAN-GENERATOR.md`'s upstream-fixes table). If a new
  Process/Resource object is added upstream without a corresponding table entry, the generator warns and
  falls back to that object's first element, which is very likely wrong — treat that specific warning as
  "go update `UNIQUE_ID_TABLE` now," not as background noise.
- **Name resolution** (`resolve_object_name`) tries an exact match against every object's `name:` field
  first, then falls back to stripping `" Object"`/`" Data Object"` suffixes and fuzzy-matching against
  `identifier`s. Every fuzzy fallback warns. If you're chasing down why some `data_type` string resolved to
  the wrong object (or to `unknown`), start here, not in `resolve_data_type`.
- **Association wrappers** (`Aggregation[X]`, `Composition[X]`, etc.) only resolve their inner type to
  `X.reference` when `X` is a process or resource *and* the wrapper kind is reference-semantics
  (`ASSOCIATION_WRAPPERS[wrapper][1]`). Composition-family wrappers always keep the full inline type, even
  when `X` is itself a process/resource — this is intentional (composition = owned/embedded data), not a
  missed case.
- **One model per file** is a hard invariant (`write_tsp` is called once per declaration). `main.tsp` is
  regenerated last, from `_written_files` (populated as a side effect of every `write_tsp` call during the
  run), specifically so its import list can never drift from what was actually written on disk.
- **Every generated file carries its own precise `import` lines** for exactly the other generated files it
  references — it does not rely on a consumer having imported `main.tsp` first. This means any single file
  under `models-auto/` (e.g. `models-auto/resources/domain-name/model.tsp`) can be `tsp compile`d directly
  and will resolve on its own, since TypeSpec imports are transitive (if A imports B and B imports C,
  compiling A also pulls in C). `main.tsp` still exists and is still regenerated as a full manifest/one-stop
  import for convenience, but it is no longer load-bearing for any individual file's correctness.
  Mechanically: `resolve_data_type` (and `owning_object_full_field_defs`/`resolve_operation_input_fields`/
  `resolve_operation_output`) take an optional `deps` set and add a `FileRegistry` key to it every time they
  resolve a type that lives in another generated file; `write_tsp(path, body, deps=...)` turns that set into
  sorted relative `import "...";` lines prepended to the file. `FileRegistry` (built once via
  `build_registry(graph)` before any emission, plus external-type entries registered right after the
  pre-scan) maps a logical key — `component:<id>`, `model:<id>`, `reference:<id>`, `op-input:<id>:<op>`,
  `op-output:<id>:<op>`, `common:<name>`, `assoc:<name>`, `external:<spec>:<type>` — to the relative path
  `write_tsp` will (or already did) write it to, so a dependency can be resolved to an import path even
  before the target file exists on disk.
  - **Pitfall already hit once:** inside the `Aggregation[X]`-family branch of `resolve_data_type`, the code
    resolves `X`'s bare type first (adding a `model:<X>` dep) and then, for reference-semantics wrappers,
    swaps that for a `reference:<X>` dep via `discard`+`add`. Do this swap against a **local scratch `deps`
    set**, not the caller's shared set — the shared set accumulates dependencies from every field in the
    whole file, so discarding directly against it can silently remove a `model:<X>` dependency that a
    *different* field in the same file still legitimately needs (e.g. `domainName.registrant: Contact
    Object` needs `contact/model.tsp` even though the sibling field `domainName.contacts:
    LabelledAggregation[Contact Object]` only needs `contact/reference.tsp`). If you add a new branch that
    resolves an inner type and then conditionally changes what it points to, follow the same
    resolve-into-a-scratch-set-then-`deps.update()` pattern.

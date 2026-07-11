# PLAN-GENERATOR.md

## Goal

Mechanically generate TypeSpec model files from `.spec/draft-ietf-rpp-data-objects.yaml`
(itself generated from the IETF draft text — see its own header comment) so that the
draft's data model can be regenerated over and over as the spec evolves, without hand
re-typing every field.

This is a **code generator**, not a one-off transcription: a Python script reads the YAML
and writes TypeSpec (`.tsp`) files. Re-running it after the YAML is updated regenerates
the output deterministically.

**Scope of this iteration:** all building-block (component/process/resource) data
models, `.reference` id-only models for every Process/Resource object, and input/output
models for every operation. **Non-goals:** interfaces/routes, real `@example` wiring,
enum extraction from prose, real RDATA/JSContact modelling.

## Isolation from the existing project

- Generated output lands entirely under `./models-auto/`, a new directory, so it never
  touches `./models/`, `./interfaces/`, or `main.tsp`.
- A new root file `test-auto-models.tsp` imports `./models-auto` and is used only to
  verify `tsp compile` succeeds against the generated output. It is not wired into
  `main.tsp` and does not affect the real OpenAPI/JSON Schema emit.
- The generator script lives at `tools/generate_models.py`, with its Python dependency
  (`pyyaml`) installed into a project-local venv (`.venv/`) — never into the system
  Python. `tools/README.md` documents `python3 -m venv .venv && .venv/bin/pip install -r
  tools/requirements.txt` as the setup step.

## Guiding principle: no silent inference

Per explicit instruction: **every** normalization of an inconsistency in the source YAML,
and **every** decision driven by a "magic value" (an empty string, a specific literal
like `"None"`, a name that doesn't exactly match any object), must print a `WARNING:`
line to stderr when the generator runs, in addition to (where useful) a `// TODO:` or
`// NOTE:` comment in the generated `.tsp` output at the call site. Nothing gets fixed
up quietly. This applies to, at least:

- data-type name resolution fuzzy-matching (§ Name resolution)
- the hardcoded unique-identifier table (§ `.reference` models)
- treating an empty `input`/`output` string as "apply the §2.6.2 uniform-interface
  default" (§ Operation input/output models)
- any other free-text `input`/`output` string that has to be pattern-matched against a
  known phrase (e.g. `"... or nothing"`, `"Object Identifier, X"`) rather than parsed
  structurally

The generator collects all warnings and also prints a summary count at the end of the
run, so a clean run is easy to distinguish from one that papered over new spec content.

## Source model recap (`.spec/draft-ietf-rpp-data-objects.yaml`)

The YAML has three top-level lists, each entry describing one object:

- `components` — reusable data-only structures, no operations (Period, ProvMetadata,
  Status, DnsRecord, DnsControls, DnsData, AuthInfo, Disclose, RestoreReport,
  OrganisationRole, Processes).
- `processes` — long-running operations bound to an owner object (TransferProcess,
  RestoreProcess, RenewProcess, CreateProcess, DomainCreateProcess). Has `operations`.
- `resources` — top-level provisioned objects (DomainName, Contact, Host, Organisation,
  User). Has `operations`.

Each element has: `identifier`, `cardinality` (`1` | `0-1` | `0+` | `1+` | `1-2`),
`mutability` (`create-only` | `read-only` | `read-write`), `data_type` (free text, see
below), `description`.

Each operation has: `identifier`, `name`, `description`, `authorisation` (list, unused
this iteration), `input` (free string, often `''`), `output` (free string, often `''`),
`params` (transient elements: `identifier`, `cardinality`, `data_type`, `description` —
no `mutability`, since transient params aren't persisted).

**Important gap confirmed by inspection:** the YAML has **no `unique_identifier` field**
anywhere in its schema (verified: the full set of keys used anywhere in the document is
`{anchor, cardinality, components, constraints, data_type, description, elements,
heading, identifier, input, mutability, name, notes, object_type, operations, output,
params, preamble, processes, resources, section_notes, subsections}` — no
`unique_identifier`). The clean draft text *does* have an explicit "Unique Identifier:
<field>" bullet per Process/Resource object, but this was not carried into the
structured YAML. See § `.reference` models for how this is handled (hardcoded table +
warning).

## Key design decisions (confirmed with user)

1. **Generator is Python**, emits `.tsp` text directly (string templates — TypeSpec has
   no Python codegen library to target).
2. **Associations become generic wrapper models**, defined once in
   `models-auto/associations.tsp`:
   - `model Aggregation<T> { ... }`
   - `model Composition<T> { ... }`
   - `model LabelledAggregation<T> { label: string, item: T }`
   - `model DictionaryAggregation<T> is Record<T>`
   - `model LabelledComposition<T> { label: string, item: T }`
   - `model DictionaryComposition<T> is Record<T>`
   First-pass approximation — reference-vs-inline semantics are refined later.
3. **Aggregations target `.reference`, not the full object.** Per §5.1, an Aggregation
   is a relation between two *independent* objects — conceptually a pointer. So every
   `Aggregation[X]` / `LabelledAggregation[X]` / `DictionaryAggregation[X]` where `X` is
   a Data Object or Process Object resolves its generic argument to `X`'s `.reference`
   model, not the full `X` model. `Composition[X]` / `LabelledComposition[X]` /
   `DictionaryComposition[X]` keep the full inline `X` (composition = owned, embedded
   data, e.g. `dnsData.records: Composition<DnsRecord>`).
4. **Scope**: generate models for all components + processes + resources, **plus**:
   - a `.reference` model per Process/Resource object (id-only)
   - input/output models per operation (see below)
5. **Mutability → `@visibility`**, matching `models/common.tsp`'s convention:
   - `read-only` → `@visibility(Lifecycle.Read, Lifecycle.Query)`
   - `create-only` → `@visibility(Lifecycle.Create, Lifecycle.Read, Lifecycle.Query)`
   - `read-write` → no visibility decorator
   Transient operation params have no `mutability` — they get no visibility decorator
   (their availability is inherently scoped to the one operation's input/output model).
6. **Script location**: `tools/generate_models.py`, run via a project venv.

## Data type → TypeSpec mapping

| YAML `data_type`                          | TypeSpec                                   |
|--------------------------------------------|---------------------------------------------|
| `String`                                    | `string`                                     |
| `Integer`                                   | `int32`                                      |
| `Boolean`                                   | `boolean`                                    |
| `Decimal`                                   | `decimal`                                    |
| `Date`                                      | `plainDate`                                  |
| `Timestamp`                                 | `utcDateTime`                                |
| `URL`                                       | `url`                                        |
| `Binary`                                    | `bytes`                                      |
| `Object`                                    | `Record<unknown>` (TODO refine per-usage) |
| `Dictionary[X]`                             | `Record<X>`                                  |
| `Identifier`, `Identifier.` (trailing dot)  | `rpp.auto.common.Identifier` (alias to `string`) |
| `Client Identifier`                         | `rpp.auto.common.ClientIdentifier` (alias to `string`) |
| `Phone Number`                              | `rpp.auto.common.PhoneNumber` (alias to `string`) |
| `External:<spec>:<type>`                    | `rpp.auto.external.<Spec_PascalCase><Type>` — opaque placeholder model, one per distinct `spec:type` pair actually referenced (currently only `External:RPP-JSContact-Profile:Card`) |
| `<Name> Object`, `<Name> Data Object`, plain object-name references (e.g. `Contact Object`, `Organisation Data Object`, `Period Object`) | Reference to the matching generated model (see "Name resolution") |
| `<Name> Reference` (e.g. `Organisation Data Object Reference`) | Resolve `<Name>` as above, then use **its `.reference` model** instead of the full model — this is the one case where "Reference" in the data_type string is *not* noise, it's a signal to use the id-only model. **Distinguish this from case above** (previously conflated — corrected in this revision). |
| `Aggregation[X]`                            | `Aggregation<X.reference>` if X is a Data/Process Object, else `Aggregation<X>` |
| `Composition[X]`                            | `Composition<X>` (always full/inline) |
| `LabelledAggregation[X]`                    | `LabelledAggregation<X.reference>` if X is a Data/Process Object, else `LabelledAggregation<X>` |
| `DictionaryAggregation[X]`                  | `DictionaryAggregation<X.reference>` if X is a Data/Process Object, else `DictionaryAggregation<X>` |
| `LabelledComposition[X]`                    | `LabelledComposition<X>` (always full/inline) |
| `DictionaryComposition[X]`                  | `DictionaryComposition<X>` (always full/inline) |

**Name resolution:** the YAML is inconsistent (`Identifier.` with a trailing dot,
`Disclose Object.` with a trailing dot, `Contact Object` vs. actual object name
`Contact Data Object`). The generator normalizes by: stripping a trailing `.`, then
trying an exact match against every known object's `name:` field, falling back to a
fuzzy match (strip `" Object"`/`" Data Object"` suffix and compare against identifiers)
if no exact match is found. **Every fuzzy-match fallback emits a `WARNING:`** (per the
no-silent-inference principle) naming the original string and what it resolved to.
Unresolved references are emitted as `unknown` with a `// TODO: unresolved data_type
"<original>"` comment plus a `WARNING:` on stderr, so `tsp compile` still succeeds and
the gap stays visible/greppable.

The ` Reference` suffix is checked **first**, stripped, the remainder resolved via the
above, and then the target's `.reference` model is used — with a `WARNING` emitted
confirming "Reference suffix" was the detected signal (since this is a magic-string
convention, not a structured flag in the YAML).

## Cardinality mapping

| Cardinality | TypeSpec shape |
|---|---|
| `1`   | `field: T` |
| `0-1` | `field?: T` |
| `0+`  | `field?: T[]` |
| `1+`  | `field: T[]` (TODO: no min-length constraint expressed yet) |
| `1-2` | `field: T[]` (TODO: no min/max-length constraint expressed yet — e.g. Contact's `contactInfo`) |

## `.reference` models (new)

For **every** Process Object and every Resource Object (not Component Objects — those
have no independent identity/Unique Identifier per §1.1), emit a second model containing
only its unique-identifier field, using the nested-namespace convention below, e.g.:

```tsp
namespace rpp.auto {
  namespace domainName {
    model reference {
      name: rpp.auto.common.Identifier;
    }
  }
}
```

**Unique-identifier source:** since the YAML has no structured field for this (see gap
noted above), the generator uses a **hardcoded table**, sourced from the "Unique
Identifier:" bullets currently in `.spec/draft-ietf-rpp-data-objects.clean.txt`:

| object identifier      | unique-id field |
|-------------------------|-----------------|
| `transferProcess`       | `processId`     |
| `restoreProcess`        | `processId`     |
| `renewProcess`           | `processId`     |
| `createProcess`          | `processId`     |
| `domainCreateProcess`    | `processId`     |
| `domainName`             | `name`          |
| `contact`                | `id`            |
| `host`                   | `hostName`      |
| `organisation`           | `id`            |
| `user`                   | `id`            |

The generator **warns** if:
- a Process/Resource object identifier from the YAML is not present in this table
  (new object added to the spec — table needs a manual update), or
- a table entry's field name is not found among that object's actual `elements`
  (table is stale relative to the current YAML).
In either case it still emits a best-effort `.reference` model (falling back to the
object's first element if the table lookup fails) so `tsp compile` doesn't break, but
flags it loudly so the gap gets fixed rather than trusted.

## Operation input/output models (new)

For every operation on every Process/Resource object, emit two nested-namespace models
under that operation's own namespace:

```tsp
namespace rpp.auto {
  namespace domainName {
    namespace read {
      model input { ... }
      // output omitted here: identical to the plain domainName model, reuse that directly
    }
    namespace transferCreate {
      model input { transferPeriod?: rpp.auto.Period }
      model output { ... }   // only emitted when distinct from the plain type
    }
  }
}
```

Naming/collapsing rule (per user's convention "`<type>.<operation>` for input,
`<type>.<operation>.output` only if specific, otherwise just `<type>`"):

- **Input always gets its own generated model**, `<type>.<operation>.input`, even when
  its shape is exactly the uniform-interface default — every operation stays
  individually addressable.
- **Output collapses to reusing the bare `<type>` model** whenever the resolved output
  shape is exactly "the full object, read-write and read-only fields" (the §2.6.2
  default for Create/Read/Update, and the same for process Create/Read). A distinct
  `<type>.<operation>.output` model is only generated when the operation's output is
  provably different — e.g. Delete ("Object or nothing" — modelled as
  `<type>.<operation>.output` being `<type> | void`... see TODO on modelling "nothing"),
  or an operation with genuinely no persisted-object output.

**Handling the `input`/`output` free-text field itself (magic-value parsing):**

The YAML's `input`/`output` per operation is unstructured prose, not a machine-readable
type reference, in the majority of cases. The generator applies these rules, each of
which **emits a `WARNING`** because it is pattern-matching english text rather than
reading a structured field:

| Literal `input`/`output` string pattern | Interpretation | Warn? |
|---|---|---|
| `''` (empty) as `input`, operation identifier is `create`/`renewCreate`/`transferCreate` | §2.6.2 Create default: create-only + read-write fields of the *owning* object | yes — "applied Create default for empty input" |
| `''` as `input`, operation identifier is `read` | §2.6.2 Read default: object identifier only → reuse `<type>.reference` | yes |
| `''` as `input`, operation identifier is `update` | §2.6.2 Update default: identifier + read-write fields | yes |
| `''` as `input`, operation identifier is `delete` | §2.6.2 Delete default: object identifier only → reuse `<type>.reference` | yes |
| `''` as `output` (any op) | §2.6.2 default: full object (read-write + read-only) → reuse bare `<type>` | yes |
| `'None'` | Explicitly no input — empty model `{}` | yes (still a literal-string match) |
| Exact object name (e.g. `'Transfer Process Object'`) | Resolve via the same Name Resolution logic as element `data_type` | yes, reusing that resolver's own warning |
| `'X or nothing'` (e.g. `'Transfer Process Object or nothing'`) | Output type `X | void` — TODO: confirm `void`/no-body modelling convention in this codebase (`models/common.tsp` doesn't yet have a precedent) | yes |
| `'Object Identifier'` / `'Object Identifier, X'` | id (`<type>.reference`) optionally combined with `X` — modelled as an `input` model with `id` field plus a spread of `X` if given | yes |
| Anything else unrecognized | Emit `unknown`, `// TODO: unparsed input/output string "<original>"`, and warn | yes |

Transient `params` for an operation (e.g. `hostsFilter`, `urgent`, `transferPeriod`,
`restoreReport`, `reason`) are always spread as **additional fields** into that
operation's `input` model (on top of whatever the base input resolves to), each mapped
through the same data_type/cardinality mapping as regular elements (minus visibility,
since params have no `mutability`).

## Output structure (`models-auto/`)

**Rule: one model per file.** Every `model`/`scalar`/`union` declaration — including
each per-object `reference` model and each per-operation `input`/`output` model — gets
its own `.tsp` file. Files are grouped into folders by kind, mirroring the YAML's own
`components`/`processes`/`resources` sections plus the cross-cutting building blocks.
A single `models-auto/main.tsp` re-exports everything (one `import` per file) so
consumers (and `test-auto-models.tsp`) only ever need one import line.

```
models-auto/
├── main.tsp                          # imports every file below, in dependency order
├── common/
│   ├── identifier.tsp                # scalar Identifier
│   ├── client-identifier.tsp         # scalar ClientIdentifier
│   └── phone-number.tsp              # scalar PhoneNumber
├── associations/
│   ├── aggregation.tsp                # model Aggregation<T>
│   ├── composition.tsp                # model Composition<T>
│   ├── labelled-aggregation.tsp       # model LabelledAggregation<T>
│   ├── dictionary-aggregation.tsp     # model DictionaryAggregation<T>
│   ├── labelled-composition.tsp       # model LabelledComposition<T>
│   └── dictionary-composition.tsp     # model DictionaryComposition<T>
├── external/
│   └── rpp-jscontact-profile-card.tsp # one file per distinct External:<spec>:<type>
├── components/                        # one folder tier, no operations/reference here
│   ├── period.tsp
│   ├── prov-metadata.tsp
│   ├── status.tsp
│   ├── dns-record.tsp
│   ├── dns-controls.tsp
│   ├── dns-data.tsp
│   ├── auth-info.tsp
│   ├── disclose.tsp
│   ├── restore-report.tsp
│   ├── organisation-role.tsp
│   └── processes.tsp                  # the "Processes Object" component (container), not to
│                                       # be confused with processes/ below (process *objects*)
├── processes/
│   ├── transfer-process/
│   │   ├── model.tsp                  # the plain TransferProcess model
│   │   ├── reference.tsp              # .reference
│   │   ├── transfer-create/
│   │   │   └── input.tsp              # no distinct output → reuses model.tsp
│   │   ├── transfer-read/
│   │   │   └── input.tsp              # output reuses model.tsp
│   │   ├── transfer-delete/
│   │   │   ├── input.tsp
│   │   │   └── output.tsp             # "...or nothing" — distinct shape
│   │   ├── transfer-approve/
│   │   │   └── input.tsp
│   │   └── transfer-reject/
│   │       └── input.tsp              # includes transient `reason` param
│   ├── restore-process/
│   │   ├── model.tsp
│   │   ├── reference.tsp
│   │   ├── create/
│   │   │   └── input.tsp              # includes transient `restoreReport` param
│   │   ├── read/
│   │   │   └── input.tsp
│   │   └── report/
│   │       └── input.tsp              # includes transient `restoreReport` param
│   ├── renew-process/
│   │   ├── model.tsp
│   │   ├── reference.tsp
│   │   └── renew-create/
│   │       └── input.tsp
│   ├── create-process/
│   │   ├── model.tsp
│   │   ├── reference.tsp
│   │   ├── create/
│   │   │   └── input.tsp
│   │   └── read/
│   │       └── input.tsp
│   └── domain-create-process/
│       ├── model.tsp
│       ├── reference.tsp
│       ├── create/
│       │   └── input.tsp
│       └── read/
│           └── input.tsp
└── resources/
    ├── domain-name/
    │   ├── model.tsp
    │   ├── reference.tsp
    │   ├── create/
    │   │   └── input.tsp
    │   ├── read/
    │   │   └── input.tsp               # includes transient `hostsFilter` param
    │   ├── update/
    │   │   └── input.tsp               # includes transient `urgent` param
    │   ├── delete/
    │   │   ├── input.tsp
    │   │   └── output.tsp              # "...or nothing"
    │   ├── renew-create/
    │   │   └── input.tsp
    │   └── transfer-create/
    │       ├── input.tsp               # includes transient `transferPeriod` param
    │       └── output.tsp
    ├── contact/
    │   ├── model.tsp
    │   ├── reference.tsp
    │   ├── create/input.tsp
    │   ├── read/input.tsp
    │   ├── update/input.tsp
    │   └── delete/{input,output}.tsp
    ├── host/
    │   ├── model.tsp
    │   ├── reference.tsp
    │   ├── create/input.tsp
    │   ├── read/input.tsp
    │   ├── update/input.tsp
    │   └── delete/{input,output}.tsp
    ├── organisation/
    │   ├── model.tsp
    │   ├── reference.tsp
    │   ├── create/input.tsp
    │   ├── read/input.tsp
    │   ├── update/input.tsp
    │   └── delete/{input,output}.tsp
    └── user/
        ├── model.tsp
        ├── reference.tsp
        ├── create/input.tsp
        ├── read/input.tsp
        ├── update/input.tsp
        └── delete/{input,output}.tsp
```

Notes:
- `output.tsp` is only present where the operation's output is provably distinct from
  the bare `model.tsp` (per the collapsing rule above) — most `read`/`update`/`create`
  operations have no `output.tsp` at all and their namespace's `output` name resolves
  (via a TypeSpec `alias`, not a duplicate model) to the object's plain model.
- Folder names are kebab-case of the object/operation `identifier` (TypeSpec is
  case-sensitive and dashes aren't valid in identifiers, but they're fine in file/folder
  names — the `model`/`namespace` names inside each file stay camelCase, matching the
  YAML `identifier`).
- Each generated file starts with a header comment: `// AUTO-GENERATED by
  tools/generate_models.py from .spec/draft-ietf-rpp-data-objects.yaml — do not hand-edit.`
- `models-auto/main.tsp` is itself generated (import list derived from the same object
  graph the generator walks), not hand-maintained, so it can never drift from the actual
  file set.

`test-auto-models.tsp` (repo root):
```tsp
import "./models-auto/main.tsp";
```
Compiled standalone via `tsp compile test-auto-models.tsp` — separate from the real
`main.tsp` service compile used by CI.

## Upstream fixes needed (living section — keep up to date)

**Goal: a fully deterministic generation pipeline.** Every entry below is something
this generator currently has to guess, pattern-match, or hardcode *because the
upstream source (the yaml-generation script `check_iana_consistency.py`, or the draft
text it reads) doesn't carry the information in structured form*. Fixing the upstream
source removes the corresponding workaround (and its `WARNING`) from this generator.
**Update this list whenever a new gap is found** — don't let workarounds accumulate
silently; if the generator grows a new fuzzy-match or magic-string rule, it gets an
entry here too.

| # | Gap | Where it bites | Upstream fix needed | Current workaround here |
|---|-----|-----------------|----------------------|--------------------------|
| 1 | No `unique_identifier` field per Process/Resource object, even though the draft text has an explicit "Unique Identifier: `<field>`" bullet | `.reference` model generation | Add `unique_identifier` to the YAML schema in `check_iana_consistency.py`, sourced from that bullet | Hardcoded Python table in the generator + `WARNING` if stale/missing (§ `.reference` models) |
| 2 | `data_type` is free-text prose, not a structured type reference (mixes primitive names, `"<Name> Object"`, `"<Name> Data Object"`, trailing punctuation, and an ad hoc `"<Name> Reference"` suffix convention all in one string field) | Every element/param type resolution | Emit `data_type` as a structured value: `{kind: primitive\|component\|process\|resource\|association\|external, ref: <canonical identifier>, by_reference: bool}` instead of a sentence | Name-normalization + fuzzy match + suffix stripping, all warned (§ Name resolution) |
| 3 | Trailing-dot typos in `data_type` (`"Identifier."`, `"Disclose Object."`) | Contact's `id`/`disclose` elements | Fix the two typos at the source (draft text, then regenerate YAML) | Strip trailing `.` before matching, warned |
| 4 | Object `name:` strings don't consistently match the phrases used to *reference* them elsewhere (e.g. object is named "Contact Data Object" but referenced as `"Contact Object"`; "Disclose" vs. referenced as `"Disclose Object."`) | Every cross-reference | Make in-body references consistently use the exact `name:` string (or better. use the `identifier`, which is already stable/machine-readable, as the reference token instead of prose names) | Fuzzy suffix-stripping match, warned (§ Name resolution) |
| 5 | `"<Name> Reference"` is a real signal (use the id-only model) but is indistinguishable, as a string, from any other prose that happens to end in the word "Reference" | `user.organisationId` (`Organisation Data Object Reference`) | Same fix as #2 — a structured `by_reference: bool` flag instead of a suffix convention | Suffix-match on literal `" Reference"`, warned |
| 6 | Operation `input`/`output` are free prose, and are empty strings (`''`) in the overwhelming majority of cases, implicitly meaning "apply the §2.6.2 uniform-interface default for this operation's identifier (create/read/update/delete)" | Every CRUD operation's input/output modelling | Either populate `input`/`output` explicitly for every operation (even when it's just restating the §2.6.2 default), or add a structured `uses_uniform_interface_default: bool` field so "empty" isn't itself the signal | Identifier-name-based default table + `WARNING` every time the default is applied (§ Operation input/output models) |
| 7 | Non-empty `input`/`output` values are still prose, not structured (`'None'`, `'Transfer Process Object'`, `'Transfer Process Object or nothing'`, `'Object Identifier, Restore Report Object'`) | `restoreProcess`/`transferProcess` operations | Structure these the same way as #2 — a list of `{ref, cardinality, by_reference}` for output, similarly for input, instead of a sentence | Regex/phrase table with a warning per pattern (§ Operation input/output models) |
| 8 | No machine-readable way to know an operation's output is "the object itself, or nothing" (HTTP 204-style) vs. a distinct payload shape | `delete`, `transferDelete` outputs | Add a structured `output: { ref: <type>, optional: true }` instead of embedding "or nothing" in prose | Literal `"... or nothing"` phrase match → union-with-void, warned; no settled `void` convention yet either (see rough-edges TODO) |
| 9 | Transient operation `params` carry no `mutability`, which is correct (they're not persisted) but means the generator has no signal to distinguish "always required in the request" from "optional" beyond `cardinality` alone — usually fine, but worth confirming intentional | Params like `urgent`, `hostsFilter` | None strictly needed — just confirm `cardinality` alone is meant to be sufficient for params (no upstream change anticipated, listed here to track the assumption) | Params mapped via cardinality only, same as elements minus visibility |
| 10 | Enum-like allowed values (Status `label`, Period `unit`, `trStatus`, `restoreStatus`, organisation `status`/roles) are documented only as prose inside `constraints` (including deeply nested bulleted lists for Status), not as a structured value list | Would block generating real TypeSpec `enum`/`union` types instead of `string` | Add a structured `allowed_values: [...]` to elements/constraints where the draft already enumerates a closed set | Not attempted this iteration — fields stay plain `string` (see rough-edges TODO) |
| 11 | `cardinality` has no associated min/max-length numeric fields for the `1+`/`0+`/`1-2` cases (e.g. Contact's `contactInfo` is "1-2" but nothing states *why* 2 is the cap, or expresses it structurally beyond the string) | Array constraint modelling | Add explicit `min`/`max` numeric fields alongside (or instead of) the `cardinality` string | Cardinality string parsed positionally (`N`, `N-M`, `N+`), no `@minItems`/`@maxItems` emitted yet |

Whenever a new inconsistency or magic-value dependency is discovered while extending
this generator, add a row here (and a corresponding `WARNING` in the code) *before*
writing the workaround, not after — this table is the single place tracking what would
need to change upstream to make the whole pipeline deterministic end-to-end.

## Known rough edges / TODOs for later iterations

- [ ] Decide real (non-placeholder) structure for `Aggregation`/`Composition`/etc. —
      whether they should carry a discriminator for "by reference" vs "inline", and how
      `Direct Access` (§2.4) should be represented.
- [ ] `Object` data type (free-form) is currently `Record<unknown>` — `dnsRecord.rdata`
      needs real per-record-type modelling later (RDATA structures for NS/A/AAAA/DS/DNSKEY).
- [ ] External type placeholders (`External:RPP-JSContact-Profile:Card`) are empty
      stand-ins; real JSContact `Card` modelling is out of scope here.
- [ ] `1+`/`1-2`/`0+` cardinalities don't yet carry min/max array-length constraints.
- [ ] "Object or nothing" outputs (Delete operations, transfer Delete/Cancel) need a
      settled `| void`-equivalent convention — check how the hand-written
      `interfaces/rpp/entitycollections` model "no body" responses and mirror that if
      it translates cleanly to a bare model context.
- [ ] Enum-like string constraints buried in prose (e.g. Status `label` allowed values,
      Period `unit` "y"/"m", TransferProcess `trStatus` values) are not extracted into
      TypeSpec `enum`/`union` types in this iteration — fields stay plain `string`.
      Tracked upstream as gap #10 above.
- [ ] No `@doc` extraction from `description` yet.
- [ ] No example values wired via `@example`.
- [ ] The hardcoded unique-identifier table (§ `.reference` models) is a maintenance
      liability. Tracked upstream as gap #1 above.
- [ ] Authorisation semantics (`authorisation` list per operation) are not modelled.

## Work plan / TODOs (this iteration)

1. [ ] `tools/generate_models.py`: YAML loader, warning-collection helper (prints
       `WARNING: ...` immediately + summary count at end), data_type normalizer/resolver,
       cardinality/mutability mappers, and a small file-writer helper that takes a
       relative path + content and creates parent folders as needed (one call per model).
2. [ ] Emit `models-auto/common/*.tsp`, `models-auto/associations/*.tsp`,
       `models-auto/external/*.tsp` — one file per scalar/model.
3. [ ] Emit `models-auto/components/*.tsp` — one file per `components` entry (plain
       models, no reference/operations).
4. [ ] Emit `models-auto/processes/<kebab-id>/model.tsp` + `reference.tsp` +
       `<kebab-op>/input.tsp` (+ `output.tsp` when distinct) for every `processes`
       entry; same for `models-auto/resources/<kebab-id>/...`. Unique-id table and
       magic-value table both apply here, with warnings.
5. [ ] Generate `models-auto/main.tsp` last, once the full file list is known, so its
       import list can never drift from what was actually written.
6. [ ] `test-auto-models.tsp` at repo root, single `import "./models-auto/main.tsp";`.
7. [ ] `tools/requirements.txt` (`pyyaml`) + short `tools/README.md` documenting the
       venv setup and `python3 tools/generate_models.py` invocation, including a note
       that warnings printed on run are expected/by-design and should be scanned, not
       silenced.
8. [ ] Run `tsp compile test-auto-models.tsp` and fix generator output until it compiles
       cleanly with zero diagnostics. Capture the generator's own WARNING output
       alongside for review.
9. [ ] Spot-check generated output against the YAML by eye for the trickiest cases:
       `domainName.contacts` (`LabelledAggregation[Contact Object]` → should target
       `contact.reference`), `organisation.roles`
       (`DictionaryComposition[Organisation Role Object]` → stays inline/full),
       `dnsData.records` (`Composition[DNS Resource Record Object]` → stays inline),
       `domainName` transferCreate input/output, `restoreProcess.create` (has a
       `restoreReport` transient param plus a non-empty prose `input`), `user.organisationId`
       (`Organisation Data Object Reference` → must resolve to `organisation.reference`).

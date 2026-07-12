# Model generator

`generate_models.py` mechanically generates TypeSpec model files under
`models-auto/` from `.spec/draft-ietf-rpp-data-objects.yaml`. See
`PLAN-GENERATOR.md` at the repo root for the full design.

## Setup

```bash
python3 -m venv .venv
.venv/bin/pip install -r tools/requirements.txt
```

## Run

```bash
.venv/bin/python3 tools/generate_models.py
```

This overwrites everything under `models-auto/` and regenerates
`test-auto-models.tsp` at the repo root.

**The generator prints `WARNING:` lines to stderr for every normalization,
fuzzy name match, or magic-value interpretation it applies.** This is by
design (see PLAN-GENERATOR.md's "no silent inference" principle) — these
warnings are not bugs to silence, they're a checklist of places where the
source YAML is ambiguous or under-structured and the generator had to guess.
Scan them on every run, especially after the YAML changes, to catch new
content that hits an existing guess in an unexpected way.

## Verifying output compiles

```bash
tsp compile test-auto-models.tsp
```

This compiles only the generated output, isolated from the real
`main.tsp`/`models/`/`interfaces/` service definition.

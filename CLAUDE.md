# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository is a [TypeSpec](https://typespec.io/) definition of the IETF **RESTful Provisioning Protocol (RPP)** — a REST API for provisioning and managing domains, contacts, and hosts in a shared registry database (the successor concept to EPP / RFC 5730-5731). The TypeSpec source compiles to OpenAPI 3.0 and JSON Schema; there is no runtime code here.

The rendered OpenAPI is published to GitHub Pages per branch/PR: https://pawel-kow.github.io/ietf-rpp-api-typespec/

## Commands

```bash
yarn install                              # install compiler + emitter deps
tsp compile .                             # emit both OpenAPI3 and JSON Schema -> tsp-output/
tsp compile . --emit @typespec/openapi3   # emit only OpenAPI (matches CI)
tsp compile . --watch                     # recompile on change
```

`tsp` comes from `@typespec/compiler` (install globally with `npm install -g @typespec/compiler`, or use the devDependency). There is no test suite — validity is defined by whether `tsp compile` succeeds without diagnostics. Emitters are configured in [tspconfig.yaml](tspconfig.yaml); output goes to `tsp-output/@typespec/openapi3/` and `tsp-output/@typespec/json-schema/`.

## Architecture

The single entry point is [main.tsp](main.tsp), which declares the `rpp` `@service` namespace and imports every interface file. Compilation flows: `main.tsp` → interfaces → models → examples.

### The EntityCollection pattern (most important concept)

RPP objects (domains, contacts, hosts) share a common REST lifecycle. Rather than repeat operations per object, generic parameterized interfaces live in [interfaces/rpp/entitycollections/](interfaces/rpp/entitycollections/) and each object's interface composes them via `extends` with type arguments:

- `EntityCollection<InputT, OutputT, UpdateT, OutputTMinimal>` — Create / Get / Check / CheckFast (HEAD) / Update ([main.tsp](interfaces/rpp/entitycollections/main.tsp))
- `EntityCollectionTransferrable<...>` — transfer request/query/cancel/approve/reject under `/{id}/processes/transfer`
- `EntityCollectionRenewable<...>` — renewal under `/{id}/processes/renewal`
- `EntityCollectionDeleteable<...>` — delete

Example — [interfaces/rpp/domains.tsp](interfaces/rpp/domains.tsp) mounts all four at `/domains`; [hosts.tsp](interfaces/rpp/hosts.tsp) mounts only the base collection. **To add or change an operation available to all objects, edit the generic interface; to change which operations an object supports, edit that object's `extends` clause.**

### Directory layout

- `interfaces/rpp/*.tsp` — one file per object, each a `namespace rpp { @route("/x") interface ... }`. `@useAuth(BasicAuth)` guards the provisioning objects.
- `models/*.tsp` — data models, each in its own sub-namespace (`rpp.domain`, `rpp.contact`, `rpp.host`, `rpp.common`, `rpp.errors`, `rpp.headers`, `rpp.message`, `rpp.discovery`).
- `models/examples/*.tsp` — `const` example values referenced via `@example(...)` decorators on models (see [models/domain.tsp](models/domain.tsp)).

### Cross-cutting conventions

- **Shared building blocks** in [models/common.tsp](models/common.tsp): `ProvisioningObjMinimal` / `ProvisioningObj` / `TransferableProvisioninigObj` are spread (`...`) into object models to attach standard registry fields (crDate, exDate, status, clID, authInfo, …).
- **Read-only fields** use `@visibility(Lifecycle.Read, Lifecycle.Query)` so they appear in responses but not in create/update request bodies.
- **Error responses** are pre-composed unions in [models/errors.tsp](models/errors.tsp), named by the status codes they carry (e.g. `ErrorResponse400_401_404_500`). Operations reference these aliases in their return-type unions. `ErrorResponse` itself uses `application/problem+json` (RFC 7807).
- **Headers** in [models/headers.tsp](models/headers.tsp): every request spreads `...RequestHeaders`/`...RequestHeadersMinimal`, every response spreads `...ResponseHeaders`. Custom `RPP-Cltrid`/`RPP-Svtrid`/`RPP-Code` headers and the `Prefer: return=minimal|representation` negotiation live here.
- **Update semantics**: `DomainUpdateModel extends UpdateModel<Add, Remove, Change>` — updates are structured as add/remove/change sub-objects, not full replacement.

### Reference material

`.spec/` holds the IETF draft documents this TypeSpec implements (`draft-ietf-rpp-core`, `draft-ietf-rpp-data-objects`, `draft-wullink-rpp-json`). Consult these when the intended semantics of a model or operation are unclear — the TypeSpec is meant to track them.

## CI

[.github/workflows/static.yml](.github/workflows/static.yml) compiles the OpenAPI spec for **every branch and open PR** in parallel and deploys each to its own folder on GitHub Pages, with a `list.json` index. A compile failure fails only that branch's matrix job (`fail-fast: false`).

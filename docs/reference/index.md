---
title: Reference
chapter: 10
---

# Reference

The reference chapters describe exact surfaces: command-line flags, file
formats, manifest fields, API envelopes, validation gates, and known failure
modes. They are written to be consulted, not read end to end.

Use the tutorials for a guided flow and the domain chapters for concepts. Use
this chapter when you need the exact spelling of a flag, the owner of a file, or
the evidence required before making a claim.

## Sections

| Section | Use it for |
|---|---|
| [Command line](cli.md) | Startup flags, recording, networking, Rhai REPL, scene tests, asset validation |
| [Controls](controls.md) | Shipped keyboard, mouse, camera, and workbench bindings |
| [twin.toml](twin-toml.md) | Project identity, entry scene, source roots, settings, children, journal |
| [Assets.toml](assets-toml.md) | External downloads, hashes, processing recipes, cache behavior |
| [File formats](file-formats.md) | Extensions, JSON kinds, generated files, and runtime state |
| [HTTP API](http-api.md) | Request envelope, endpoints, schema discovery, readiness |
| [Mission control](mission-control.md) | Operator lifecycle, authority claims, telemetry, release |
| [Validation](validation.md) | Preflight, lint, scene tests, SysML verification, evidence |
| [Troubleshooting](troubleshooting.md) | Startup, scene, input, asset, Modelica, telemetry, and API failures |

SysML authors should also see the dedicated [SysML v2 chapter](../sysml/index.md)
for source structure, typed analysis, and verification limits.

## Conventions

**Paths.** A path in a manifest is relative to that manifest's owner unless the
text says otherwise. `twin.toml` paths are Twin-relative. `Assets.toml`
destinations are Twin-relative or cache-relative. Runtime UI manifest paths are
relative to the scope's asset root and are qualified with `lunco://` or
`twin://` before publication.

**Commands.** Command names are exact and case-sensitive. Discover them from the
running build with `GET /api/commands/schema`; do not infer a name from a menu
label. A rejected command is terminal and does not partially apply.

**Values.** A missing value is not zero. A port can be absent while its owner is
preparing. An omitted setting inherits; an explicit `false` is a value.

**Evidence.** A parse check is not a runtime test. A screenshot is not numerical
evidence. A passing test must come from a real verdict, not from the absence of
a failure.

## Source of truth

When this documentation and the running build disagree, the build wins:

1. The reflected command and query schema of the running binary.
2. The authored asset or manifest actually loaded by that build.
3. The current source in the engine repository.
4. This documentation.

That order is deliberate. The schema is generated from the registered types, and
a manifest is validated before it is mounted. Prose can lag a rename; the
running surface cannot.

## Related

- [How it fits together](../general/how-it-fits-together.md) — the runtime flow
  behind these surfaces
- [Formats](../general/formats.md) — which authored format owns which fact
- [Glossary](../general/glossary.md) — terms used across the reference
- [Integrate your stack](../general/integrate-your-stack.md) — supported
  boundaries and adapter responsibilities

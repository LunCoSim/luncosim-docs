---
title: SysML v2
chapter: 7
---

# SysML v2

SysML v2 gives a Twin a place to state what its system must do and how the
system is organized. LunCoSim reads `.sysml` and `.kerml` source, resolves a
bounded model, and exposes typed facts to its editor and Rhai policies.

SysML is one authored source in a Twin. It does not replace the scene, the
continuous model, or the test procedure.

| Source | Owns |
|---|---|
| SysML v2 | Requirement intent, logical structure, typed values, and trace links |
| USD | Scene identity, composed topology, geometry, and physical properties |
| Modelica | Continuous equations and state |
| Rhai | Runtime observations, test policy, and verdicts |
| `twin.toml` | Source roots and the mapping from SysML verification cases to scene tests |

## A practical workflow

1. Add `.sysml` or `.kerml` source to the Twin and declare its entry point in
   [`twin.toml`](../reference/twin-toml.md#modelica-and-sysml-roots).
2. Write requirement definitions and usages, subjects, typed acceptance
   criteria, and explicit `satisfy` and `verify` relationships.
3. In the windowed app, open the **SysML Requirements** panel in the **Editor**
   view. Use Requirements for coverage, Traceability for links, and Structure
   for the package and part hierarchy.
4. Run source validation and review its diagnostics and structural findings.
5. Map each executable verification case to a USD scene and Rhai observer in
   the Twin manifest, then run it through `luncosim test`.

The editor can navigate source declarations and run mapped cases. It does not
author BDD/IBD diagrams or infer missing relationships.

## Supported profile

| Area | LunCoSim support |
|---|---|
| Source | SysML v2 textual `.sysml` and `.kerml` files in a Twin source set |
| Structure | Source-backed packages, parts, interfaces, ports, connections, and typed attributes |
| Requirements | Definitions and usages, documentation, subjects, typed values, `require`, `satisfy`, and `verify` relationships |
| Analysis | Typed, source-linked facts with selection and paging for larger Twins |
| Constraints | A bounded typed expression subset, with a separate limited path for lowering eligible constraints to Modelica |
| Verification | Rhai observers read SysML facts and runtime state; the Twin registry binds a case to a scene test |

Parsing a declaration does not mean LunCoSim executes its full SysML or KerML
semantics. Unsupported expressions produce diagnostics. Requirement thresholds
are not copied into Rhai: the observer selects a source criterion and supplies
the measurement or runtime observation.

LunCoSim does not provide a general KerML execution engine, automatic
requirement-to-USD projection, or full diagram authoring. Check
[Requirements and structure](requirements.md) and
[Analysis and verification](analysis-and-verification.md) before relying on a
specific language feature.

## In this chapter

- [Requirements and structure](requirements.md): source files, Twin roots, and
  a worked requirement with typed evidence and verification links.
- [Analysis and verification](analysis-and-verification.md): the editor,
  validation commands, typed analysis, and the path from a requirement to a
  scene-test verdict.

For the normative language definition, see the
[OMG SysML v2 specification](https://www.omg.org/spec/SysML/2.0). LunCoSim
implements a documented subset of that specification. SysML v2 builds on
[KerML](https://www.omg.org/spec/KerML/1.0), whose full execution semantics are
also outside LunCoSim's current profile.

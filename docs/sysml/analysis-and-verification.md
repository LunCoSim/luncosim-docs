---
title: Analysis and verification
chapter: 8
section: 2
---

# Analysis and verification

SysML analysis and runtime verification answer different questions. Analysis
checks the source model and exposes its typed facts. A verification run uses a
Rhai observer against a loaded scene and reports whether the authored evidence
meets the criterion.

## Inspect the source in LunCoSim

With a Twin active in a windowed build that includes SysML support, open the
**SysML Requirements** panel in the **Editor** view. The workspace shows
requirement usages, reusable definitions, source diagnostics, and coverage.
Traceability follows explicit subject, `satisfy`, and `verify` links. Structure
browses the package and part hierarchy.

The panel keeps model coverage, requirement evidence, and scene-test execution
as separate statuses. A passing test does not repair a missing `verify` link;
a complete trace does not prove the runtime passed.

## Validate and analyze

Use the CLI for a file-level parse and loader check:

```bash
luncosim --validate path/to/twin/requirements/rover.sysml
```

This checks the input file and its supported declarations. It does not execute
a constraint against the simulation. From a running Twin, `ValidateSysml`
checks its resolved source set and returns parser/resolver diagnostics plus
structured `lint.sysml` findings. Review `errors`, `warnings`, and `findings`;
each finding includes a rule, severity, subject, and message.

Use `AnalyzeSysml` when Rhai needs typed source facts. Select tables and page
large results rather than copying a full model into a script:

```rhai
let page = query("AnalyzeSysml", #{
    path: "twin://my-rover",
    tables: ["requirements", "verifications"],
    offset: 0,
    limit: 16,
});

let requirements = page.analysis.page.tables.requirements;
```

Each selected table reports its offset, limit, total, returned count, and
whether more records remain. Pages include a source revision. Check that value
before combining results from multiple pages; do not mix facts from different
source edits.

## Map a verification case to a scene test

SysML names the verification case. `twin.toml` names the scene and Rhai
observer that execute it:

```toml
[verification]
[[verification.cases]]
name = "RoverRequirements::VerifyPowerBudget"
scene = "scenes/tests/power_budget.usda"
script = "scenarios/tests/verify_power_budget.rhai"
verdict_channel = "POWER_BUDGET"
```

All paths are relative to the Twin root. The registered case must match the
qualified SysML verification name, scene, script, and verdict channel.

Run it through the production scene-test runner:

```bash
luncosim test \
  --scene path/to/twin/scenes/tests/power_budget.usda \
  --verification RoverRequirements::VerifyPowerBudget
```

The observer reads the source criterion and gathers the needed values from the
runtime. It then emits the verdict. LunCoSim does not infer which USD object
implements a SysML part or automatically project a requirement into the scene.

The engine repository includes a complete power-budget fixture with a
[SysML model](https://github.com/LunCoSim/lunco-sim/blob/c84fba03ae41c1c48548485e0effd8c152b3621d/assets/scenes/tests/sysml_async_analysis/analysis.sysml),
[Twin manifest](https://github.com/LunCoSim/lunco-sim/blob/c84fba03ae41c1c48548485e0effd8c152b3621d/assets/scenes/tests/sysml_async_analysis/twin.toml),
and [Rhai observer](https://github.com/LunCoSim/lunco-sim/blob/c84fba03ae41c1c48548485e0effd8c152b3621d/assets/scenes/tests/sysml_async_analysis/verify_power_budget.rhai).

## Read the result

A verification claim needs both a sound source mapping and current runtime
evidence:

1. Source analysis has no unresolved names or syntax errors.
2. The requirement has a formal `require` criterion and an explicit `verify`
   link.
3. The Twin registry maps the case to the intended fixture and observer.
4. The observer emits a verdict from actual source values or runtime state.
5. The scene test exits with `0`; keep its structured evidence and source
   revision with the result.

An absent value, unresolved reference, stale result, or missing test mapping is
not a pass. A passing scene test proves only the authored checks on that build
and fixture. It does not certify physical accuracy beyond the comparison and
assumptions recorded for the run.

For the general evidence gates and report checklist, see
[Validate and share](../tutorials/validate-and-share.md). For exact CLI flags,
see [Command line](../reference/cli.md).

## Limits

LunCoSim supports source parsing, typed analysis, selected constraint
expressions, and authored requirement verification. It does not execute
arbitrary KerML behavior, run every SysML constraint, create full BDD/IBD
diagrams, or generate USD geometry from SysML. Unsupported constructs return
diagnostics; they are not silently approximated.

Use the [SysML v2 overview](index.md) for the supported profile and
[Requirements and structure](requirements.md) for source-authoring guidance.

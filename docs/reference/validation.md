---
title: Validation
chapter: 8
section: 8
---

# Validation

Validation is layered. Each layer answers a different question, and a clean
result at one layer does not imply a clean result at the next. Use the lightest
layer that can answer your question, then keep the evidence with the project.

## What are you trying to prove?

| Question | Evidence | What it does not prove |
|---|---|---|
| Do the authored files parse and compose? | `luncosim --validate`, `ValidateAsset` | That the scene runs or behaves correctly |
| Does the Twin resolve its names and assets? | `ValidateTwin` | That a runtime owner does not collide |
| Is the loaded scene structurally sound? | `RunLint` | That the behavior matches a requirement |
| Does the authored scenario meet its verdict? | `luncosim test --scene` | That the model is physically accurate |
| Does a SysML requirement pass? | `--verification` with a Twin registry entry | That every requirement is covered |
| Is the live runtime healthy? | `/api/ready`, `CosimStatus`, `GetBrokenConnections` | That the authored design is correct |
| Does it look right? | Screenshot or recording | That the numbers are right |
| Is it accurate for my mission? | Comparison with reference data and documented assumptions | That it is accurate outside that evidence |

LunCoSim provides a test and evidence harness. It does not issue a generic
accuracy certificate.

## Preflight the files

```bash
luncosim --validate \
  path/to/twin/scene.usda \
  path/to/twin/models/Drive.mo \
  path/to/twin/scenarios/drive.rhai
```

Supported inputs are `.mo`, `.usda`, `.sysml`/`.kerml`, `.wesl`, and `.rhai`.
The command runs without a window, GPU, or application instance. It exits `0`
when every report is valid and `1` when any report fails.

`--validate` is parse- and loader-oriented. It catches syntax errors, broken
references, invalid Modelica declarations, missing authored wheel attributes,
and unparsable Rhai. It does not execute the scenario, run the solver, or prove
that a value is physically correct.

From a running session, the same file-level checks are available as the
`ValidateAsset` query. It admits one operation and returns an operation ID; poll
that ID until the report is ready. Use `ValidateTwin` when the question spans a
whole Twin folder and its resolver closure. `ValidateTwin` reports namespace
collisions; use `policy: "error"` when a collision should fail the check.

## Lint the loaded scene

A file check cannot see entities spawned at runtime or edits made after load.
After loading and editing a scene, run the explicit live lint:

```json
{"type": "ExecuteCommand", "command": "RunLint", "params": {}}
```

Then poll `GetDiagnostics` until the report is complete before treating it as
clean. Loaded-stage lint can see runtime-owned ports that file validation
cannot. It remains an explicit check; nothing lints automatically on load or on
a physics tick.

Use `RunLint` when you need to know whether the scene as composed will behave
correctly, not merely whether its files parse.

## Run the authored behavior test

```bash
luncosim test --scene path/to/twin/tests/drive.usda
```

The scene test runs the authored Rhai observer with manual, fixed-step time
advancement. The exit code is the verdict:

| Exit | Meaning |
|---|---|
| `0` | PASS |
| `1` | FAIL |
| `2` | No verdict was produced |

A passing test must come from a real verdict, not from the absence of a
failure. A test that exhausts its tick budget without a verdict is exit `2`.
Keep a negative fixture for the behavior you are guarding; a test that cannot
fail is not evidence.

Useful selectors:

| Option | Use |
|---|---|
| `--list` | Discover test scenes and their execution kind |
| `--verdict-channel NAME` | Accept the verdict only from a named channel |
| `--verification QUALIFIED_NAME` | Bind the run to a Twin SysML verification case |
| `--max-ticks N` | Bound cumulative simulated steps; default 20000 |
| `--tick-hz HZ` | Select the manual update rate; default 60 |
| `--readiness-timeout SECS` | Bound scene preparation time; default 420 |
| `--determinism-reference PATH` | Load a typed state reference for comparison |

A component suite can use:

```bash
luncosim test-component --twin path/to/twin --component rover.wheels
```

The component manifest owns the scene and observer, so the test and its fixture
stay together. Run scene tests through the production `luncosim` binary; do not
substitute a private harness or `--validate`.

## Verify requirements with SysML

A Twin can keep its requirements in `.sysml`/`.kerml` source and map a
verification case to a scene and Rhai observer:

```toml
[verification]
[[verification.cases]]
name = "Project::VerifyDrive"
scene = "tests/drive.usda"
script = "scenarios/tests/drive.rhai"
verdict_channel = "DRIVE_REQUIREMENTS"
```

Run the mapped case:

```bash
luncosim test --scene path/to/twin/tests/drive.usda \
  --verification Project::VerifyDrive
```

`ValidateSysml` checks source validity and structural policy. `AnalyzeSysml`
returns typed facts for Rhai policy. `--verification` checks that the qualified
name, scene, observer, and verdict channel match the Twin registry before the
run starts.

This is a bounded subset: scalar constraints and authored observations are
supported; full KerML execution and automatic requirement-to-USD projection are
not. Keep the requirement text and limits in SysML, and keep provider selection
and runtime observations in the Twin's Rhai observer.

## Read runtime evidence

Before treating a live value as final, check readiness:

```bash
curl -s "http://127.0.0.1:4101/api/ready"
```

Require `ready: true`, `world_hold: false`, and `pending_count: 0`. A missing
port is not a zero; it can mean the owner is still preparing.

For the coupled chain, read:

- `CosimStatus` for per-entity model timing, status, and propagated values.
- `GetBrokenConnections` for rejected wires and dropped writes.
- `CausalTrace` for an admitted input edge and its producer identity.
- `ListTelemetryChannels` then `QueryTelemetryHistory` for retained samples.
- `ExportTelemetryRecording` for a columnar `times`/`series` export.

A single sample proves a moment; a history query proves a trend. Use one
`ReadPortsBatch` response when comparing values from the same simulation tick.
The telemetry `t` value is simulation seconds; `epoch_jd` gives the absolute
mission frame when one is authored.

## Make an accuracy claim

Separate three questions before saying a model is accurate:

1. **Model form.** What equations, assumptions, and neglected effects define
   the model?
2. **Numerical verification.** Which solver, step size, tolerances, units, and
   initial conditions were used? Did refinement change the answer?
3. **Validation.** What reference data was used, over what range, with what
   tolerance, and on which build?

Record the answer with the run. Compare the exported telemetry against a
reference run or an external tool. A reference FMU can be run through native
FMI import when you need an independent implementation, but that is a comparison
setup, not an automatic equivalence proof.

A useful evidence record contains:

- the Twin revision and `luncosim` build;
- the exact scene and scenario paths;
- the passed requirements and verdict channels;
- the reference data source and tolerance;
- the readiness and cosim diagnostics;
- a screenshot when the claim includes presentation.

Do not use a render screenshot as numerical evidence, and do not use a green
scene test as an accuracy certificate.

## A practical gate

| Stage | Run |
|---|---|
| While authoring | `luncosim --validate` on every changed asset |
| Before opening a Twin | `ValidateTwin` and `RunLint` |
| Before sharing a behavior | `luncosim test --scene …` |
| Before claiming a requirement is met | `luncosim test --verification …` |
| Before publishing a result | Reference comparison, versioned evidence, and a saved recording or screenshot |

## Common traps

| Trap | Better check |
|---|---|
| Treating `--validate` as a runtime test | Run the authored scene test |
| Treating a missing port as `0.0` | Check readiness and `ListPorts` |
| Accepting a test with no verdict | Require exit `0`, not merely no failure |
| Comparing samples from different ticks | Use one batch read |
| Calling a screenshot "validation" | Pair it with numeric evidence |
| Claiming FMI conformance from one imported FMU | State the exact FMI profile and tested limits |

## Related

- [CLI](cli.md) — full command-line surface
- [Use the HTTP API](http-api.md) — request envelope and readiness
- [Telemetry](../ui/telemetry.md) — live values and history
- [Integrate your stack](../general/integrate-your-stack.md) — supported boundaries

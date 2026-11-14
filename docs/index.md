---
title: LunCoSim Documentation
hide:
  - toc
---

<div class="titlepage" markdown>

<p class="title-kicker">Technical documentation</p>

# LunCoSim Documentation

<p class="title-subtitle">An open-source workbench for authoring, simulating, and
operating space missions with USD, Modelica, and Rhai.</p>

<div class="title-meta">
<dl>
<dt>Document version</dt><dd>0.1</dd>
<dt>Release date</dt><dd>November 2026</dd>
<dt>LunCoSim version</dt><dd>0.6.0-dev</dd>
<dt>LunCoSim source commit</dt><dd><code>13b383cce1b99fa6755fa8689c466529cb0046da</code></dd>
<dt>Applies to</dt><dd>Desktop builds; browser build coverage is TBD</dd>
<dt>Status</dt><dd>Living document; updated with each release</dd>
<dt>License</dt><dd>Open source; see the repository for details</dd>
</dl>
</div>

<div class="abstract" markdown>

**Abstract.** LunCoSim combines a composed OpenUSD scene, continuous Modelica
models, and discrete Rhai mission policy into one running simulation. This
document describes the project model, the authoring workflow, the runtime
contracts that connect the three formats, and the evidence required before a
result is trusted. It is written for engineers, mission designers, educators,
and tool integrators who need to understand both what to author and why the
runtime behaves as it does.

</div>

<div class="contents" markdown>

**Contents**

1. [General](general/index.md) — purpose, installation, first run, perspectives,
   Twins, and the format boundaries.
2. [Tutorials](tutorials/index.md) — guided lessons from a first drive to a
   validated Twin, including an AI assistant connection.
3. [USD](usd/index.md) — scene composition, physics, typed ports, programs,
   materials, and asset addressing.
4. [Modelica](modelica/index.md) — continuous behavior, cosimulation, the Lunica
   workbench, libraries, and experiments.
5. [Rhai](rhai/index.md) — scenario lifecycle, task trees, commands, events,
   tests, and reusable policy patterns.
6. [Shaders](shaders/index.md) — WESL material parameters, texture layers, USD
   material binding, terrain rendering, and quality budgets.
7. [SysML v2](sysml/index.md) — requirement sources, system structure, typed
   analysis, and verification with scene tests.
8. [UI & Settings](ui/index.md) — global and project settings, HUD surfaces,
   theming, and runtime-authored UI.
9. [Reference](reference/index.md) — command line, controls, manifests, file
   formats, HTTP API, mission control, validation, and troubleshooting.

</div>

<figure class="title-figure">
<a href="assets/images/luncosim-layers.svg"><img src="assets/images/luncosim-layers.svg" alt="The LunCoSim layer model: TOML configuration, USD scene, Modelica behavior, Rhai policy, and the Rust runtime."></a>
<figcaption>The authored formats and the runtime that projects them into a live
world. Each fact has one owner.</figcaption>
</figure>

## About this document

This guide documents the behavior of the shipped application and the contracts
an author can rely on. Where a capability is partial, experimental, or limited
to one platform, the limitation is stated in the relevant section rather than
implied by silence.

The documentation follows the same ownership rule as the software:

- **USD** owns scene structure, geometry, materials, physics schemas, and typed
  connections.
- **Modelica** owns continuous equations and state.
- **Rhai** owns events, commands, mission sequencing, and authored verdicts.
- **TOML** owns project and asset configuration.
- **The runtime** owns projection, scheduling, physics integration, and
  rendering.

A reader who remembers only one rule should remember this one: do not
reimplement a fact in a second layer. A wheel position belongs in USD, a motor
curve in Modelica, a waypoint mission in Rhai, and a download declaration in
`Assets.toml`.

## Conventions

| Convention | Meaning |
|---|---|
| **Bold** | A user-interface label, a perspective name, or a term defined in the glossary. |
| `Monospace` | A file name, command, attribute, property, or literal value. |
| `>` | A menu path, for example **File → Open Twin…**. |
| Note boxes | A constraint, a platform limitation, or a warning about a common mistake. |
| Code blocks | Authored source or a command to run. Shell blocks use a POSIX shell unless marked otherwise. |
| Version numbers | LunCoSim is under active development; command and schema details can change between releases. |

Paths in this document use forward slashes. On Windows, substitute the
platform separator where the application accepts a native path. Logical asset
addresses such as `lunco://` and `twin://` always use forward slashes.

## How to use this document

A new user should read [Installation](general/install.md), run
[First mission](tutorials/first-mission.md), and then read
[How it fits together](general/how-it-fits-together.md). An author who already
knows the workbench can go directly to the format chapter for the layer being
edited. An integrator should start with
[Integrate your stack](general/integrate-your-stack.md) and the
[HTTP API](reference/http-api.md). An instructor should read the
[Tutorials](tutorials/index.md) overview and the lesson descriptions before
using the classroom track. A requirements author should start with
[SysML v2](sysml/index.md).

## Current status

LunCoSim is under active development. Model coverage, platform support, and
tool maturity vary. A successful build, a clean parse, or a green scene test is
evidence about a specific claim; none of them is a general accuracy
certificate. The [Validation](reference/validation.md) chapter explains how to
separate preflight, runtime behavior, requirement coverage, and physical
accuracy.

Release builds and notes are published on the
[GitHub releases page](https://github.com/LunCoSim/lunco-sim/releases).
Community links are in the site footer.

</div>

---
title: General
chapter: 1
---

# General

This part introduces LunCoSim as a system: what it is for, how it is
installed, how the workbench is organized, and which format owns which fact.
It is the part to read before authoring a project. The remaining chapters
assume the vocabulary and ownership rules established here.

## Purpose of this part

A LunCoSim project is a folder of ordinary domain files — USD, Modelica, Rhai,
SysML, and TOML — that the runtime composes into a live world. The first task
of the documentation is therefore to explain the boundaries between those
files before explaining the tools that edit them.

The chapters in this part answer four questions:

1. What problem does LunCoSim solve, and what does it deliberately not solve?
2. How is the application installed, launched, and navigated?
3. What is a Twin, and how does it differ from a folder or a single file?
4. How do the authored formats and the runtime interact?

## The system in one page

The runtime opens a Twin, resolves its manifest, composes the default USD
stage, admits Modelica participants and Rhai programs, and then advances a
fixed simulation clock. The UI, the HTTP API, and scripts all use the same
typed command and query surface. Rendering observes the resulting state; it
does not own it.

| Layer | Owns | Typical file |
|---|---|---|
| Manifest | Project identity, entry scene, search roots, project settings | `twin.toml` |
| Scene | Hierarchy, transforms, geometry, materials, physics, ports, connections | `.usda`, `.usdc` |
| Behavior | Continuous equations, state, and physical conservation laws | `.mo` |
| Policy | Events, commands, mission phases, tutorial flow, test verdicts | `.rhai` |
| Assets | External bytes such as libraries, rasters, textures, and fonts | `Assets.toml` |
| Runtime | Projection, scheduling, physics, rendering, and the command bridge | Rust / Avian |

The rule that makes this decomposition useful is **one fact, one owner**. When
the same value is authored twice, the copies eventually disagree, and the
disagreement is usually discovered only after a mission has been tuned around
the wrong one.

## Reading paths

The part is written so that it can be read linearly, but not every reader needs
every chapter.

| Reader | Recommended path |
|---|---|
| New user | [Installation](install.md) → [First run](first-run.md) → [First mission](../tutorials/first-mission.md) |
| Project author | [Twins](twins.md) → [How it fits together](how-it-fits-together.md) → the format chapter for the layer being edited |
| Tool integrator | [Integrate your stack](integrate-your-stack.md) → [HTTP API](../reference/http-api.md) → [Mission control](../reference/mission-control.md) |
| Instructor | [Tutorials](../tutorials/index.md) → [First mission](../tutorials/first-mission.md) → [Validate and share](../tutorials/validate-and-share.md) |
| Contributor | [How it fits together](how-it-fits-together.md) → [USD](../usd/index.md) → [Modelica](../modelica/index.md) → [Rhai](../rhai/index.md) |

## What the reader is expected to know

The documentation assumes familiarity with a 3D content tool, a text editor,
and the idea of a simulation model. It does not assume prior knowledge of
OpenUSD, Modelica, or Rhai; each format chapter introduces the subset LunCoSim
uses and points to the upstream standard for the full language.

Some chapters use vector arithmetic and basic control concepts. A reader who
has tuned a PID controller or assembled a jointed mechanism will recognize the
examples. A reader who has not can still follow the workflow; the examples
state the intended behavior before showing the source.

## Scope and status

LunCoSim is a workbench, not a certified analysis tool. The documentation
distinguishes three kinds of statement:

- **Contract.** A behavior the runtime enforces, such as rejecting a force
  connection from a program that is not declared realtime-safe.
- **Convention.** A recommended authoring pattern that the runtime does not
  enforce, such as keeping mission decisions out of Modelica.
- **Limitation.** A capability that is partial, platform-specific, or not
  shipped, such as native FMI import being unavailable in the browser build.

Read the limitation notes before planning a workflow around a feature. The
[Validation](../reference/validation.md) chapter explains how to turn a
successful run into evidence and how to state what that evidence does not
prove.

## The chapters in this part

| Section | What it covers |
|---|---|
| [1.1 Introduction](introduction.md) | The problem, the design principles, and the intended audience |
| [1.2 How it fits together](how-it-fits-together.md) | The runtime flow and the boundary between the layers |
| [1.3 Formats](formats.md) | A side-by-side comparison of USD, Modelica, Rhai, TOML, SysML, and glTF |
| [1.4 Installation](install.md) | Packaged builds, source builds, and the updater |
| [1.5 First run](first-run.md) | The window, the perspectives, and the tutorial catalog |
| [1.6 Perspectives](perspectives.md) | The five task layouts and how to switch between them |
| [1.7 Twins](twins.md) | The project folder, nested Twins, and the project lifecycle |
| [1.8 Integrate your stack](integrate-your-stack.md) | What can be kept, what must be converted, and which adapters exist |
| [1.9 Glossary](glossary.md) | Definitions of the terms used throughout the document |

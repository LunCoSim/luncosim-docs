---
title: Use an AI assistant
chapter: 3
---

# Use an AI assistant with LunCoSim

Connect an external AI assistant to LunCoSim through the Model Context Protocol
(MCP). The LunCoSim MCP server exposes tools for inspecting and controlling a
running application. It does not start the simulator or run an AI model inside
LunCoSim.

## What the assistant can use

The MCP server provides tools for project discovery, Modelica work, telemetry,
and live simulation control. It also builds typed command tools from the
connected app's schema.

| Work | Tools |
|---|---|
| Discover commands and read general state | `discover_schema`, `execute_command`, `list_entities`, `query_entity`, `capture_screenshot` |
| Find Twin files, documents, and models | `list_twin`, `list_open_documents`, `list_bundled`, `list_library`, `find_model`, `open_uri`, `get_document_source` |
| Inspect and compile Modelica | `describe_model`, `list_compile_candidates`, `compile_model`, `compile_status` |
| Read and control Modelica runs | `set_input`, `RunActiveModel`, `RestartActiveModel`, `snapshot_variables`, `RunExperiment`, `ListRuns`, `GetExperimentResult` |
| Read telemetry and cosimulation state | `read_port`, `read_ports`, `watch_ports`, `list_telemetry_channels`, `query_telemetry_history`, `export_telemetry_recording`, `cosim_status` |
| Observe or operate a scene | `load_scene`, `acquire_control`, `follow_target`, `focus_target`, `run_scenario` |
| Inspect Rhai hooks and tool libraries | `ScriptingCatalog`, `ScriptInspect`, `ScriptStatus`, `ListToolLibraries`, `GetToolLibrary` through `execute_command` |
| Read LunCoSim workflows | `list_skills`, `read_skill` |

`RunExperiment`, `ListRuns`, and `GetExperimentResult` are API commands called
through `execute_command`. The list above shows the server's current tool set;
it can change with the server version. The command-specific tools depend on the
connected LunCoSim build. Ask the assistant to call `discover_schema` before it
tries a command.

Before creating a same-named Rhai tool, ask the assistant to inspect
`ListToolLibraries` and `GetToolLibrary`. That reveals the current owner and
which implementation is active.

## Connect an assistant

You need a desktop LunCoSim build with the HTTP API enabled, Node.js 18 or newer,
an engine source checkout, and an AI client that supports local stdio MCP
servers. At this docs revision, the MCP server is available in the engine
checkout; `@lunco/mcp-server` is not published on the public npm registry.

1. Install the MCP server dependencies from the engine checkout:

   ```bash
   git clone https://github.com/LunCoSim/lunco-sim.git
   cd lunco-sim/mcp
   npm ci
   ```

   If you already have the engine repository, skip the clone and run the
   remaining commands from its `mcp` directory.

2. Start LunCoSim with the API enabled. Include a scene if you want the
   assistant to work with a particular Twin:

   ```bash
   luncosim --api 4101 --scene path/to/scene.usda
   ```

3. Check that the app is ready:

   ```bash
   curl http://127.0.0.1:4101/api/ready
   ```

   Before asking the assistant to control the simulation, wait for `ready` to
   be `true`, `world_hold` to be `false`, and `pending_count` to be `0`. See
   [Readiness](../reference/http-api.md#readiness).

4. Add the server to your AI client's MCP configuration. Host settings differ;
   this is the server entry used by clients with a JSON `mcpServers` setting.
   Replace the path with the absolute path to your engine checkout:

   ```json
   {
     "mcpServers": {
       "lunco": {
         "command": "node",
         "args": ["/absolute/path/to/lunco-sim/mcp/src/index.js"],
         "env": {
           "LUNCO_API_HOST": "localhost",
           "LUNCO_API_PORT": "4101"
         }
       }
     }
   }
   ```

5. Restart or reload the AI client and approve its local LunCoSim server when
   prompted. If LunCoSim uses a different API port, set `LUNCO_API_PORT` to
   match.

Try a read-only request first:

> Inspect the connected LunCoSim session. List the entities and identify which
> discovered commands can read their ports. Do not change the scene or
> simulation.

The assistant should use the live schema and query tools to answer. It should
not guess a command name from an old example.

For an authored change, name its owner in the request. For example:

> This mission belongs only to the active Twin. Inspect its existing scenarios
> and Rhai tool libraries first. Propose a Twin-owned rover survey using the
> existing hooks and tools. Keep application policy unchanged, and show the
> files and validation steps before applying anything to the live simulation.

## App policy, Twin policy, and hooks

The assistant connects to the app's command surface. LunCoSim still decides
which owner handles a request. Tool libraries resolve from broad to narrow
scope. Core and application policy also have owners and lifetimes separate from
the active Twin:

| Scope | What belongs here | Lifetime |
|---|---|---|
| Standard | Shared assets shipped by the engine. | Available as the baseline for all Twins. |
| Core | Always-on engine mechanisms and shared native tools. | The runtime owns it. Twin authors normally do not edit this scope. |
| Application | Workbench-wide menus, presentation, and reusable application tools. | One running app; it remains active when the selected Twin changes. |
| Twin | Project-specific tools, mission policy, and scenarios. | The active Twin's lifetime in the app. It is the narrowest scope. |

Rhai tool libraries are reusable functions available to hooks and scenarios.
The registry reports whether a library comes from `standard`, `core`,
`application`, or `twin:<id>`. A narrower library can replace a broader library
with the same name. A Twin can therefore replace an application library while
it is active. See [Rhai tooling](../rhai/tooling.md).

Scenario hooks belong to a particular scenario instance. They run on the
runtime schedule that owns that scenario:

| Entry point | When it runs |
|---|---|
| `on_start(me, ctx)` | Once, after declared inputs and any scene requirements are ready. |
| `on_event(me, evt, ctx)` | When an event reaches the scenario's next eligible pass. |
| `task(me, ctx)` | Builds the mission task tree that the runtime advances. |
| `mission(me, ctx)` | Declares mission objectives and completion conditions. |
| `on_stop(me, ctx)` | During teardown, such as when the scenario is replaced or detached. |

An AI request does not call a hook by itself. The assistant sends a typed
command or edits authored policy; the app or Twin owner invokes its hooks at
the right lifecycle point. Application policy stays with the application.
Twin scenarios and their state stay with their Twin. For lifecycle details, see
[Scenario lifecycle](../rhai/lifecycle.md).

Stateless policy hooks are different from a scenario's lifecycle callbacks.
An owning subsystem calls a policy hook when it needs a decision, then checks
and applies the result. A scenario hook belongs to one script instance and can
keep mission state across its lifecycle.

## Work in small steps

Tell the assistant which Twin, document, or entity you mean and what result you
want. Ask it to inspect the relevant files and live state before proposing an
edit. For authored changes, keep each fact in its owning format: USD for scene
structure, Modelica for continuous equations, Rhai for mission policy, and TOML
for Twin configuration.

Review changes before applying them. Use `luncosim --validate` for parse and
structure checks, then run the production scene test or a live scenario for
behavioral evidence. A screenshot can confirm the visible result; it does not
prove numeric accuracy. See [Validate and share](validate-and-share.md) and
[Validation](../reference/validation.md).

The command API can affect open documents and the live simulation. It is
loopback-only by default; do not expose it to an untrusted network. The AI
client supplies the model and conversation. LunCoSim supplies the typed tools,
runtime state, and workflow guides.

# Inspect telemetry

Telemetry is a first-class runtime surface. Read it from the **Analyze**
perspective or from the HTTP API; do not tail a log or poll a screenshot for a
number.

## In the window

1. Switch to **Analyze**.
2. Open **Telemetry**. It lists the live port-bearing entities and their
   channels.
3. Select an entity to see its current values. An absent port is not a zero;
   the entity may still be preparing.
4. Open **Graphs** and add a channel to see it over time. This is the right tool
   for settling, oscillation, and arrival checks.
5. Use **Ports** to inspect the resolved direction and kind of each port before
   wiring a target.

The graph records real simulation samples. It is not a render-frame animation.
When the world is paused, the last sample stays visible.

## From the HTTP API

Start LunCoSim with an explicit port:

```bash
luncosim --api 4101
```

Find an entity:

```bash
PORT=4101

curl -s "http://127.0.0.1:$PORT/api/commands" \
  -H "Content-Type: application/json" \
  -d '{"type": "ListEntities"}'
```

The response contains each entity's `api_id`. Use that identity for reads:

```bash
# Discover the port names first; ReadPorts requires explicit names.
curl -s "http://127.0.0.1:$PORT/api/commands" \
  -H "Content-Type: application/json" \
  -d '{"type": "ExecuteCommand", "command": "ListPorts",
       "params": {"api_id": 42}}'

curl -s "http://127.0.0.1:$PORT/api/commands" \
  -H "Content-Type: application/json" \
  -d '{"type": "ExecuteCommand", "command": "ReadPorts",
       "params": {"api_id": 42,
                  "port_names": ["throttle", "steer", "speed"]}}'
```

`ReadPorts` returns one shared `sim_tick` and the selected rows. It does not
dump every port on an entity; name what you need. Use `ReadPortsBatch` when you
need the same sample across several entities.

## Modelica state

A rendered port is not necessarily the whole solver state. To inspect the
Modelica side:

```bash
curl -s "http://127.0.0.1:$PORT/api/commands" \
  -H "Content-Type: application/json" \
  -d '{"type": "ExecuteCommand", "command": "SnapshotVariables",
       "params": {"api_id": 42}}'
```

`SnapshotVariables` answers "what does the model currently hold?" Use
`ReadPorts` for "what is exposed at the wiring boundary?" and `CosimStatus` for
the end-to-end `Modelica → physics` chain.

## Readiness matters

Before treating a value as final, check readiness:

```bash
curl -s "http://127.0.0.1:$PORT/api/ready"
```

Require:

- `ready: true`
- `world_hold: false`
- `pending_count: 0`

A port may be momentarily absent while its model is compiling or its scene is
still being admitted. That is different from a valid zero.

## Screenshots

Numbers answer "what value?" A screenshot answers "does the scene look right?"
Capture the visible production window, not a headless substitute:

```bash
curl -s "http://127.0.0.1:$PORT/api/commands" \
  -H "Content-Type: application/json" \
  -d '{"type": "ExecuteCommand", "command": "CaptureScreenshot",
       "params": {"save_to_file": true, "path": "target/telemetry-check.png"}}'
```

The path is relative to the process working directory. Read the resulting PNG
before reporting a visual result.

## Common traps

| Trap | Better read |
|---|---|
| Polling stdout for a value | `ReadPorts` or the Telemetry panel |
| Treating a missing port as `0.0` | Check readiness and `ListPorts` |
| Using a single sample for a trend | Record a graph or a time series |
| Reading a render FPS as simulation cadence | Inspect the clock and timing profile |
| Comparing values from different ticks | Use one `ReadPorts`/`ReadPortsBatch` response |
| Looking only at ports for solver state | Also call `SnapshotVariables` |

See [HTTP API](http-api.md) for the request envelope and the discovery
endpoint.

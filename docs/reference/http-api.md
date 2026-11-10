---
title: HTTP API
chapter: 9
section: 6
---

# HTTP API

LunCoSim exposes a small HTTP API for automation, inspection, tests, and
screenshots. It is the same typed command/query surface used by the UI and by
Rhai, not a second control path.

Launch with an explicit free port:

```bash
luncosim --api 4101
```

The command endpoint is loopback-only. Do not expose it to an untrusted
network.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/commands` | Execute a command or query |
| `GET` | `/api/commands/schema` | Discover command names and field types |
| `GET` | `/api/health` | Liveness; does not read the world |
| `GET` | `/api/ready` | Readiness, scene hold, and pending work |
| `GET` | `/api/diagnostics` | Co-simulation wiring and connection health |

## Request envelope

Every write and query uses the same JSON envelope:

```bash
curl -s "http://127.0.0.1:4101/api/commands" \
  -H "Content-Type: application/json" \
  -d '{
        "type": "ExecuteCommand",
        "command": "SetPorts",
        "params": {
          "target": 42,
          "producer_id": 4812,
          "writes": [["throttle", 0.4], ["steer", 0.0], ["brake", 0.0]],
          "seq": 0,
          "tick": 0
        }
      }'
```

The successful response wraps the owner's result:

```json
{
  "data": {
    "accepted": true
  }
}
```

An error response is terminal. Do not retry a rejected command blindly; read
the error, inspect the target, and fix the input.

`ListEntities` can also be sent as a shorthand request:

```json
{"type": "ListEntities"}
```

## Discover the surface

Never guess a command name from memory:

```bash
curl -s "http://127.0.0.1:4101/api/commands/schema" | python3 -m json.tool
```

The schema is derived from the running application's reflected command and
query types. It grows with the features actually registered in that build.

## Readiness

Before controlling a scene, wait for readiness:

```bash
curl -s "http://127.0.0.1:4101/api/ready"
```

Continue only when `ready` is true, `world_hold` is false, and `pending_count`
is zero. A faulted world is not a slow world; inspect the readiness detail and
`/api/diagnostics`.

## Commands and queries

The API has both write commands and read queries. They share `ExecuteCommand`
for transport, but their contract differs:

- A write command has side effects and returns an acceptance/result.
- A query reads state and returns typed data.
- A rejected command does not partially apply a multi-target write.
- A missing value is not silently replaced with a zero.

Common discovery/read examples:

```bash
# Entities, including their stable api_id
curl -s "http://127.0.0.1:4101/api/commands" \
  -H "Content-Type: application/json" \
  -d '{"type": "ListEntities"}'

# Ports on one entity
curl -s "http://127.0.0.1:4101/api/commands" \
  -H "Content-Type: application/json" \
  -d '{"type": "ExecuteCommand", "command": "ListPorts",
       "params": {"api_id": 42}}'
```

## Driving from a script

A Python or shell client only needs an HTTP request. There is no SDK and no
handshake:

```python
import json
import urllib.request

def execute(command, params=None):
    body = json.dumps({
        "type": "ExecuteCommand",
        "command": command,
        "params": params or {},
    }).encode()
    request = urllib.request.Request(
        "http://127.0.0.1:4101/api/commands",
        data=body,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        payload = json.load(response)
    if "error" in payload:
        raise RuntimeError(payload["error"])
    return payload["data"]

entities = execute("ListEntities")["entities"]
```

## Boundaries

- The API is a transport. Domain state is still owned by USD, Modelica, Rhai,
  and the native runtime.
- Use `LoadScene`, not direct file writes, to mount a scene.
- Use `SetPorts` for a live input hold; use `ReleaseControl` or `ReleasePort`
  to return the input to its authored source.
- Use `CaptureScreenshot` for visual evidence; do not infer a rendered result
  from a numeric query alone.
- Run scene tests through the production binary (`luncosim test`), not through
  a private HTTP loop that skips the authored verdict.

For live values, see [Telemetry](../ui/telemetry.md). For the
operator lifecycle, including authority claims, telemetry, and safe release, see
[Mission control](mission-control.md). For supported asset and tool
boundaries, see [Integrate your stack](../general/integrate-your-stack.md). For
command-line flags, see [CLI](cli.md).

# mongo-runner

Manage MongoDB instances with `npx mongodb-runner` (no install needed). All commands via the Bash tool.

## Argument mapping

| User says | Translates to |
|---|---|
| `standalone`, `single`, *(none)* | `--topology standalone` |
| `replica`, `repl`, `rs` | `--topology replset` |
| `shard`, `sharded` | `--topology sharded` |
| `latest` | `--version 8.2` |
| a version number | `--version <X.Y>` |

## Commands

```bash
npx mongodb-runner start [--topology standalone|replset|sharded] [--version X.Y]
npx mongodb-runner ls
npx mongodb-runner stop --id=<uuid>          # uuid printed by start
npx mongodb-runner exec --topology replset -- mongosh --eval "..."  # start + run + stop
npx mongodb-runner prune                     # remove stale instances
```

Stop all running instances:
```bash
npx mongodb-runner ls | awk -F: '{print $1}' | xargs -I{} npx mongodb-runner stop --id={}
```

## macOS ARM64

Native binaries: **6.0, 7.0, 8.0, 8.2** only. `--docker` does not work (Linux-only `--network=host`).

For **4.4 or 5.0**, download x86_64 binaries (run via Rosetta 2):
```bash
V=4.4 P=4.4.29   # adjust for 5.0 / 5.0.30
mkdir -p ~/.mongodb/$V/bin
curl -sL "https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-$P.tgz" \
  | tar -xz --strip-components=2 -C ~/.mongodb/$V/bin
npx mongodb-runner start --topology replset --binDir ~/.mongodb/$V/bin
```
If `~/.mongodb/<V>/bin` already exists, skip the download and go straight to `start --binDir`.

## Multi-version / multi-topology testing

Run autonomously across versions and topologies without waiting for the user:

```bash
# Start/stop only (no tests)
~/.claude/scripts/mongodb-test-matrix.sh

# With a test command — receives MONGODB_URI as env var
~/.claude/scripts/mongodb-test-matrix.sh replset 7.0,8.0 -- pytest tests/ -x
~/.claude/scripts/mongodb-test-matrix.sh standalone,replset 8.2 -- mongosh "$MONGODB_URI" --eval "db.runCommand({ping:1})" --quiet

# Topology and version default to all when omitted
~/.claude/scripts/mongodb-test-matrix.sh standalone,replset,sharded 6.0,7.0,8.0,8.2 -- <cmd>
```

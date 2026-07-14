# opencode.json plugin notes

## Active plugins (June 2026)

| Plugin | npm version | Purpose |
|--------|-------------|---------|
| `opencode-vibeguard` | 0.1.0 | Security guardrails for tool invocations |
| `opencode-pty` | 0.3.4 | PTY support for terminal-style commands |
| `@tarquinen/opencode-dcp` | 3.1.14 | Dynamic Context Pruning — token-cost optimization via obsolete-tool-output pruning |
| `@zenobius/opencode-skillful` | 1.2.5 | Anthropic Agent Skills spec implementation — lazy load skill prompts on demand |

All four resolve cleanly via `npx -y <name>` or `opencode plugin add <name>`.

## Why scoped names

The first version of this pack used the short names `opencode-dynamic-context-pruning` and `opencode-skillful`. Both are 404 on the public npm registry. The actual published packages are scoped forks maintained by the community:

- `Opencode-DCP/opencode-dynamic-context-pruning` (GitHub) publishes to npm as **`@tarquinen/opencode-dcp`**
- `zenobi-us/opencode-skillful` (GitHub) publishes to npm as **`@zenobius/opencode-skillful`**

Always reference the scoped name in `opencode.json` — opencode resolves it directly from npm.

## Adding plugins

To add a plugin, edit `opencode.json`:

```json
"plugin": [
  "opencode-vibeguard",
  "opencode-pty",
  "@tarquinen/opencode-dcp",
  "@zenobius/opencode-skillful",
  "<new-plugin-name>"
]
```

Verify with `opencode debug config` — the merged config shows the resolved plugin list and any load errors. If a name returns 404 on `npm view <name> version`, find the actual published name (often scoped) and use that.

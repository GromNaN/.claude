# Jira MCP — Setup for Claude Code

Interact with https://jira.mongodb.org directly from Claude Code:
read tickets, create issues, add labels, update descriptions, add comments.

## 1. Get a Personal Access Token

1. Open https://jira.mongodb.org/tokens (SSO login required)
2. Click **Create token**
3. Give it a name (e.g. `claude-code`) and copy the generated value

## 2. Install the plugin

```bash
pipx install mcp-atlassian
```

## 3. Register the MCP server

```bash
claude mcp add-json jira '{
  "command": "/Users/<YOUR_USER>/.local/bin/mcp-atlassian",
  "env": {
    "JIRA_URL": "https://jira.mongodb.org",
    "JIRA_PERSONAL_TOKEN": "<YOUR_PAT>"
  }
}'
```

Replace `<YOUR_USER>` with your macOS username and `<YOUR_PAT>` with your token.

## 4. Restart Claude Code

Jira tools will be available automatically.

## Usage

Use the `/jira` skill with natural language:

- `"Show me ticket PHPC-2700"`
- `"What PRs are linked to DRIVERS-1234?"`
- `"Search for open bugs in project SERVER with label needs-triage"`
- `"Create a Bug in project PHPC with description..."`
- `"Add label needs-triage to PYTHON-456"`
- `"Add a comment on COMPASS-789: <text>"`
- `"Update the description of SERVER-123"`
- `"I'm starting PHPC-2700"`
- `"PR #1987 was merged into v2.2, close PHPC-2700"`
- `"Cancel PHPC-2700, won't fix"`

## Renewing the token

Jira PATs do not expire by default. If you create a new one:
1. Go back to https://jira.mongodb.org/tokens
2. Re-run the `claude mcp add-json` command with the new token
3. Restart Claude Code

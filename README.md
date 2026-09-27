# mb — the Miss Blue command line

`mb` is the [Miss Blue](https://missblue.dev) API from a terminal: send and
read iMessages from your numbers, look people up, manage contacts and webhooks.
`mb mcp` serves the same commands to an AI agent (Claude Code, Codex,
OpenCode, Cursor, Claude Desktop, and anything else that speaks MCP).

This repository holds the official builds. The source is not public.

Current version: **0.2.38**

## Install

**macOS and Linux**

```sh
curl -fsSL https://github.com/danest/missblue-cli/releases/latest/download/install.sh | sh
```

**Windows** (PowerShell)

```powershell
irm https://github.com/danest/missblue-cli/releases/latest/download/install.ps1 | iex
```

The installer picks the build for your machine (macOS Apple Silicon or Intel,
Linux x86_64 or arm64, Windows x86_64), checks it against the release's
`SHA256SUMS`, and installs `mb`. Run it again to update.

Or download the archive for your platform from the
[latest release](https://github.com/danest/missblue-cli/releases/latest) and
put `mb` on your `PATH`.

## Sign in and choose a project

```sh
mb login
```

`mb login` prints a short code and opens the Miss Blue console, where you
approve it. Nothing is pasted. Then it asks which organization and project to
work in, and remembers it.

```sh
mb use                 # choose again
mb use <project-id>    # or set it directly
mb whoami              # who you are, and the current project
```

`--project <id>` on any command, or `MISS_BLUE_PROJECT`, acts on another
project once. For CI and servers, set `MISS_BLUE_API_KEY` to a project key
from the console's Developers page instead of signing in.

## Use with AI agents

`mb mcp` serves every command below as an MCP tool over stdio. For example,
Claude Code:

```sh
claude mcp add missblue -- mb mcp --project <project-id>
```

Setup for Codex, OpenCode, Cursor, Claude Desktop, VS Code, Windsurf and
Gemini CLI: https://missblue.dev/docs/cli

## Commands

```
mb — the Miss Blue API from a terminal

USAGE
  mb <command> [--flag value]

SIGNING IN
  login              Approve this machine in a browser. No key to paste.
                     Then choose the organization and project to work in.
                       --no-browser   print the URL instead of opening one
  use [project]      Choose the project again, from a list or by id or name.
  logout             Forget the saved token on this machine.

  --project <id>     On any command: act on this project instead, once.
  MISS_BLUE_PROJECT  The same, for a whole shell or script.
  MISS_BLUE_API_KEY  A project key instead of a login. Wins over a saved login,
                     and its project is the key's.
  MISS_BLUE_API_URL  Another server; defaults to the hosted API.

COMMANDS
  whoami           What this key is, and which project it holds.
  numbers          The numbers this project holds.
  send             Send an iMessage.
                     --to              Phone number, Apple ID email, or a chat_id. (required)
                     --text            The message. Optional only when sending a file.
                     --from            Number id to send from. Defaults to your only number.
                     --file            A file to send. Uploaded first, then sent.
                     --allow-duplicate Send although the same text went there moments ago.
  threads          Conversations, most recent first.
  thread           Every message in one conversation.
                     --chat-id         From `threads`. (required)
  messages         Recent messages across this project's numbers.
  message          One message, including its delivery state and the Mac build that handled it.
                     --id              The message id. (required)
  workspaces       The businesses you belong to.
  projects         The projects in a workspace.
                     --workspace       Workspace id, from `workspaces`. (required)
  activity         Who has been answering a project's numbers, and how much.
                     --project         Project id, from `projects`. The chosen project by default.
                     --days            How far back to count. 1 to 365, 30 by default.
  member-activity  One person: what they sent, who to, and the messages.
                     --project         Project id, from `projects`. The chosen project by default.
                     --user            Whose work to report, from `activity`. (required)
                     --days            How far back to count. 1 to 365, 30 by default.
  problems         Sends that failed, or are still waiting for a Mac.
                     --only            `queued` or `failed`.
  lookup           Whether iMessage is known to reach a handle. Answered from your own traffic, not from Apple.
                     --handle          Phone number or Apple ID email. (required)
  typing           Show or hide the typing bubble in a conversation.
                     --chat-id         The conversation. (required)
                     --off             Hide it rather than show it.
  read             Tell the customer their message was seen. Only when a human has looked.
                     --chat-id         The conversation. (required)
                     --unread          Mark unread again.
  react            Add or remove a tapback on a message.
                     --id              The message id. (required)
                     --reaction        heart, like, dislike, laugh, emphasize, question. Defaults to heart.
                     --remove          Take it back.
  unsend           Unsend a message, inside Apple's two-minute window.
                     --id              The message id. (required)
  edit             Change what a sent message says, inside Apple's fifteen-minute window.
                     --id              The message id. (required)
                     --text            The replacement text. An empty edit is not an unsend, and is refused. (required)
  label            Name a number, so threads say which line they arrived on.
                     --id              The number id. (required)
                     --label           Empty clears it back to the bare handle.
  contacts         Names this project has given handles. Shared by everyone on it.
  name             Name a handle, or rename one already named.
                     --handle          Phone number or Apple ID email. (required)
                     --name            What to call them. (required)
  forget           Remove a name from the project's book.
                     --id              The contact id, from `contacts`. (required)
  webhooks         The endpoints this project sends events to.
  webhook-add      Register where events should go.
                     --url             https, and not a private address. (required)
  webhook-rm       Stop sending to an endpoint.
                     --id              The endpoint id. (required)
  deliveries       What we tried to send an endpoint, and what came back.
                     --id              The endpoint id. (required)

  mcp              Serve MCP over stdio, exposing every command above as a tool.
                     --project <id>    Pin the project this agent acts on.

DOCS
  https://missblue.dev/docs
```

## Documentation

https://missblue.dev/docs/cli

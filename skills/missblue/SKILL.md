---
name: missblue
description: Send and read iMessages from the user's Miss Blue business numbers with the mb command line. Text a customer, reply in a conversation, check whether a message was delivered, look up whether a number has iMessage, and manage contacts and webhooks. Use when the user asks to text, message, iMessage, follow up with, or read replies from customers or contacts through Miss Blue, or mentions mb or missblue.
---

# Miss Blue

Miss Blue sends real iMessages, with SMS as a fallback, from the user's own business
numbers. `mb` is its command line. Every command prints JSON.

## Before anything else

Run `mb whoami`.

- **Not signed in:** run `mb login`. It opens the user's browser and waits until they
  approve (up to 10 minutes). Show them the code it prints. Never ask the user to paste
  an API key or a token into the chat. If they use a key, it belongs in the
  `MISS_BLUE_API_KEY` environment variable, set by them.
- **No project chosen** (commands answer "no project chosen"): list them with
  `mb workspaces` and `mb projects --workspace <id>`, ask the user which one, then run
  `mb use <project id>`. `--project <id>` on a single command works elsewhere once.
- `mb numbers` shows the numbers this project can send from.

## Common tasks

Send a message. With one number it is used; with several, pass `--from` with a number id
from `mb numbers`:

    mb send --to +15555550100 --text "Your table is ready"
    mb send --to +15555550100 --file receipt.png

Reply in a conversation: find it with `mb threads`, read it with
`mb thread --chat-id <chat_id>`, then `mb send --to <chat_id> --text "..."`.

Check what happened after sending:

    mb message --id <message id>     # delivery state of one message
    mb problems                      # everything that failed or is still waiting

Look up whether a number is known to have iMessage: `mb lookup +15555550100`.
Contacts: `mb contacts`, `mb name --handle +1555... --name "Dana"`, `mb forget --id <id>`.
Webhooks: `mb webhooks`, `mb webhook-add --url https://...`, `mb deliveries --id <id>`.
Who has been answering: `mb activity --days 7` (needs a signed-in person, not a key).

## Rules

- Only message people who expect to hear from this business: its customers, and people
  who asked. Never send marketing to a list the user has not confirmed.
- Show the user the exact text and the recipients, and get a yes, before sending to more
  than one person or to anybody who has not messaged this number before.
- First contacts (people who have never messaged the number) are limited per number per
  day, 50 by default, and spaced out. A send may be accepted and held; that is expected.
  Do not try to get around the limit.
- The server honours STOP and other opt-outs. A refused send to somebody who opted out
  is final: do not retry it from another number.
- `--allow-duplicate` is only for a deliberate repeat. Do not use it to push a message
  through.
- Never print, paste or read aloud an API key, a token, or
  `~/.config/miss-blue/credentials.json`.
- After sending, check `mb problems` (or `mb message --id <id>`) and tell the user plainly
  what failed and why.

## With MCP

If Miss Blue is connected as an MCP server (`mb mcp`), the same commands are tools of the
same names. Use whichever you have; the rules above apply either way.

## Every command

Generated from this mb build, so it matches what `mb help` lists. Flags use dashes on the command line; the MCP tool of the same name takes the same arguments with underscores.

### mb whoami

What this key is, and which project it holds.

### mb numbers

The numbers this project holds.

### mb send

Send an iMessage.

- `--to <string>` Required. Phone number, Apple ID email, or a chat_id.
- `--text <string>` The message. Optional only when sending a file.
- `--from <string>` Number id to send from. Defaults to your only number.
- `--file <string>` A file to send. Uploaded first, then sent.
- `--allow-duplicate` Send although the same text went there moments ago.

### mb threads

Conversations, most recent first.

### mb thread

Every message in one conversation.

- `--chat-id <string>` Required. From `threads`.

### mb messages

Recent messages across this project's numbers.

### mb message

One message, including its delivery state and the Mac build that handled it.

- `--id <string>` Required. The message id.

### mb workspaces

The businesses you belong to.

### mb projects

The projects in a workspace.

- `--workspace <string>` Required. Workspace id, from `workspaces`.

### mb activity

Who has been answering a project's numbers, and how much.

- `--project <string>` Project id, from `projects`. The chosen project by default.
- `--days <number>` How far back to count. 1 to 365, 30 by default.

### mb member-activity

One person: what they sent, who to, and the messages.

- `--project <string>` Project id, from `projects`. The chosen project by default.
- `--user <string>` Required. Whose work to report, from `activity`.
- `--days <number>` How far back to count. 1 to 365, 30 by default.

### mb problems

Sends that failed, or are still waiting for a Mac.

- `--only <string>` `queued` or `failed`.

### mb lookup

Whether iMessage is known to reach a handle. Answered from your own traffic, not from Apple.

- `--handle <string>` Required. Phone number or Apple ID email.

### mb typing

Show or hide the typing bubble in a conversation.

- `--chat-id <string>` Required. The conversation.
- `--off` Hide it rather than show it.

### mb read

Tell the customer their message was seen. Only when a human has looked.

- `--chat-id <string>` Required. The conversation.
- `--unread` Mark unread again.

### mb react

Add or remove a tapback on a message.

- `--id <string>` Required. The message id.
- `--reaction <string>` heart, like, dislike, laugh, emphasize, question. Defaults to heart.
- `--remove` Take it back.

### mb unsend

Unsend a message, inside Apple's two-minute window.

- `--id <string>` Required. The message id.

### mb edit

Change what a sent message says, inside Apple's fifteen-minute window.

- `--id <string>` Required. The message id.
- `--text <string>` Required. The replacement text. An empty edit is not an unsend, and is refused.

### mb label

Name a number, so threads say which line they arrived on.

- `--id <string>` Required. The number id.
- `--label <string>` Empty clears it back to the bare handle.

### mb contacts

Names this project has given handles. Shared by everyone on it.

### mb name

Name a handle, or rename one already named.

- `--handle <string>` Required. Phone number or Apple ID email.
- `--name <string>` Required. What to call them.

### mb forget

Remove a name from the project's book.

- `--id <string>` Required. The contact id, from `contacts`.

### mb webhooks

The endpoints this project sends events to.

### mb webhook-add

Register where events should go.

- `--url <string>` Required. https, and not a private address.

### mb webhook-rm

Stop sending to an endpoint.

- `--id <string>` Required. The endpoint id.

### mb deliveries

What we tried to send an endpoint, and what came back.

- `--id <string>` Required. The endpoint id.

### mb mcp

Serve every command above as MCP tools over stdio. `--project <id>` pins the project for that agent.

<!-- mb skill 0.2.40 818a6df8f2d061ff -->

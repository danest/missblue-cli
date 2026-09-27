# mb, the Miss Blue command line

`mb` is the [Miss Blue](https://missblue.dev) API from a terminal: send and
read iMessages from your numbers, look people up, manage contacts and webhooks.
`mb mcp` serves the same commands to an AI agent (Claude Code, Codex,
OpenCode, Cursor, Claude Desktop, and anything else that speaks MCP).

This repository holds the official builds. The source is not public.

Current version: **0.2.47**

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

Install the Miss Blue skill so your agent knows how to use `mb` and what it
must never do:

```sh
mb skill install            # Claude Code, Cursor and OpenCode (~/.claude/skills)
mb skill install --codex    # Codex, Cursor and OpenCode (~/.agents/skills)
```

The same file is published with every release as
[SKILL.md](https://github.com/danest/missblue-cli/releases/latest/download/SKILL.md)
and kept in this repository at `skills/missblue/SKILL.md`.

`mb mcp` serves every command below as an MCP tool over stdio. For example,
Claude Code:

```sh
claude mcp add missblue -- mb mcp --project <project-id>
```

Setup for Codex, OpenCode, Cursor, Claude Desktop, VS Code and
Gemini CLI: https://missblue.dev/docs/cli

## Commands

```
mb: the Miss Blue API from a terminal

USAGE
  mb <command> [--flag value]

SIGNING IN
  login              Approve this machine in a browser. No key to paste.
                     Then choose the organization and project to work in.
                       --no-browser   print the URL instead of opening one
  use [project]      Choose the project again, from a list or by id or name.
  logout             Forget the saved token on this machine.

AI AGENTS
  skill              Print the Miss Blue skill: how an agent should use mb.
  skill install      Install it for Claude Code (also read by Cursor and OpenCode).
                       --codex   for Codex instead (~/.agents/skills)
                       --repo    into this directory, to commit for a team
                       --force   replace a copy that was edited by hand

  --project <id>     On any command: act on this project instead, once.
  MISS_BLUE_PROJECT  The same, for a whole shell or script.
  MISS_BLUE_API_KEY  A project key instead of a login. Wins over a saved login,
                     and its project is the key's.
  MISS_BLUE_API_URL  Another server; defaults to the hosted API.

COMMANDS
  whoami              What this key is, and which project it holds.
  numbers             The numbers this project holds.
  send                Send an iMessage.
                        --to              Phone number, Apple ID email, or a chat_id. (required)
                        --text            The message. Optional only when sending a file.
                        --from            Number id to send from. Defaults to your only number.
                        --file            A file to send. Uploaded first, then sent.
                        --allow-duplicate Send although the same text went there moments ago.
                        --wait            Wait until it is `sent`, `delivered` or `read`, then print it. Exits with an error if that has not happened in time.
                        --timeout         How long --wait waits: 90s, 5m. A minute by default, at most 10 minutes.
  threads             Conversations, most recent first.
  thread              Every message in one conversation.
                        --chat-id         From `threads`. (required)
  messages            Recent messages across this project's numbers.
  message             One message, including when it was sent, delivered and read, and the Mac build that handled it.
                        --id              The message id. (required)
                        --wait            Wait until it is `sent`, `delivered` or `read`. Exits with an error if that has not happened in time.
                        --timeout         How long --wait waits: 90s, 5m. A minute by default, at most 10 minutes.
  workspaces          The businesses you belong to.
  projects            The projects in a workspace.
                        --workspace       Workspace id, from `workspaces`. (required)
  activity            Who has been answering a project's numbers, and how much.
                        --project         Project id, from `projects`. The chosen project by default.
                        --days            How far back to count. 1 to 365, 30 by default.
  member-activity     One person: what they sent, who to, and the messages.
                        --project         Project id, from `projects`. The chosen project by default.
                        --user            Whose work to report, from `activity`. (required)
                        --days            How far back to count. 1 to 365, 30 by default.
  problems            Sends that failed, or are still waiting for a Mac.
                        --only            `queued` or `failed`.
  lookup              Whether iMessage is known to reach a handle. Answered from your own traffic, not from Apple.
                        --handle          Phone number or Apple ID email. (required)
  typing              Show or hide the typing bubble in a conversation.
                        --chat-id         The conversation. (required)
                        --off             Hide it rather than show it.
  read                Tell the customer their message was seen. Only when a human has looked.
                        --chat-id         The conversation. (required)
                        --unread          Mark unread again.
  react               Add or remove a tapback on a message.
                        --id              The message id. (required)
                        --reaction        heart, like, dislike, laugh, emphasize, question. Defaults to heart.
                        --remove          Take it back.
  unsend              Unsend a message, inside Apple's two-minute window.
                        --id              The message id. (required)
  edit                Change what a sent message says, inside Apple's fifteen-minute window.
                        --id              The message id. (required)
                        --text            The replacement text. An empty edit is not an unsend, and is refused. (required)
  label               Name a number, so threads say which line they arrived on.
                        --id              The number id. (required)
                        --label           Empty clears it back to the bare handle.
  contacts            Names this project has given handles. Shared by everyone on it.
  name                Name a handle, or rename one. contact-add does the same and says what it queued for Apple Contacts.
                        --handle          Phone number or Apple ID email. (required)
                        --name            What to call them. (required)
  contact-add         Add a contact, or rename one, and queue them for Apple Contacts on this project's numbers, so Messages shows their name. Prints what was queued and how to check. --field sets their custom fields for messages to use.
                        --handle          Phone number or Apple ID email. (required)
                        --name            Their full name. Or give --first-name and --last-name.
                        --first-name      Their first name.
                        --last-name       Their last name.
                        --field           A custom field, as name=value. Repeat it for more: --field product=Hoodie --field amount=$48. Sets those fields and keeps the others; name= with nothing or only spaces after it removes one. Messages read them as {{ contact.custom.product }}.
                        --no-sync         Save them in Miss Blue only, not in Apple Contacts.
  contact             One contact, and whether Apple Contacts on each of this project's numbers has them yet: queued, synced or failed.
                        --handle          Phone number or Apple ID email. (required)
  contact-sync        Put a saved contact in Apple Contacts again, on each of this project's numbers or one of them, and wait for each to answer. For a number that did not take it.
                        --handle          Phone number or Apple ID email. (required)
                        --from            Only this number id. Every number of this project by default.
  forget              Remove a name from the project's book.
                        --id              The contact id, from `contacts`. (required)
  webhooks            The endpoints this project sends events to.
  webhook-add         Register where events should go.
                        --url             https, and not a private address. (required)
  webhook-rm          Stop sending to an endpoint.
                        --id              The endpoint id. (required)
  deliveries          What we tried to send an endpoint, and what came back.
                        --id              The endpoint id. (required)
  announcements       Announcements (blasts) in this project, with how each is going.
  announce            Draft an announcement (one message to many people) and preview it. Sends nothing. Show the user the preview (how many people, how many are first contacts and how long their pacing takes, who is left out) and the exact text before `announce-send`.
                        --text            The message. Everybody gets the same words. (required)
                        --to              Phone numbers or emails, separated by commas.
                        --list            List ids or names, separated by commas. Everybody on them now.
                        --tag             Tags, separated by commas. Everybody carrying them now.
                        --from            Number id to send from. Defaults to your only number.
                        --title           An internal name. Nobody receiving it sees this.
                        --at              When to start, with a UTC offset: 2026-10-02T09:00:00-05:00. Otherwise when sent.
                        --time-zone       The zone --at was chosen in, like America/Chicago. Shown in the console.
                        --reply-window-hoursHow long a reply still counts as a reply to it. 1 to 720, 72 by default.
                        --text-b          An A/B test: version B of the message. --text is version A. Each person gets one.
                        --text-c          Version C, with --text-b, for an A/B/C test.
                        --weights         Each version's share of the list, in percent, A first: 50,30,20. An even split unless given.
                        --test-first      Send the versions to this share of the list first, like 20%, then the rest the one with the best reply rate. 5% to 50%.
                        --pick-after      With --test-first: how long after the test has gone out to pick, like 4h. 1h to 72h, 4h by default.
  announce-send       Send a drafted announcement. Prints the preview again. Only after the user has seen the preview and the text and explicitly said yes: pass confirm. Without it nothing is sent.
                        --id              The announcement id, from `announce` or `announcements`. (required)
                        --confirm         The user said yes to this preview. Without it, nothing is sent.
  announce-cancel     Cancel an announcement. One already sending stops; what went out stays out.
                        --id              The announcement id. (required)
  scheduled           Messages scheduled for later, and what became of them.
  schedule            Schedule one message for later. Pick a time that suits the recipient where they are.
                        --to              Phone number or Apple ID email. (required)
                        --text            The message. (required)
                        --at              When, with the recipient's UTC offset: 2026-10-02T09:00:00-05:00. (required)
                        --time-zone       The zone the time was chosen in, like America/Chicago. Shown in the console.
                        --from            Number id to send from. Defaults to your only number.
  schedule-cancel     Cancel a scheduled message that has not gone yet.
                        --id              The scheduled message id, from `scheduled`. (required)
  automations         Automations in this project: what starts each, its steps, and whether it is on.
  automation          One automation, and what switching it on would do: who it reaches now and how long first contacts take.
                        --id              The automation id, from `automations`. (required)
  automation-create   Create an automation, switched off. A keyword reply, or a message when somebody joins a list or gets a tag, then a wait, then a follow-up only if they did not reply. A list or tag automation sends from Auto unless given a number. --hours keeps it to business hours. Only for people who asked to hear from this business.
                        --name            What to call it. Required unless --file has one.
                        --file            A JSON file with the whole automation, as the API takes it. Other flags are ignored.
                        --keyword         Reply when somebody texts one of these words. Separated by commas.
                        --list            Start when somebody joins this list. Id or name.
                        --tag             Start when somebody gets this tag.
                        --trigger         Or `first_message` (somebody new writes) or `conversation_opened` (any message).
                        --text            The first message it sends. Required unless --file.
                        --wait            How long before the follow-up: 30m, 36h, 2d. Up to 31 days.
                        --follow-up       A second message after --wait. By default only if they have not replied since the first.
                        --follow-up-if    When the follow-up goes: `not_replied_since_last` (the default), `not_replied` (since it started), `replied_since_last` or `replied`.
                        --follow-up-anywaySend the follow-up whether or not they replied.
                        --text-b          An A/B test: version B of the first message. --text is version A. Each person gets one version, and keeps it for the follow-up.
                        --text-c          Version C of the first message, with --text-b.
                        --weights         Each version's share of new people, in percent, A first: 50,30,20. Also the follow-up's when it has as many versions. An even split unless given.
                        --follow-up-b     Version B of the follow-up. People on B hear it; anybody on C hears A where there is no C.
                        --follow-up-c     Version C of the follow-up, with --follow-up-b.
                        --from            Number id it sends from. A list or tag automation without one sends from Auto: each person gets the best of this project's numbers.
                        --stop-on-reply   End a person's run as soon as they reply. On unless you pass --stop-on-reply false.
                        --allow-repeat    Let the same person go through it more than once.
                        --hours           Only send between these times, like 08:00-18:00 or 9am-5pm. A message due outside them waits until they open; what starts it still starts it at any time.
                        --time-zone       The zone --hours are in, like America/Chicago. Eastern (America/New_York) unless given.
                        --days            The days it sends on, with --hours: mon-fri, mon,wed,fri or weekends. Every day unless given.
                        --any-time        Send at any hour, with no --hours. The default.
  automation-update   Change an automation. Pass only what changes: --name, --from, --stop-on-reply, --allow-repeat or the hours flags alone keep its trigger and steps; a trigger flag replaces the trigger; --text and the follow-up flags replace the steps; --file replaces the whole thing. People partway through keep their step number.
                        --id              The automation id. (required)
                        --file            A JSON file with the whole automation, as the API takes it.
                        --name            A new name.
                        --keyword         Reply when somebody texts one of these words. Separated by commas.
                        --list            Start when somebody joins this list. Id or name.
                        --tag             Start when somebody gets this tag.
                        --trigger         Or `first_message` (somebody new writes) or `conversation_opened` (any message).
                        --text            A new first message. Replaces the steps, with the follow-up flags.
                        --wait            How long before the follow-up: 30m, 36h, 2d. Up to 31 days.
                        --follow-up       A second message after --wait. By default only if they have not replied since the first.
                        --follow-up-if    When the follow-up goes: `not_replied_since_last` (the default), `not_replied` (since it started), `replied_since_last` or `replied`.
                        --follow-up-anywaySend the follow-up whether or not they replied.
                        --text-b          An A/B test: version B of the first message, with --text as A. Replaces the steps.
                        --text-c          Version C of the first message, with --text-b.
                        --weights         Each version's share of new people, A first: 50,30,20. To change only the weights, use `variant-weights`.
                        --follow-up-b     Version B of the follow-up.
                        --follow-up-c     Version C of the follow-up, with --follow-up-b.
                        --from            Number id it sends from, or `auto` for Auto.
                        --stop-on-reply   End a person's run as soon as they reply: true or false. Absent keeps what it has.
                        --allow-repeat    Let the same person go through it more than once.
                        --hours           Only send between these times, like 08:00-18:00 or 9am-5pm. Keeps its zone and days unless you change them.
                        --time-zone       The zone its hours are in, like America/Chicago. Eastern (America/New_York) for new hours unless given.
                        --days            The days it sends on: mon-fri, mon,wed,fri or weekends. Needs hours, given now or already set.
                        --any-time        Clear its hours: send at any time again.
  automation-on       Switch an automation on. Show the user what it will send and who it reaches first. With include_existing it also messages everybody already on the list or tag, which needs confirm after the user says yes.
                        --id              The automation id. (required)
                        --include-existingAlso start it for everybody already on the list or carrying the tag.
                        --confirm         The user said yes to messaging everybody already there.
  automation-off      Switch an automation off. Everybody partway through it stops.
                        --id              The automation id. (required)
  automation-delete   Delete an automation and everything partway through it. Ask the user first.
                        --id              The automation id. (required)
  automation-runs     Who is in an automation and how far they got, or which automations are messaging one person.
                        --id              The automation id. Required unless --handle.
                        --status          Only `running`, `done`, `stopped` or `failed`.
                        --handle          Instead: what is running for this person right now, across automations.
                        --limit           How many to show. 1 to 500, 100 by default.
                        --offset          How many to skip, for the next page.
  automation-stats    How an automation is doing, step by step: sent, delivered, read (opened), replied and opted out, with reply and opt-out rates, and how people's runs ended. Read only counts people with read receipts on, so it is at least that many.
                        --id              The automation id, from `automations`. (required)
                        --days            Count messages sent in the last this many days. 1 to 365, 30 by default.
                        --all             Count everything since the automation began, instead of --days.
                        --variant         Only this version of each step's text, for A/B/C tests.
  variant-use         "Use this one" in an A/B/C test. For an automation, one step's version for everybody who reaches that step from now on (weights 100/0/0), including people given another version earlier; the others' results stay. For an announcement, everybody not yet sent gets it, which ends a test first's wait. Ask the user first.
                        --automation      The automation id. Or --announcement.
                        --step            With --automation: the step's number, from 1, as `automation-stats` numbers it.
                        --announcement    The announcement id, instead of --automation.
                        --letter          The version: A, B or C. (required)
  variant-weights     Change the weights of an automation's A/B/C test, on the first step with versions (later steps follow its split). They decide the version of people who reach it from now on; anybody already given a version keeps it.
                        --automation      The automation id. (required)
                        --step            The step's number, from 1, as `automation-stats` numbers it. (required)
                        --weights         Each version's share in percent, A first, adding up to 100: 70,30 or 50,30,20. (required)
  automation-replies  Which texts got the replies: who answered an automation, what they said and when, the message they answered, and a link to the conversation. Newest first.
                        --id              The automation id, from `automations`. (required)
                        --step            Only replies to this step's messages: its number, from 1, as `automation-stats` numbers it.
                        --days            Only replies to messages sent in the last this many days. All of them by default.
                        --variant         Only replies to this version of the text, for A/B/C tests.
                        --limit           How many to show. 1 to 100, 25 by default.
                        --cursor          `next_cursor` from the page before, for the next page.
  automation-stop     Take one person out of one automation. Everybody else carries on.
                        --id              The automation id. (required)
                        --handle          Their phone number or email. (required)
  lists               Lists in this project, and how many people are on each.
  list-create         Make a list.
                        --name            Unique in this project. (required)
                        --description     What it is for.
  list-members        Who is on a list, newest first.
                        --list            List id or name. (required)
  list-add            Add people to a list. If an automation starts on this list, each new person is messaged, so that needs confirm after the user says yes.
                        --list            List id or name. (required)
                        --handles         Phone numbers or emails, separated by commas. (required)
                        --confirm         The user said yes to the automation messaging them.
  list-remove         Take somebody off a list. An automation they are in carries on.
                        --list            List id or name. (required)
                        --handle          Their phone number or email. (required)
  tags                Tags in this project, and how many people carry each.
  tag                 Tag people. If an automation starts on this tag, each newly tagged person is messaged, so that needs confirm after the user says yes.
                        --tag             The tag. Case and extra spaces do not matter. (required)
                        --handles         Phone numbers or emails, separated by commas. (required)
                        --confirm         The user said yes to the automation messaging them.
  untag               Take a tag off somebody.
                        --tag             The tag. (required)
                        --handle          Their phone number or email. (required)

  mcp                 Serve MCP over stdio, exposing every command above as a tool.
                        --project <id>    Pin the project this agent acts on.

DOCS
  https://missblue.dev/docs
```

## Documentation

https://missblue.dev/docs/cli

---
name: missblue
description: Send and read iMessages from the user's Miss Blue business numbers with the mb command line. Text a customer, reply in a conversation, check whether a message was delivered, look up whether a number has iMessage, manage contacts and webhooks, and run campaigns (announcements to a list, scheduled messages, automations, lists and tags). Use when the user asks to text, message, iMessage, follow up with, blast, announce to, schedule a message for, automate messages to, or read replies from customers or contacts through Miss Blue, or mentions mb or missblue.
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

## Campaigns

An announcement is one message to many people. Draft it, which sends nothing and prints a
preview, then send it only after the user says yes to that preview:

    mb announce --text "We open at nine from Monday" --list "Spring customers" --tag vip
    mb announce-send --id <announcement id> --confirm

Schedule one message for later, at the recipient's local time with their UTC offset:

    mb schedule --to +15555550100 --text "See you tomorrow" --at 2026-10-02T09:00:00-05:00 --time-zone America/Chicago

Automations answer a keyword, or message somebody when they join a list or get a tag. They
are created switched off:

    mb automation-create --name Hours --keyword hours --text "Open 9 to 5, Monday to Friday"
    mb automation-create --name Welcome --tag new-customer --text "Welcome!" --wait 2d --follow-up "Any questions?"
    mb automation --id <id>          # the steps, and who switching it on reaches
    mb automation-on --id <id>

A list or tag automation sends from Auto unless you pass `--from <number id>`: each person
gets the best of the project's numbers when their first message goes. A reply ends that
person's run (`--stop-on-reply false` keeps it going). The follow-up only goes to people who
have not answered since the message before it; `--follow-up-if` picks another condition
(`not_replied`, `replied_since_last`, `replied`), and the two that wait for a reply need
`--stop-on-reply false`. Change one thing at a time with `mb automation-update --id <id>`
and only that flag, for example `--stop-on-reply false` or `--from auto`.

Lists and tags: `mb lists`,
`mb list-create --name Spring`, `mb list-add --list Spring --handles +1555...,+1555...`,
`mb tags`, `mb tag --tag vip --handles +1555...`, `mb untag`, `mb list-remove`. What is
queued or running: `mb announcements`, `mb scheduled`, `mb automation-runs --id <id>`.

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
- Before any announcement, run `mb announce` and show the user the text and the preview:
  how many people it reaches, how many are first contacts, and who is left out. Send with
  `mb announce-send --confirm` only after they explicitly say yes to that number. The same
  goes for `mb automation-on --include-existing`, and for `mb list-add` or `mb tag` when an
  automation starts on that list or tag: those commands refuse without `--confirm`, and the
  refusal says why. Never pass `--confirm` on the user's behalf.
- Never automate messages to people who have not opted in to hearing from this business.
  An automation on a list or tag messages everybody who is added to it later, too.
- Schedule for the recipient's local time, not the user's or your own: morning where they
  are, not in the middle of their night. Pass the time with their UTC offset for that date.
- Explain first-contact pacing when it applies: people who have never messaged the number
  go out at up to 50 a day per number (the preview gives the real figure), spaced a few
  minutes apart, so a large first announcement takes days. That is expected, not a fault.
  A project's first announcement, and its first automation that writes to people first,
  wait for a person at Miss Blue to read them. On Auto the pace is per number, so the
  preview from `mb automation` counts every number Auto can use.
- If an automation shows a `number_note`, tell the user what it says: its number left the
  project, and it moved to another of the project's numbers or was switched off.
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

### mb announcements

Announcements (blasts) in this project, with how each is going.

### mb announce

Draft an announcement (one message to many people) and preview it. Sends nothing. Show the user the preview (how many people, how many are first contacts and how long their pacing takes, who is left out) and the exact text before `announce-send`.

- `--text <string>` Required. The message. Everybody gets the same words.
- `--to <string>` Phone numbers or emails, separated by commas.
- `--list <string>` List ids or names, separated by commas. Everybody on them now.
- `--tag <string>` Tags, separated by commas. Everybody carrying them now.
- `--from <string>` Number id to send from. Defaults to your only number.
- `--title <string>` An internal name. Nobody receiving it sees this.
- `--at <string>` When to start, with a UTC offset: 2026-10-02T09:00:00-05:00. Otherwise when sent.
- `--time-zone <string>` The zone --at was chosen in, like America/Chicago. Shown in the console.
- `--reply-window-hours <number>` How long a reply still counts as a reply to it. 1 to 720, 72 by default.

### mb announce-send

Send a drafted announcement. Prints the preview again. Only after the user has seen the preview and the text and explicitly said yes: pass confirm. Without it nothing is sent.

- `--id <string>` Required. The announcement id, from `announce` or `announcements`.
- `--confirm` The user said yes to this preview. Without it, nothing is sent.

### mb announce-cancel

Cancel an announcement. One already sending stops; what went out stays out.

- `--id <string>` Required. The announcement id.

### mb scheduled

Messages scheduled for later, and what became of them.

### mb schedule

Schedule one message for later. Pick a time that suits the recipient where they are.

- `--to <string>` Required. Phone number or Apple ID email.
- `--text <string>` Required. The message.
- `--at <string>` Required. When, with the recipient's UTC offset: 2026-10-02T09:00:00-05:00.
- `--time-zone <string>` The zone the time was chosen in, like America/Chicago. Shown in the console.
- `--from <string>` Number id to send from. Defaults to your only number.

### mb schedule-cancel

Cancel a scheduled message that has not gone yet.

- `--id <string>` Required. The scheduled message id, from `scheduled`.

### mb automations

Automations in this project: what starts each, its steps, and whether it is on.

### mb automation

One automation, and what switching it on would do: who it reaches now and how long first contacts take.

- `--id <string>` Required. The automation id, from `automations`.

### mb automation-create

Create an automation, switched off. A keyword reply, or a message when somebody joins a list or gets a tag, then a wait, then a follow-up only if they did not reply. A list or tag automation sends from Auto unless given a number. Only for people who asked to hear from this business.

- `--name <string>` What to call it. Required unless --file has one.
- `--file <string>` A JSON file with the whole automation, as the API takes it. Other flags are ignored.
- `--keyword <string>` Reply when somebody texts one of these words. Separated by commas.
- `--list <string>` Start when somebody joins this list. Id or name.
- `--tag <string>` Start when somebody gets this tag.
- `--trigger <string>` Or `first_message` (somebody new writes) or `conversation_opened` (any message).
- `--text <string>` The first message it sends. Required unless --file.
- `--wait <string>` How long before the follow-up: 30m, 36h, 2d. Up to 31 days.
- `--follow-up <string>` A second message after --wait. By default only if they have not replied since the first.
- `--follow-up-if <string>` When the follow-up goes: `not_replied_since_last` (the default), `not_replied` (since it started), `replied_since_last` or `replied`.
- `--follow-up-anyway` Send the follow-up whether or not they replied.
- `--from <string>` Number id it sends from. A list or tag automation without one sends from Auto: each person gets the best of this project's numbers.
- `--stop-on-reply` End a person's run as soon as they reply. On unless you pass --stop-on-reply false.
- `--allow-repeat` Let the same person go through it more than once.

### mb automation-update

Change an automation. Pass only what changes: --name, --from, --stop-on-reply or --allow-repeat alone keep its trigger and steps; a trigger flag replaces the trigger; --text and the follow-up flags replace the steps; --file replaces the whole thing. People partway through keep their place.

- `--id <string>` Required. The automation id.
- `--file <string>` A JSON file with the whole automation, as the API takes it.
- `--name <string>` A new name.
- `--keyword <string>` Reply when somebody texts one of these words. Separated by commas.
- `--list <string>` Start when somebody joins this list. Id or name.
- `--tag <string>` Start when somebody gets this tag.
- `--trigger <string>` Or `first_message` (somebody new writes) or `conversation_opened` (any message).
- `--text <string>` A new first message. Replaces the steps, with the follow-up flags.
- `--wait <string>` How long before the follow-up: 30m, 36h, 2d. Up to 31 days.
- `--follow-up <string>` A second message after --wait. By default only if they have not replied since the first.
- `--follow-up-if <string>` When the follow-up goes: `not_replied_since_last` (the default), `not_replied` (since it started), `replied_since_last` or `replied`.
- `--follow-up-anyway` Send the follow-up whether or not they replied.
- `--from <string>` Number id it sends from, or `auto` for Auto.
- `--stop-on-reply` End a person's run as soon as they reply: true or false. Absent keeps what it has.
- `--allow-repeat` Let the same person go through it more than once.

### mb automation-on

Switch an automation on. Show the user what it will send and who it reaches first. With include_existing it also messages everybody already on the list or tag, which needs confirm after the user says yes.

- `--id <string>` Required. The automation id.
- `--include-existing` Also start it for everybody already on the list or carrying the tag.
- `--confirm` The user said yes to messaging everybody already there.

### mb automation-off

Switch an automation off. Everybody partway through it stops.

- `--id <string>` Required. The automation id.

### mb automation-delete

Delete an automation and everything partway through it. Ask the user first.

- `--id <string>` Required. The automation id.

### mb automation-runs

Who is in an automation and how far they got, or which automations are messaging one person.

- `--id <string>` The automation id. Required unless --handle.
- `--status <string>` Only `running`, `done`, `stopped` or `failed`.
- `--handle <string>` Instead: what is running for this person right now, across automations.
- `--limit <number>` How many to show. 1 to 500, 100 by default.
- `--offset <number>` How many to skip, for the next page.

### mb automation-stop

Take one person out of one automation. Everybody else carries on.

- `--id <string>` Required. The automation id.
- `--handle <string>` Required. Their phone number or email.

### mb lists

Lists in this project, and how many people are on each.

### mb list-create

Make a list.

- `--name <string>` Required. Unique in this project.
- `--description <string>` What it is for.

### mb list-members

Who is on a list, newest first.

- `--list <string>` Required. List id or name.

### mb list-add

Add people to a list. If an automation starts on this list, each new person is messaged, so that needs confirm after the user says yes.

- `--list <string>` Required. List id or name.
- `--handles <string>` Required. Phone numbers or emails, separated by commas.
- `--confirm` The user said yes to the automation messaging them.

### mb list-remove

Take somebody off a list. An automation they are in carries on.

- `--list <string>` Required. List id or name.
- `--handle <string>` Required. Their phone number or email.

### mb tags

Tags in this project, and how many people carry each.

### mb tag

Tag people. If an automation starts on this tag, each newly tagged person is messaged, so that needs confirm after the user says yes.

- `--tag <string>` Required. The tag. Case and extra spaces do not matter.
- `--handles <string>` Required. Phone numbers or emails, separated by commas.
- `--confirm` The user said yes to the automation messaging them.

### mb untag

Take a tag off somebody.

- `--tag <string>` Required. The tag.
- `--handle <string>` Required. Their phone number or email.

### mb mcp

Serve every command above as MCP tools over stdio. `--project <id>` pins the project for that agent.

<!-- mb skill 0.2.42 5c9f5c87cf0997ff -->

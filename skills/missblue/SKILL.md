---
name: missblue
description: Send and read iMessages from the user's Miss Blue business numbers with the mb command line. Text a customer, reply in a conversation, check whether a message was delivered or read, look up whether a number has iMessage, add contacts to Apple Contacts and tag them, manage webhooks, and run campaigns (announcements to a list, scheduled messages, automations and how they are doing, A/B/C tests of their texts, lists and tags). Use when the user asks to text, message, iMessage, follow up with, blast, announce to, schedule a message for, automate messages to, A/B test messages to, or read replies from customers or contacts through Miss Blue, or mentions mb or missblue.
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

    mb message --id <message id>     # its delivery: when it was sent, delivered and read
    mb problems                      # everything that failed or is still waiting

Look up whether a number is known to have iMessage: `mb lookup +15555550100`.
Contacts: `mb contacts`, `mb contact-add`, `mb contact`, `mb forget --id <id>`.

## The basics

Add a contact. It is saved to the project and queued for Apple Contacts on the project's
numbers, so Messages there shows their name instead of the number. `mb contact` shows each
number as queued, then synced, or failed and why:

    mb contact-add --handle +15555550100 --first-name Ada --last-name Lovelace
    mb contact --handle +15555550100
    mb contact-sync --handle +15555550100     # push again to a number that did not take it

`--no-sync` keeps a contact in Miss Blue only. Then tag them, message them, and see what
happened:

    mb tag --tag vip --handles +15555550100
    mb send --to +15555550100 --text "Hi Ada, your order is ready" --wait delivered
    mb message --id <message id> --wait read --timeout 10m

`--wait` takes `sent`, `delivered` or `read`, and stops at its `--timeout` (a minute unless
you say, ten at most) with an error that says where the message got to. After
`mb send --wait` the message was accepted even when the wait runs out. Read receipts only appear
if the recipient has them turned on, so `read` may never come; say so rather than waiting
again. Their reply is in `mb thread --chat-id <chat_id>`: the send's answer carries the
chat_id, and `mb threads` lists conversations, newest first.

To give somebody a link to a conversation, use its `url` (`https://missblue.dev/c/...`), which
`mb send`, `mb threads` and `mb thread` print beside `link_code`. Pass it on as it is; do not
build one. It opens only for people allowed to read that conversation. A first message to
somebody new that is still waiting for its number has no link yet; `mb threads` lists it once
it has gone. Webhooks carry the same link as `data.conversation.url`.
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

Announcements, scheduled messages and automation steps are Liquid, filled in for each person
at the moment that message sends. `{{ contact.first_name }}`, `{{ contact.last_name }}` and
`{{ contact.name }}` come from their contact, and so do the contact's own fields, as
`{{ contact.custom.product }}` (or `{{ contact.custom["Checkout link"] }}` for a name with a
space). Always give a variable a `default:` fallback, so somebody with nothing saved reads
"Hi there" rather than "Hi ,":

    mb automation-create --name "Cart reminder" --tag cart-abandoned --text 'Hi {{ contact.first_name | default: "there" }}, your {{ contact.custom.product }} ({{ contact.custom.amount }}) is still waiting: {{ contact.custom.checkout_link }}' --wait 1d --follow-up 'Still thinking it over, {{ contact.first_name | default: "there" }}? {{ contact.custom.checkout_link }}'
    mb contact-add --handle +15555550100 --first-name Ada --field product="Blue hoodie" --field amount='$48' --field checkout_link=https://shop.example/c/91

Once it is on, tagging somebody `cart-abandoned` starts it for them. `--field` sets those
fields and keeps the others; `--field name=` with nothing, or only spaces, after the `=`
removes one. A field changed before a follow-up sends is what the follow-up says. The
fields a project's contacts have are listed with the variables at
`GET /v1/projects/{id}/templates/variables`. `mb send` text goes exactly as typed: it is
not filled in.

Keep an automation to business hours with `--hours 08:00-18:00 --days mon-fri`: Eastern
time unless you pass `--time-zone America/Chicago` (or the recipient's zone), every day
unless you pass `--days`. What starts it still starts it at any time; a message due outside
the hours waits until they next open, and first contacts are still paced inside them.
`mb automation-update --id <id> --any-time` clears the hours.

Lists and tags: `mb lists`,
`mb list-create --name Spring`, `mb list-add --list Spring --handles +1555...,+1555...`,
`mb tags`, `mb tag --tag vip --handles +1555...`, `mb untag`, `mb list-remove`. What is
queued or running: `mb announcements`, `mb scheduled`, `mb automation-runs --id <id>`.

How an automation is doing, and which of its texts got the replies:

    mb automation-stats --id <id>              # the last 30 days; --days 90, or --all
    mb automation-replies --id <id> --step 4   # who answered step 4, what they said, and a link

`automation-stats` gives each send step's sent, delivered, read (opened), replied and opted
out, with a reply rate and an opt-out rate, and how people's runs ended. Read receipts only
come from people who have them turned on, so read is at least that many, never a rate.
A reply counts for a step when that step's message was the last thing sent to that person
before they wrote, within a week (not after a message from the team or an announcement),
and each person counts once however many texts they send. Opted out counts only replies
that opted them out; a STOP to a project that handles opt-outs itself shows as `said_stop`.
An automation older than the record of which step sent each message is counted from then
(`from_recorded_since`).
`automation-replies` lists every text, newest first; for more, run the `next` it prints.

### A/B/C tests

A message can have two or three versions, to learn which one gets replies (and which one
makes people opt out). `--text` is version A; add `--text-b`, `--text-c` and `--weights`
(each version's share, A first, adding up to 100; an even split unless given):

    mb automation-create --name Tour --tag toured --text "Thanks for coming by!" --text-b "Want a second look?" --weights 50,50 --wait 1d --follow-up "Still thinking it over?" --follow-up-b "Happy to set up another visit."
    mb announce --text "Open house Saturday." --text-b "Come see it Saturday?" --list Leads --test-first 20% --pick-after 4h

In an automation each person is given a version the first time they reach a message with
versions, and keeps it: somebody on B hears B's follow-up too (A where a message has no B).
An announcement divides its list by the weights when it is drafted; with `--test-first` it
sends the versions to that share of the list, waits `--pick-after` from when the last of
them went, then sends everybody else the version with the best reply rate, leaving out one
with clearly more opt-outs.

`mb automation-stats` puts each tested step's versions side by side and says whether one is
ahead: "B gets more replies (18% vs 11%), and opt-outs are about the same." Under 30 people
reached per version it says "Not enough yet", and a gap too small to be sure is "about the
same". Say that plainly; never call a winner the stats do not call. Then, if the user wants:

    mb variant-use --automation <id> --step 1 --letter B       # everybody reaching step 1 gets B
    mb variant-weights --automation <id> --step 1 --weights 70,30
    mb variant-use --announcement <id> --letter B               # the rest of an announcement

`variant-use` sends that version to everybody who reaches the step from now on, including
people given another version earlier. `variant-weights` works on the first step with
versions only (later steps follow its split): people already given one keep it. Every
version's results stay. `automation-update --text` replaces the steps and ends a test.

## Rules

- Only message people who expect to hear from this business: its customers, and people
  who asked. Never send marketing to a list the user has not confirmed.
- Show the user the exact text and the recipients, and get a yes, before sending to more
  than one person or to anybody who has not messaged this number before.
- First contacts (people who have never messaged the number) are limited per number per
  day, 50 by default, and spaced out. A send may be accepted and held; that is expected.
  Do not try to get around the limit.
- The server honours STOP and other opt-outs. A refused send to somebody who opted out
  is final: do not retry it from another number. If they write back afterwards, you may
  answer them one to one with `mb send`; campaigns and automations still skip
  them until they text START.
- When somebody asks you to stop, in any words ("stop texting me", "not interested, take
  me off", "wrong person, leave me alone"), run `mb opt-out --handle <them> --note "<what
  they said>"` straight away, before anything else, and do not message them again. It is
  safe to run when Miss Blue already caught it.
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
- In an A/B/C test, show the user every version before sending: each is a message people
  get. Run `mb variant-use` or `mb variant-weights` only after the user asks, and report the
  verdict as the stats say it, including "Not enough yet".
- `--allow-duplicate` is only for a deliberate repeat. Do not use it to push a message
  through.
- Never send a message again because `--wait` ran out or it is still pending: it was sent,
  or is waiting for its number, and goes out on its own. Check it with `mb message --id`.
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
- `--wait <string>` Wait until it is `sent`, `delivered` or `read`, then print it. Exits with an error if that has not happened in time.
- `--timeout <string>` How long --wait waits: 90s, 5m. A minute by default, at most 10 minutes.

### mb threads

Conversations, most recent first.

### mb thread

Every message in one conversation.

- `--chat-id <string>` Required. From `threads`.

### mb messages

Recent messages across this project's numbers.

### mb message

One message, including when it was sent, delivered and read, and the Mac build that handled it.

- `--id <string>` Required. The message id.
- `--wait <string>` Wait until it is `sent`, `delivered` or `read`. Exits with an error if that has not happened in time.
- `--timeout <string>` How long --wait waits: 90s, 5m. A minute by default, at most 10 minutes.

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

Name a handle, or rename one. contact-add does the same and says what it queued for Apple Contacts.

- `--handle <string>` Required. Phone number or Apple ID email.
- `--name <string>` Required. What to call them.

### mb contact-add

Add a contact, or rename one, and queue them for Apple Contacts on this project's numbers, so Messages shows their name. Prints what was queued and how to check. --field sets their custom fields for messages to use.

- `--handle <string>` Required. Phone number or Apple ID email.
- `--name <string>` Their full name. Or give --first-name and --last-name.
- `--first-name <string>` Their first name.
- `--last-name <string>` Their last name.
- `--field <string>` A custom field, as name=value. Repeat it for more: --field product=Hoodie --field amount=$48. Sets those fields and keeps the others; name= with nothing or only spaces after it removes one. Messages read them as {{ contact.custom.product }}.
- `--no-sync` Save them in Miss Blue only, not in Apple Contacts.

### mb contact

One contact, and whether Apple Contacts on each of this project's numbers has them yet: queued, synced or failed.

- `--handle <string>` Required. Phone number or Apple ID email.

### mb contact-sync

Put a saved contact in Apple Contacts again, on each of this project's numbers or one of them, and wait for each to answer. For a number that did not take it.

- `--handle <string>` Required. Phone number or Apple ID email.
- `--from <string>` Only this number id. Every number of this project by default.

### mb forget

Remove a name from the project's book.

- `--id <string>` Required. The contact id, from `contacts`.

### mb opt-outs

Everybody this project will not message, and how each asked: a reply Miss Blue understood (keyword) or one added by hand or by key (staff).

### mb opt-out

Stop messaging somebody who asked not to be messaged, however they asked. Anything already queued to them is cancelled, and every later send to them is refused. Do this whenever somebody asks you to stop, in any words.

- `--handle <string>` Required. Phone number or email address. No saved contact needed.
- `--note <string>` How they asked, for whoever reads the list later.

### mb opt-out-remove

Message somebody again after they opted out, because they asked to start again: confirm with the person you work for first. Needs a key made by an owner or admin of the organization.

- `--handle <string>` Required. Phone number or email address.
- `--note <string>` Required. How they asked to start again, for example "texted START on 9/27".

### mb block

Block a saved contact across the whole organization: nothing is sent to them from any number, and anything queued is cancelled.

- `--handle <string>` Required. Phone number or Apple ID email of a saved contact.

### mb unblock

Lift a block, so the organization may message this contact again. Confirm with the person you work for first. Needs a key made by an owner or admin of the organization.

- `--handle <string>` Required. Phone number or Apple ID email of a saved contact.

### mb cancel

Cancel a message that has not gone yet: queued, held for review, or waiting for its number to come back.

- `--id <string>` Required. The message id.

### mb resend

Send a held or failed message again, as it was. Confirm with the person you work for first.

- `--id <string>` Required. The message id.

### mb resolve

Mark a conversation done. It opens again by itself when they write back.

- `--chat-id <string>` Required. The conversation, from `threads`.
- `--handle <string>` Who the conversation is with. Read from a one-to-one chat_id when left out.

### mb reopen

Open a conversation that was marked done.

- `--chat-id <string>` Required. The conversation, from `threads`.
- `--handle <string>` Who the conversation is with. Read from a one-to-one chat_id when left out.

### mb notes

The team's internal notes on a conversation. The customer never sees them.

- `--chat-id <string>` Required. The conversation, from `threads`.

### mb note

Leave an internal note on a conversation for the team. The customer never sees it.

- `--chat-id <string>` Required. The conversation, from `threads`.
- `--text <string>` Required. The note.
- `--handle <string>` Who the conversation is with. Read from a one-to-one chat_id when left out.

### mb note-rm

Remove an internal note. Only one this key, or you, wrote.

- `--id <string>` Required. The note id, from `notes`.

### mb group-create

Start a group iMessage with two or more people and send its first message. Confirm with the person you work for first.

- `--to <string>` Required. Two or more phone numbers or Apple ID emails, comma separated.
- `--text <string>` Required. The first message.
- `--from <string>` Which of this project's numbers. The only one by default.

### mb group

One group conversation: its name and who is in it.

- `--chat-id <string>` Required. The conversation, from `threads`.

### mb group-rename

Name a group conversation, as everybody in it sees it. Confirm with the person you work for first.

- `--chat-id <string>` Required. The conversation, from `threads`.
- `--name <string>` Required. The new name.

### mb group-add

Add somebody to a group conversation; everybody in it sees them join. Confirm with the person you work for first.

- `--chat-id <string>` Required. The conversation, from `threads`.
- `--handle <string>` Required. Phone number or Apple ID email.

### mb group-remove

Take somebody out of a group conversation; everybody in it sees them leave. Confirm with the person you work for first.

- `--chat-id <string>` Required. The conversation, from `threads`.
- `--handle <string>` Required. Phone number or Apple ID email.

### mb templates

The project's saved message templates.

### mb template-add

Save a message template. It can use {{ variables }}: see `template-variables`.

- `--name <string>` Required. What to call it.
- `--text <string>` Required. The message.

### mb template-update

Change a saved template's name and text.

- `--id <string>` Required. The template id, from `templates`.
- `--name <string>` Required. What to call it.
- `--text <string>` Required. The message.

### mb template-rm

Delete a saved template.

- `--id <string>` Required. The template id, from `templates`.

### mb template-preview

Show how a message with {{ variables }} reads for one contact, or for somebody with no details.

- `--text <string>` Required. The message.
- `--handle <string>` A saved contact to fill it in for.

### mb template-variables

The {{ variables }} a message can use in this project, custom fields included.

### mb project

This project: its numbers, its settings, and your role in it.

### mb project-rename

Rename this project. Needs a key made by an owner or admin.

- `--name <string>` Required. The new name.

### mb setting

Change one project setting: opt-out-detection on or off, auto-typing on or off, or sender-routing single or round-robin. Turning opt-out detection off, and sender routing, need a key made by an owner or admin.

- `--name <string>` Required. opt-out-detection, auto-typing or sender-routing.
- `--value <string>` Required. on or off; single or round-robin for sender-routing.

### mb sending-stats

How much each of this project's numbers has sent today, and how much it may still send.

### mb traffic

Messages in and out over time, per day.

- `--days <number>` How far back to count. 1 to 90, 30 by default.

### mb report

The project's outreach report: reach, replies and response times.

- `--days <number>` How far back to count. 1 to 90, 30 by default.

### mb webhook-on

Turn a webhook endpoint back on.

- `--id <string>` Required. The endpoint id, from `webhooks`.

### mb webhook-off

Pause a webhook endpoint without deleting it.

- `--id <string>` Required. The endpoint id, from `webhooks`.

### mb list-rename

Rename a list, or change its description.

- `--list <string>` Required. The list's name or id, from `lists`.
- `--name <string>` Required. The new name.
- `--description <string>` What the list is for.

### mb list-delete

Delete a list. The contacts on it are kept.

- `--list <string>` Required. The list's name or id, from `lists`.

### mb audience

Which lists and tags one person is on in this project.

- `--handle <string>` Required. Phone number or Apple ID email.

### mb number

One of this project's numbers: its handle, label and whether it is on iMessage now.

- `--from <string>` Which of this project's numbers. The only one by default.

### mb number-profile

Set the name people see for a number in iMessage. Everybody it messages sees the change: confirm with the person you work for first.

- `--from <string>` Which of this project's numbers. The only one by default.
- `--first-name <string>` Required. First name.
- `--last-name <string>` Last name.

### mb call-forwarding

Where calls to a number are forwarded, if anywhere.

- `--from <string>` Which of this project's numbers. The only one by default.

### mb call-forward

Ask for calls to a number to be forwarded to another phone. It is a request staff carry out, and a number gets two a month: confirm with the person you work for first.

- `--from <string>` Which of this project's numbers. The only one by default.
- `--to <string>` Required. The phone number to forward to.

### mb unread

How many conversations have messages you have not read. Needs a signed-in person (mb login): a key reads nothing, so it always sees 0.

### mb location-request

Ask somebody to share their location in Find My. Confirm with the person you work for first.

- `--chat-id <string>` Required. The conversation, from `threads`.
- `--to <string>` Required. Their phone number or Apple ID email.

### mb location

Somebody's shared location, when they have shared it.

- `--chat-id <string>` Required. The conversation, from `threads`.
- `--to <string>` Required. Their phone number or Apple ID email.

### mb sync

Read a number's conversations from its Mac again, to fill in anything missed.

- `--from <string>` Which of this project's numbers. The only one by default.

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
- `--text-b <string>` An A/B test: version B of the message. --text is version A. Each person gets one.
- `--text-c <string>` Version C, with --text-b, for an A/B/C test.
- `--weights <string>` Each version's share of the list, in percent, A first: 50,30,20. An even split unless given.
- `--test-first <string>` Send the versions to this share of the list first, like 20%, then the rest the one with the best reply rate. 5% to 50%.
- `--pick-after <string>` With --test-first: how long after the test has gone out to pick, like 4h. 1h to 72h, 4h by default.

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

Create an automation, switched off. A keyword reply, or a message when somebody joins a list or gets a tag, then a wait, then a follow-up only if they did not reply. A list or tag automation sends from Auto unless given a number. --hours keeps it to business hours. Only for people who asked to hear from this business.

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
- `--text-b <string>` An A/B test: version B of the first message. --text is version A. Each person gets one version, and keeps it for the follow-up.
- `--text-c <string>` Version C of the first message, with --text-b.
- `--weights <string>` Each version's share of new people, in percent, A first: 50,30,20. Also the follow-up's when it has as many versions. An even split unless given.
- `--follow-up-b <string>` Version B of the follow-up. People on B hear it; anybody on C hears A where there is no C.
- `--follow-up-c <string>` Version C of the follow-up, with --follow-up-b.
- `--from <string>` Number id it sends from. A list or tag automation without one sends from Auto: each person gets the best of this project's numbers.
- `--stop-on-reply` End a person's run as soon as they reply. On unless you pass --stop-on-reply false.
- `--allow-repeat` Let the same person go through it more than once.
- `--hours <string>` Only send between these times, like 08:00-18:00 or 9am-5pm. A message due outside them waits until they open; what starts it still starts it at any time.
- `--time-zone <string>` The zone --hours are in, like America/Chicago. Eastern (America/New_York) unless given.
- `--days <string>` The days it sends on, with --hours: mon-fri, mon,wed,fri or weekends. Every day unless given.
- `--any-time` Send at any hour, with no --hours. The default.

### mb automation-update

Change an automation. Pass only what changes: --name, --from, --stop-on-reply, --allow-repeat or the hours flags alone keep its trigger and steps; a trigger flag replaces the trigger; --text and the follow-up flags replace the steps; --file replaces the whole thing. People partway through keep their step number.

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
- `--text-b <string>` An A/B test: version B of the first message, with --text as A. Replaces the steps.
- `--text-c <string>` Version C of the first message, with --text-b.
- `--weights <string>` Each version's share of new people, A first: 50,30,20. To change only the weights, use `variant-weights`.
- `--follow-up-b <string>` Version B of the follow-up.
- `--follow-up-c <string>` Version C of the follow-up, with --follow-up-b.
- `--from <string>` Number id it sends from, or `auto` for Auto.
- `--stop-on-reply` End a person's run as soon as they reply: true or false. Absent keeps what it has.
- `--allow-repeat` Let the same person go through it more than once.
- `--hours <string>` Only send between these times, like 08:00-18:00 or 9am-5pm. Keeps its zone and days unless you change them.
- `--time-zone <string>` The zone its hours are in, like America/Chicago. Eastern (America/New_York) for new hours unless given.
- `--days <string>` The days it sends on: mon-fri, mon,wed,fri or weekends. Needs hours, given now or already set.
- `--any-time` Clear its hours: send at any time again.

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

### mb automation-stats

How an automation is doing, step by step: sent, delivered, read (opened), replied and opted out, with reply and opt-out rates, and how people's runs ended. Read only counts people with read receipts on, so it is at least that many.

- `--id <string>` Required. The automation id, from `automations`.
- `--days <number>` Count messages sent in the last this many days. 1 to 365, 30 by default.
- `--all` Count everything since the automation began, instead of --days.
- `--variant <string>` Only this version of each step's text, for A/B/C tests.

### mb variant-use

"Use this one" in an A/B/C test. For an automation, one step's version for everybody who reaches that step from now on (weights 100/0/0), including people given another version earlier; the others' results stay. For an announcement, everybody not yet sent gets it, which ends a test first's wait. Ask the user first.

- `--automation <string>` The automation id. Or --announcement.
- `--step <number>` With --automation: the step's number, from 1, as `automation-stats` numbers it.
- `--announcement <string>` The announcement id, instead of --automation.
- `--letter <string>` Required. The version: A, B or C.

### mb variant-weights

Change the weights of an automation's A/B/C test, on the first step with versions (later steps follow its split). They decide the version of people who reach it from now on; anybody already given a version keeps it.

- `--automation <string>` Required. The automation id.
- `--step <number>` Required. The step's number, from 1, as `automation-stats` numbers it.
- `--weights <string>` Required. Each version's share in percent, A first, adding up to 100: 70,30 or 50,30,20.

### mb automation-replies

Which texts got the replies: who answered an automation, what they said and when, the message they answered, and a link to the conversation. Newest first.

- `--id <string>` Required. The automation id, from `automations`.
- `--step <number>` Only replies to this step's messages: its number, from 1, as `automation-stats` numbers it.
- `--days <number>` Only replies to messages sent in the last this many days. All of them by default.
- `--variant <string>` Only replies to this version of the text, for A/B/C tests.
- `--limit <number>` How many to show. 1 to 100, 25 by default.
- `--cursor <string>` `next_cursor` from the page before, for the next page.

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

<!-- mb skill 0.2.50 2916b4180d00d4fc -->

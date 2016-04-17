# hubot-deezer

A simple shared music player controlled by hubot.

See [`src/scripts/deezer.coffee`](src/scripts/deezer.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-deezer --save`

Then add **hubot-deezer** to your `external-scripts.json`:

```json
[
  "hubot-deezer"
]
```

Setup environment variables.

```
PUSHER_APP_ID=<Pusher ID>
PUSHER_KEY=<Your Pusher Key>
PUSHER_SECRET=<Your Pusher Secret>
DEEZER_APP_ID=<Your Deezer App ID>
```

Open <Your host>/hubot-deezer on your browser.

## Sample Interaction

```
user1>> deezer add Love yourself
hubot>> Searching "Love yourself" ...
        Type `deezer add NUMBER` to add the song.
        0. Love Yourself - Justin Bieber
        1. Love Yourself - William Singe
user1>> deezer add 0
hubot>> 'Love Yourself - Justin Bieber' is successfully added.
```

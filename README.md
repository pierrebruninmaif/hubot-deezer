# hubot-deezer

A simple shared music player controlled by hubot.

See [`src/deezer.coffee`](src/deezer.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-deezer --save`

Then add **hubot-deezer** to your `external-scripts.json`:

```json
[
  "hubot-deezer"
]
```

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

# hubot-deezer

A simple shared music player controlled by hubot. Let **everyone** in your team **add** / **remove** / **play** / **skip** songs.
They can also control volume, repeat and shuffle status of your player.

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
DEEZER_APP_ID=<Your Deezer App ID>
PUSHER_APP_ID=<Your Pusher App ID>
PUSHER_KEY=<Your Pusher Key>
PUSHER_SECRET=<Your Pusher Secret>
```

## How to use it

1. Open a web browser on your computer which is connected to a good speaker.
2. Sign in to [deezer](https://deezer.com).
3. Visit `http://<Your Host>/hubot-deezer`.

You can now control your music player with your teammates using hubot. 

## Sample Interaction

```
user1>> deezer search Love yourself
hubot>> Searching "Love yourself" ...
        Type `deezer add NUMBER` to add the song.
        0. Love Yourself - Justin Bieber
        1. Love Yourself - William Singe
user1>> deezer add 0
hubot>> **Love Yourself** - *Justin Bieber* is added.
```

## Commands
Type `deezer help` to see what you can do.

```
deezer help - Show help.

*Search Tracks*
deezer search QUERY - Search songs with QUERY.
deezer search artist:"ARTIST" - Search songs with artist name.
deezer search track:"TITLE" - Search songs with song title.

*Player Control*
deezer status - Display current player status.
deezer play [INDEX] - Play music. Play a track at the INDEX if presented.
deezer (pause|stop) - Pause music.
deezer next - Play next song.
deezer prev - Play previous song.
deezer seek 0-100 - Set the position of the reader head in the currently playing track.
deezer volume (0-100|up|down) - Set the volume level of the current player.
deezer repeat (no|all|one) - Set the repeat mode of the current player.
deezer shuffle (true|false) - Whether to shuffle the order of the tracks in the current player.
deezer add INDEX - Add the track in search result to the end of the playlist.
deezer list - Display songs in playlist.
```

## External Services

#### DEEZER
- International music streaming service.
- https://deezer.com
- Visit https://developers.deezer.com to get your Deezer App ID

#### PUSHER
- Pus/sub messaging service.
- Free plan may work for this project.
- https://pusher.com


# Description:
#   A simple shared music player controlled by hubot.
#
# Configuration:
#   PUSHER_APP_ID
#   PUSHER_KEY
#   PUSHER_SECRET
#   DEEZER_APP_ID
#
# Commands:
#   deezer help
#
# Author:
#   Sungwon Lee <ssowonny@gmail.com>

Pusher = require('pusher')
request = require('request')
jade = require('jade')
fs = require('fs')
path = require('path')

module.exports = (robot) ->
  pusher = new Pusher {
    appId: process.env.PUSHER_APP_ID
    key: process.env.PUSHER_KEY
    secret: process.env.PUSHER_SECRET
    encrypted: true
  }
  pusher.port = 443

  robot.hear /^(hubot |)deezer help$/i, (res) ->
    res.send """
      deezer help - Show help.
      deezer search QUERY - Search songs with the QUERY.

      *Play Control*
      deezer status - Display current player status.
      deezer play [INDEX] - Play music. Play a track at the INDEX if presented.
      deezer pause - Pause music.
      deezer next - Play next song.
      deezer prev - Play previous song.
      deezer seek 0-100 - Set the position of the reader head in the currently playing track.
      deezer volume (0-100|up|down) - Set the volume level of the current player.
      deezer repeat (no|all|one) - Set the repeat mode of the current player.
      deezer shuffle (true|false) - Whether to shuffle the order of the tracks in the current player.

      *Playlist Control*
      deezer add INDEX - Add the track in search result to the end of the playlist.
      deezer add "QUERY" - Add the first song searched with QUERY string.
      deezer insert INDEX - Insert the track in search result to the next of the current track.
      deezer insert "QUERY" - Insert the first song searched with QUERY string to the next of the current track.
      deezer list [COUNT|all] - Display songs in playlist.
      """

  robot.hear /^(hubot |)deezer (status|next|prev|play|pause|seek|volume|repeat|shuffle) *(.*)$/i, (res) ->
    pusher.trigger('hubot-deezer', 'control', {
      room: res.message.room
      action: res.match[2]
      value: res.match[3]
    })

  robot.hear /^(hubot |)deezer list *([0-9]+|all|)$/i, (res) ->
    pusher.trigger('hubot-deezer', 'playlist', {
      room: res.message.room
      action: 'list'
      size: res.match[2]
    })

  search = (query, callback) ->
    request.get 'https://api.deezer.com/search?q=' + query, (error, response, body) ->
      if error 
        callback(error)
      else if response.statusCode != 200
        callback(new Error("Failed to search '#{query}'. Please try again."))
      else
        callback(undefined, JSON.parse(body).data)

  _searchResult = null
  robot.hear /^(hubot |)deezer search (.*)$/i, (res) ->
    query = res.match[2].replace(/['"]+/g, '')
    res.send "Searching \"#{query}\" ..."
    search query, (error, list) ->
      return res.send error.message if error
      return res.send 'No Result.' if list.length == 0

      _searchResult = list
      result = for track, index in list
        "*#{index}*. #{track.title} - _#{track.artist?.name}_"
      res.send "_Type `deezer add NUMBER` to add the song._\n>>>\n#{result.join('\n')}"

  robot.hear /^(hubot |)deezer (add|insert) ([0-9]+)$/i, (res) ->
    index = parseInt res.match[3]
    if _searchResult && index >= 0 && index < _searchResult.length
      pusher.trigger('hubot-deezer', 'playlist', {
        room: res.message.room
        action: res.match[2]
        id: _searchResult[index].id
      })
    else
      res.send "Select a number among the search result. (Try `deezer search QUERY`.)"

  robot.hear /^(hubot |)deezer (add|insert) ['“”\"](.*)['“”\"]$/i, (res) ->
    query = res.match[3]
    res.send "Searching \"#{query}\" ..."
    search query, (error, list) ->
      return res.send error.message if error
      return res.send 'No Result.' if list.length == 0

      pusher.trigger('hubot-deezer', 'playlist', {
        room: res.message.room
        action: res.match[2]
        id: list[0].id
      })

  robot.router.get '/hubot/deezer/app.js', (req, res) ->
    # TODO Load the file on loading
    fs.readFile path.resolve(__dirname, '../assets/app.js'), 'utf8', (err, data) =>
      throw err if err
      res.send data

  robot.router.get '/hubot/deezer', (req, res) ->
    # TODO Compile template on loading
    template = null
    fs.readFile path.resolve(__dirname, '../templates/index.jade'), 'utf8', (err, data) =>
      throw err if err
      template = jade.compile(data)

      res.send template(pusher_key: process.env.PUSHER_KEY, deezer_app_id: process.env.DEEZER_APP_ID)

  robot.router.get '/hubot/deezer/channel', (req, res) ->
    res.send '<script src="https://cdns-files.dzcdn.net/js/min/dz.js"></script>'

  robot.router.post '/hubot/deezer/:room/status', (req, res) ->
    room = req.params.room
    data = req.body
    repeat = ['no', 'all', 'one'][data.repeat]
    robot.messageRoom room, "_playing(#{data.playing}) volume(#{data.volume}) shuffle(#{data.shuffle}) repeat(#{repeat})_"
    res.send 'OK'

  robot.router.post '/hubot/deezer/:room/track', (req, res) ->
    track = req.body.track
    message = "'#{track.title} - _#{track.artist?.name}_' is successfully added."
    robot.messageRoom req.params.room, message
    res.send 'OK'

  robot.router.post '/hubot/deezer/:room/message', (req, res) ->
    robot.messageRoom req.params.room, req.body.message
    res.send 'OK'

  robot.router.post '/hubot/deezer/:room/tracks', (req, res) ->
    start = parseInt(req.body.start || 0)
    index = parseInt(req.body.index || 0)
    total_count = parseInt(req.body.total_count)
    tracks = req.body.tracks

    list = req.body.tracks.map (track, i) ->
      "#{i + start}. #{track.title} - _#{track.artist?.name}_"
    list[index - start] = ":notes: #{list[index - start]}"

    prefix = if start > 0 then '...\n' else ''
    postfix = if total_count > start + list.length then '\n...' else ''
    description = if tracks.length == total_count then '' else '\n_Type `deezer list all` to see all songs in playlist_'
    message = "*Current playlist (total #{total_count} songs)*#{description}\n>>>\n#{prefix}#{list.join('\n')}#{postfix}"
    robot.messageRoom req.params.room, message
    res.send 'OK'

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
      deezer search QUERY - Search songs with QUERY.
      deezer search artist:"ARTIST" - Search songs with artist name.
      deezer search track:"TITLE" - Search songs with song title.

      *Play Control*
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
      """

  robot.hear /^(hubot |)deezer (status|next|prev|play|pause|stop|seek|volume|repeat|shuffle|list) *(.*)$/i, (res) ->
    pusher.trigger('hubot-deezer', 'control', {
      room: res.message.room
      action: res.match[2]
      value: res.match[3]
    })

  search = (query, callback) ->
    query = query.replace(/“”/g, '"')
    query = query.replace(/‘’/g, '\'')
    request.get 'https://api.deezer.com/search?q=' + encodeURI(query), (error, response, body) ->
      if error 
        callback(error)
      else if response.statusCode != 200
        callback(new Error("Failed to search '#{query}'. Please try again."))
      else
        callback(undefined, JSON.parse(body).data)

  _searchResult = null
  robot.hear /^(hubot |)deezer search (.*)$/i, (res) ->
    query = res.match[2]
    res.send "Searching \"#{query}\" ..."
    search query, (error, list) ->
      return res.send error.message if error
      return res.send 'No Result.' if list.length == 0

      _searchResult = list
      result = for track, index in list
        "*#{index}*. #{track.title} - _#{track.artist?.name}_"
      res.send "_Type `deezer add NUMBER` to add the song._\n>>>\n#{result.join('\n')}"

  robot.hear /^(hubot |)deezer add ([0-9]+)$/i, (res) ->
    index = parseInt res.match[3]
    if _searchResult && index >= 0 && index < _searchResult.length
      pusher.trigger('hubot-deezer', 'control', {
        room: res.message.room
        action: res.match[2]
        id: _searchResult[index].id
      })
    else
      res.send "Select a number among the search result. (Try `deezer search QUERY`.)"


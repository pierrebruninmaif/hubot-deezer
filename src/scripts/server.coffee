# Description:
#   Server application for Deezer client.
#
# Author:
#   Sungwon Lee <ssowonny@gmail.com>

jade = require('jade')
fs = require('fs')
path = require('path')

files = {}

compile = ->
  fs.readFile path.resolve(__dirname, '../assets/app.js'), 'utf8', (err, data) =>
    throw err if err
    files.app = data

  fs.readFile path.resolve(__dirname, '../templates/index.jade'), 'utf8', (err, data) =>
    throw err if err
    template = jade.compile(data)
    files.html = template(pusher_key: process.env.PUSHER_KEY, deezer_app_id: process.env.DEEZER_APP_ID)

module.exports = (robot) ->
  compile()

  robot.router.get '/hubot-deezer/app.js', (req, res) ->
    res.send files.app

  robot.router.get '/hubot-deezer', (req, res) ->
    res.send files.html

  robot.router.get '/hubot-deezer/channel', (req, res) ->
    res.send '<script src="https://cdns-files.dzcdn.net/js/min/dz.js"></script>'

  robot.router.post '/hubot-deezer/:room/status', (req, res) ->
    room = req.params.room
    data = req.body
    repeat = ['no', 'all', 'one'][data.repeat]
    robot.messageRoom room, "*#{data.track.title}* - _#{data.track.artist?.name}_\n_playing(#{data.playing}) volume(#{data.volume}) shuffle(#{data.shuffle}) repeat(#{repeat})_"
    res.send 'OK'

  robot.router.post '/hubot-deezer/:room/track', (req, res) ->
    track = req.body.track
    message = "'*#{track.title}* - _#{track.artist?.name}_' is successfully added."
    robot.messageRoom req.params.room, message
    res.send 'OK'

  robot.router.post '/hubot-deezer/:room/message', (req, res) ->
    robot.messageRoom req.params.room, req.body.message
    res.send 'OK'

  robot.router.post '/hubot-deezer/:room/tracks', (req, res) ->
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


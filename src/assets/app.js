$(function () {
  // Enable pusher logging - don't include this in production
  Pusher.log = function(message) {
    if (window.console && window.console.log) {
      window.console.log(message)
    }
  }

  var _room = null
  var _track = null
  var _trackOrder = null

  var pusher = new Pusher(PUSHER_KEY, {
    encrypted: true
  })
  var channel = pusher.subscribe('hubot-deezer')
  channel.bind('control', function (data) {
    var action = data.action
    var value = data.value
    _room = data.room

    if (action === 'play' && !!value) {
      action = 'playTracks'
      value = parseInt(value)
      if (value < 0) {
        value = DZ.player.getTrackList().length + parseInt(value)
      }
      var ids = DZ.player.getTrackList().map(function (track) { return track.id })
      return DZ.player.playTracks(ids, value)
    } else if(action === 'status') {
      return postStatus()
    }

    if (action === 'volume') {
      action = 'setVolume'
      if (value === 'up') {
        value = DZ.player.getVolume() + 10
      } else if (value === 'down') {
        value = DZ.player.getVolume() - 10
      }
    } else if (action === 'repeat') {
      action = 'setRepeat'
      switch(value) {
        case 'no': value = 0; break
        case 'all': value = 1; break
        case 'one': value = 2; break
        default: return
      }
    } else if (action === 'shuffle') {
      action = 'setShuffle'
      value = value === 'true'
    }

    var result = DZ.player[action] && DZ.player[action](value)

    // Workaround for endless playing.
    if (action === 'play' && result === false) {
      DZ.player.prev()
      DZ.player.next()
    }
  })

  channel.bind('playlist', function (data) {
    var action = data.action
    _room = data.room

    if (action === 'add') {
      var id = data.id.toString()
      addTrack(id, function (track) {
        if (track) {
          postTrack(track)
        } else {
          postMessage('Sorry, the track cannot be added.')
        }
      })

    } else if (action === 'insert') {
      var id = data.id.toString()
      insertTrack(id, function (track) {
        if (track) {
          postTrack(track)
        } else {
          postMessage('Sorry, the track cannot be inserted.')
        }
      })
    } else if (action === 'list') {
      var size = data.size ? parseInt(data.size) : 6
      postPlaylist(size)
    }
  })

  function addTrack (id, callback) {
    var added = DZ.player.addToQueue([id], function (playlist) {
      var ids = null
      if (_trackOrder) {
        ids = _trackOrder
        ids.push(id)
      } else {
        ids = DZ.player.getTrackList().map(function (track) { return track.id })
      }
      _trackOrder = ids

      var tracks = playlist.tracks.filter(function (track) { return track.id === id })
      var track = tracks && tracks.length > 0 ? tracks[0] : null
      callback(track)
    })

    if (added === false) {
      // Do not send current track to the end.
      if (_track && _track.id === id) {
        return callback(null)
      }

      // If the track is already added then send it to the end.
      var index
      if (_trackOrder && (index = _trackOrder.indexOf(id)) >= 0) {
        var ids = _trackOrder
        ids.splice(index, 1)
        ids.push(id)

        DZ.player.changeTrackOrder(ids)
        _trackOrder = ids

        var tracks = DZ.player.getTrackList().filter(function (track) { return track.id === id })
        var track = tracks && tracks.length > 0 ? tracks[0] : null
        callback(track)
      } else {
        callback(null)
      }
    }
  }

  function insertTrack (id, callback) {
    addTrack(id, function (track) {
      var ids = _trackOrder
      ids.splice(ids.indexOf(id), 1)
      var index = ids.indexOf(_track.id)
      ids.splice(index + 1, 0, id)

      DZ.player.changeTrackOrder(ids)
      _trackOrder = ids

      var tracks = DZ.player.getTrackList().filter(function (track) { return track.id === id })
      var track = tracks && tracks.length > 0 ? tracks[0] : null
      callback(track)
    })
  }

  function postStatus () {
    if (!_room) { return }

    var status = {
      playing: DZ.player.isPlaying(),
      volume: DZ.player.getVolume(),
      shuffle: DZ.player.getShuffle(),
      repeat: DZ.player.getRepeat()
    }

    $.post('/hubot/deezer/' + _room + '/status', status)
  }

  function postTrack (track) {
    if (!_room) { return }

    $.post('/hubot/deezer/' + _room + '/track', { track: track })
  }

  function postPlaylist (size) {
    var tracks = DZ.player.getTrackList().slice()
    if (_trackOrder) {
      tracks.sort(function (a, b) {
        return _trackOrder.indexOf(a.id) - _trackOrder.indexOf(b.id)
      })
    }

    var total_count = tracks.length
    var index = _track && tracks.map(function (t) { return t.id }).indexOf(_track.id)
    var start = 0

    if (size) {
      start = Math.max(0, index - 1)
      tracks.splice(0, start)
      tracks.splice(size)
    }

    $.post('/hubot/deezer/' + _room + '/tracks', {
      tracks: tracks,
      total_count: total_count,
      index: index,
      start: start || 0
    })
  }

  function postMessage (message) {
    if (!_room) { return }

    $.post('/hubot/deezer/' + _room + '/message', {
      message: message
    })
  }

  var _playing = false
  function subscribeEvents () {
    var statusEvents = ['player_play', 'player_paused', 'volume_changed', 'shuffle_changed', 'repeat_changed']
    statusEvents.forEach(function (event) {
      DZ.Event.subscribe(event, function (name) {
        if (name === 'player_play' || name === 'player_paused') {
          var playing = name == 'player_play'
          if (_playing !== playing) {
            _playing = playing
            postStatus()
          }
        } else {
          postStatus()
        }
      })
    })

    DZ.Event.subscribe('current_track', function (trackInfo) {
      _track = trackInfo.track
    })
  }

  DZ.init({
    appId: window.DEEZER_APP_ID,
    channelUrl: '/hubot/deezer/channel',
    player: {
      container: 'player',
      playlist: true,
      onload : function() {
        subscribeEvents()
      }
    }
  })
})

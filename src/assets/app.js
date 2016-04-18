const hubot = {
  statusQueue: [],

  postStatus: function (room) {
    var status = {
      track: DZ.player.getCurrentTrack(),
      playing: DZ.player.isPlaying(),
      volume: DZ.player.getVolume(),
      shuffle: DZ.player.getShuffle(),
      repeat: DZ.player.getRepeat()
    }

    $.post('/hubot-deezer/' + room + '/status', status)
  },

  postMessage: function (room, message) {
    if (!room) { return }

    $.post('/hubot-deezer/' + room + '/message', {
      message: message
    })
  },

  postTracks: function (room, tracks, index) {
    $.post('/hubot-deezer/' + room + '/tracks', {
      tracks: tracks,
      total_count: tracks.length,
      index: index
    })
  },

  postTrack: function (room, track, message) {
    $.post('/hubot-deezer/' + room + '/track', { track: track, message: message })
  },

  enqueueStatusQueue: function (room) {
    if (this.statusQueue.indexOf(room) < 0) {
      this.statusQueue.push(room)
    }
  },

  processStatusQueue: function () {
    this.statusQueue.forEach(function (room) {
      hubot.postStatus(room)
    })

    this.statusQueue = []
  }
}

function Request (room, type) {
  this.room = room
  this.type = type

  this.perform = function (action, value) {
    this[action] && this[action](value)
  }

  this.enqueueStatus = function () {
    hubot.enqueueStatusQueue(this.room)
  }

  this.play = function (index) {
    this.enqueueStatus()

    if (!index) {
      DZ.player.play()
    } else {
      var trackIds = DZ.player.getTrackList().map(function (track) { return track.id })
      DZ.player.playTracks(trackIds, parseInt(index, 10))
    }
  }

  this.pause = this.stop = function () {
    this.enqueueStatus()
    DZ.player.pause()
  }

  this.status = function () {
    hubot.postStatus(this.room)
  }

  this.prev = function () {
    this.enqueueStatus()
    DZ.player.prev()
  }

  this.next = function () {
    this.enqueueStatus()
    DZ.player.next()
  }

  this.seek = function (position) {
    this.enqueueStatus()
    DZ.player.seek(position)
  }

  this.volume = function (volume) {
    this.enqueueStatus()
    if (volume === 'up') {
      volume = DZ.player.getVolume() + 10
    } else if (volume === 'down') {
      volume = DZ.player.getVolume() - 10
    }
    DZ.player.setVolume(volume)
  }

  this.shuffle = function (shuffle) {
    this.enqueueStatus()
    DZ.player.setShuffle(shuffle === 'true')
  }

  this.repeat = function (repeat) {
    this.enqueueStatus()
    var value = 0
    switch (repeat) {
      case 'no': value = 0; break
      case 'all': value = 1; break
      case 'one': value = 2; break
      default: return
    }
    DZ.player.setRepeat(value)
  }

  this.list = function () {
    hubot.postTracks(this.room, DZ.player.getTrackList(), DZ.player.getCurrentIndex())
  }

  this.add = function (id) {
    id = id.toString()
    console.log(id)
    DZ.player.addToQueue([id], function (playlist) {
      var tracks = playlist.tracks.filter(function (track) { return track.id === id })
      var track = tracks && tracks.length > 0 ? tracks[0] : null
      console.log(track)
      if (track) {
        hubot.postTrack(this.room, track, 'is added.')
      }
    }.bind(this))
  }

  this.remove = function (index) {
    index = parseInt(index, 10)
    var tracks = DZ.player.getTrackList()
    var track = tracks[index]
    if (!track) {
      return
    }

    var currentIndex = DZ.player.getCurrentIndex()
    if (index < currentIndex) {
      --currentIndex
    }

    var trackIds = tracks.map(function (track) { return track.id })
    trackIds.splice(index, 1)
    DZ.player.playTracks(trackIds, currentIndex, function (tracks) {
      hubot.postTrack(this.room, track, 'is removed.')
    }.bind(this))
  }
}

$(function () {
  var pusher = new Pusher(PUSHER_KEY, { encrypted: true })
  var channel = pusher.subscribe('hubot-deezer')
  channel.bind('control', function (data) {
    var request = new Request(data.room)
    request.perform(data.action, data.value)
  })

  function subscribeEvents () {
    var statusEvents = ['player_play', 'player_paused', 'volume_changed', 'shuffle_changed', 'repeat_changed']
    statusEvents.forEach(function (event) {
      DZ.Event.subscribe(event, function (name) {
        hubot.processStatusQueue()
      })
    })
  }

  DZ.init({
    appId: window.DEEZER_APP_ID,
    channelUrl: '/hubot-deezer/channel',
    player: {
      container: 'player',
      playlist: true,
      onload : function() {
        subscribeEvents()
      }
    }
  })
})

chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'deezer', ->
  beforeEach ->
    @robot =
      router:
        get: () ->
        post: () ->
        put: () ->
        delete: () ->
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/scripts/deezer')(@robot)

  it 'registers a hear listener', ->
    expect(@robot.hear).to.have.been.calledWith(/^(hubot |)deezer help$/i)

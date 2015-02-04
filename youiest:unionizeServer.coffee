console.log " hi from unionize server "


@getUsername = ->
  'server'

@testReverse = ->
  @v = w.documents.insert
    from: 'present'
    # this should trigger an incomming to future
    to: 'future'
    creator: 'me'
    _idd: 'present-future-me'

  # send something to that which is created by me
  @vv = w.documents.insert
    from: 'USER'
    to: 'youiest'
    creator: 'w'
    _idd: 'USER-youiest-w'
    username: 'future'

  @vvv = w.documents.findOne
    incoming: 'present-future-me'

  console.log 'anyone got incomming?' , vvv


###

User.Meta.collection._ensureIndex
  username: 1

app.getUsername = ->
  username = ""
  unless Meteor.username() return this.userId
###


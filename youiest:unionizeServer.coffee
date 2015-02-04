console.log " hi from unionize server "


@getUsername = ->
  'server'


###

User.Meta.collection._ensureIndex
  username: 1

app.getUsername = ->
  username = ""
  unless Meteor.username() return this.userId
###


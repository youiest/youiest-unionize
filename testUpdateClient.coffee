# emulate a logged in user, this is user, later use real user
@user = 'wiber'
@recFrom = 'picture'

ConsoleMe.enabled = true



Meteor.methods
  "dummyInsert" : (args) ->
    unless args
      args = user
    one = WI.insert
      '_id': args
    two = W.insert 
      '_id': args
    #smite one, two, 'dummyInsert buckle my shoe'
    return one
  "clearDb": () ->
    #smite eval(s), 'clearDb'
    one = W.remove {}
    two = WI.remove {}
    smite one, two, 'clearDb buckle my boots', WI.find({}).count() , eval s
    return WI.findOne({})

@generateRecommend = (i) ->
    to: user+i
    from: recFrom+i


Meteor.startup ->

  if Meteor.isClient

    testing = 0 
    Tinytest.addAsync 'clear - '+testing+' call clearDb server clears db and W goes to 0 items', (test, next) ->

      Meteor.call 'clearDb', (res,err) ->
        one = WI.find({}).count()
        # test async that there are no items in db, returns only one time
        test.equal one, 0
        next()

    testing++
    Tinytest.addAsync 'clear - '+testing+' call clearDb server clears db and WI goes to 0 items', (test, next) ->
      two = WI.find({}).count()
      test.equal two, 0
      next()

    testing++
    Tinytest.add 'insert - '+testing+' dummyInsert creates WI user object synced to client', (test, next) ->
      Meteor.call 'dummyInsert', user, (res, err) ->
        userCreated = WI.findOne
          '_id': user
        smite userCreated, user
        test.equal userCreated._id, user
        next()
    
    testing++
    Tinytest.addAsync 'update - '+testing+' clientside update of WI should hook same inserted into W', (test, next) ->
      rec = generateRecommend testing
      connect rec
      Tracker.autorun (computation) ->
        one = W.findOne
          from: rec.from
          to: rec.to
        smite rec, one, testing, 'testing inserted', eval s
        unless !one
          test.equal one.from, rec.from
          next()

    testing++
    Tinytest.addAsync 'update - '+testing+' client WI.outbox -> server W -> client WI.inbox', (test, next) ->
      rec = generateRecommend testing
      connect rec
      Tracker.autorun (computation) ->
        two = WI.findOne
          _id: rec.to
        smite rec, two, testing, 'testing update outbox to inbox', eval s
        unless !two.inbox
          test.equal two.inbox[0].from, rec.from
          next()

    testing++
    Tinytest.addAsync 'feed - '+testing+' client WI.feed has ten dummy items hooked in after server sees feed field', (test, next) ->
      # when server sees a feed attribute, it fills it called by a hook
      WI.update
        _id: user
      ,
        feed: 'nothing'
      Tracker.autorun (computation) ->
        smite feed = WI.find({_id:'wiber'}).fetch()[0].feed, eval s
        # does third feed item have a journey?
        unless !feed[3].journey
          # the feed function will add feed to the journey of the object
          # has this feed item been created by journey?
          test.equal Object.keys(feed[3].journey[0])[0], 'feed'
          next()
        #smite one, two, 'one two in testing',testing, rec.from, 'rec', err, eval s


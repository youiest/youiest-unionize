# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed

#global variable not in here? what?
at = "eval(t());eval( 'arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)'[0]);"
l eval(at), 'hi from updateClient.coffee'


# test that inserting w.to myUserId triggers a hook that inserts it into my.incoming in WI

# test that updating WI on client fires hook and inserts same object into w on server
    

Meteor.methods
  "dummyInsert" : (insert) ->
    Meteor.call 'clearDb'
    e = W.insert
    _id: 'elias'
    n = W.insert
      _id: 'nicolson'
    p = W.insert
      _id: 'picture'
    WI.insert 
      _id: 'elias'
    WI.insert
      _id: 'nicolson'
    l eval(at), 'dummyInsert done and waitingForIt'
  "clearDb": () ->
    l eval(at), 'clearDb'
    W.remove {}
    WI.remove {}
    

Meteor.call 'clearDb'
Meteor.call 'dummyInsert'


Collection = if typeof Mongo != 'undefined' and typeof Mongo.Collection != 'undefined' then Mongo.Collection else Meteor.Collection


if Meteor.isClient
  consoling = true
  if consoling 
    ConsoleMe.subscribe()
  l eval(at), 'starting clearing calls'

  Meteor.call 'clearDb' , (res,err) ->
      Meteor.call 'dummyInsert'

  @recFrom = 'picture'
  recommendation =
      to: 'elias'
      from: recFrom
  Tinytest.addAsync 'update - clientside update of WI should trigger insert into W', (test, next) ->
    
    connect(recommendation)

    #when client update synced to server, hook inserts w and w is synced to client tracker reruns
    picd = Tracker.autorun (computation) ->
      # since the sync hasn't gone to server and back (hooks!) we test once the data is here
      unless !W.findOne({to:'elias'})
        test.equal recFrom , W.findOne({to:'elias'}).from
        next()
        # computation.stop() # APPEARS not necessary
        return
      return
    return


# test that inserting w.to myUserId triggers a hook that inserts it into my.incoming in WI

# test that updating WI on client fires hook and inserts same object into w on server

# test that grounddb syncs back offline changes

# test that grounddb changes synced back to server trigger hooks

# test that hooks follow rules and only maintain enough data on WI objects to load fresh data

# test that I have a sane WI waiting for me when I log in
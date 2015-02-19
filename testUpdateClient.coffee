

Meteor.methods
  "dummyInsert" : (insert) ->
    Meteor.call 'clearDb', (res,err) ->
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
      #l eval('L()'), 'dummyInsert called clear and done'
  "clearDb": () ->
    l eval('L()'), 'clearDb'
    W.remove {}
    WI.remove {}

ConsoleMe.enabled = true




#if WI.find({inbox:  { $exists : true } }, {_id: 1}).limit(1) #apparently faster by many times
@recFrom = 'picture'
@recommendation =
  to: 'elias'
  from: recFrom





if Meteor.isClient
  l eval('L()'), 'starting'
  Meteor.call 'dummyInsert', (req,res) ->
    l eval('L()'), 'returned'
    Tinytest.addAsync 'update - clientside update of WI should trigger insert into W', (test, next) ->
      l eval('L()'), 'added'
      # update outbox serverside with minimal information.  
      connect(recommendation)
      l eval('L()'), 'connected'
      #when client update synced to server, hook inserts w and w is synced to client tracker reruns
      picd = Tracker.autorun (computation) ->
        #TODO Exception from Tracker recompute function: Error: Can't call Tracker.flush while flushing
        # this doesn't affect the test but looks bad
        l eval('L()'), 'ran tracker'
        # since the sync hasn't gone to server and back (hooks!) we test once the data is here
        unless !W.findOne({to:'elias'})
          l eval('L()'), 'got hit'
          test.equal W.findOne({to:'elias'}).from , recFrom
          next()
          #computation.stop() # APPEARS not necessary

if Meteor.isClient
  l eval('L()'), 'starting number 2'
  Meteor.call 'dummyInsert', (req,res) ->
    l eval('L()'), 'returned from dummyinsert'
    Tinytest.addAsync 'update -  trying again for awake server clientside update of WI should trigger insert into W', (test, next) ->
      l eval('L()'), 'added'
      # update outbox serverside with minimal information.  
      connect(recommendation)
      l eval('L()'), 'connected'
      #when client update synced to server, hook inserts w and w is synced to client tracker reruns
      picd = Tracker.autorun (computation) ->
        #TODO Exception from Tracker recompute function: Error: Can't call Tracker.flush while flushing
        # this doesn't affect the test but looks bad
        l eval('L()'), 'ran tracker'
        # since the sync hasn't gone to server and back (hooks!) we test once the data is here
        unless !W.findOne({to:'elias'})
          l eval('L()'), 'got hit'
          test.equal W.findOne({to:'elias'}).from , recFrom
          next()
          #computation.stop() # APPEARS not necessary


if Meteor.isClient
  l eval('L()'), 'starting number 3'
  Meteor.call 'dummyInsert', (req,res) ->
    l eval('L()'), 'returned from dummyinsert'
    Tinytest.addAsync 'update -  recommend leads to w leads to inbox', (test, next) ->
      l eval('L()'), 'added'
      # update outbox serverside with minimal information.  
      connect(recommendation)
      l eval('L()'), 'connected'
      #when client update synced to server, hook inserts w and w is synced to client tracker reruns
      inbox = Tracker.autorun (computation) ->
        #TODO Exception from Tracker recompute function: Error: Can't call Tracker.flush while flushing
        # this doesn't affect the test but looks bad
        inboxed = WI.findOne({inbox:{ $exists: true}})
        l eval('L()'), 'ran tracker inbox', inboxed
        # since the sync hasn't gone to server and back (hooks!) we test once the data is here
        unless !inboxed
          l eval('L()'), 'got hit'
          test.equal W.findOne({to:'elias'}).from , recFrom
          next()
          #computation.stop() # APPEARS not necessary


###
if Meteor.isClient  
  Tinytest.addAsync 'update - d3 clientside update of WI should update of target users WI if present'+new Date().getTime(), (test, next) ->
    Meteor.call 'dummyInsert' , (res,err) ->
      connect(recommendation)
    sense = Tracker.autorun (computation) ->
      if WI.findOne({to: 'elias'})
        l eval('L()'), 'elias exists?'
        test.equal W.findOne({to:'elias'}).from , recFrom
        next()
        computation.stop()

if Meteor.isClient
  sent = Tracker.autorun (computation) ->
      if inboxed = WI.findOne({inbox:  { $exists : true } })
        l eval('L()'), 'inbox exists?',
    
      if inboxed = WI.findOne({inbox:  { $exists : true } })
        l eval('L()'), 'inbox exists', inboxed
        #Tinytest.addAsync 'update - 2 clientside update of WI should update of target users WI if present', (test, next) ->
        l eval('L()') , W.findOne({to:'elias'}) , WI.findOne({_id:'elias'})
        test.equal W.findOne({to:'elias'}) , WI.findOne({_id:'elias'})
        next()
        computation.stop()  
  Tinytest.addAsync 'update - e2 clientside update of WI should update of target users WI if present'+new Date().getTime(), (test, next) ->
    Meteor.call 'dummyInsert' , (res,err) ->
      sent()
    
    
###
###
if Meteor.isClient

  @recFrom = 'picture'
  recommendation =
      to: 'elias'
      from: recFrom
  l eval('L()'), 'starting'
  Meteor.call 'dummyInsert', (req,res) ->
    l eval('L()'), 'returned'
    Tinytest.addAsync 'update - clientside update of WI should update of target users WI if present', (test, next) ->
      l eval('L()'), 'added'
      # update outbox serverside with minimal information.  
      connect(recommendation)
      l eval('L()'), 'connected'
      #when client update synced to server, hook inserts w and w is synced to client tracker reruns
      picd = Tracker.autorun (computation) ->
        #TODO Exception from Tracker recompute function: Error: Can't call Tracker.flush while flushing
        # this doesn't affect the test but looks bad
        l eval('L()'), 'ran tracker'
        # since the sync hasn't gone to server and back (hooks!) we test once the data is here
        unless !W.findOne({to:'elias'})
          l eval('L()'), 'got hit'
          test.equal W.findOne({to:'elias'}).from , WI.findOne({_id:'elias'}).inbox[0].from
          next()
          computation.stop() # APPEARS not necessary
###
          
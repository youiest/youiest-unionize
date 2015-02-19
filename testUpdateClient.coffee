

Meteor.methods
  "dummyInsert" : (insert) ->
    Meteor.call 'clearDb', (res,req) ->
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


if Meteor.isClient
  @recFrom = 'picture'
  recommendation =
      to: 'elias'
      from: recFrom
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
          computation.stop() # APPEARS not necessary
          
@at = "eval(t());eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)'[0]);"
#l eval('Li()'), 'hi from testUpdateClient.coffee'
@LineNFile = do ->
  getErrorObject = ->
    try
      throw Error('')
    catch err
      return err
    return

  err = getErrorObject()
  
  caller_line = err.stack.split('\n')[4]
  index = caller_line.indexOf('at ')
  clean = caller_line.slice(index + 2, caller_line.length)
  return clean

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
      #l eval('Li()'), 'dummyInsert called clear and done'
  "clearDb": () ->
    l eval('Li()'), 'clearDb'
    W.remove {}
    WI.remove {}

ConsoleMe.enabled = true


if Meteor.isClient
  @recFrom = 'picture'
  recommendation =
      to: 'elias'
      from: recFrom
  l eval('Li()'), 'starting'
  Meteor.call 'dummyInsert', (req,res) ->
    l eval('Li()'), 'returned'
    Tinytest.addAsync 'update - clientside update of WI should trigger insert into W', (test, next) ->
      l eval('Li()'), 'added'
      # update outbox serverside with minimal information.  
      connect(recommendation)
      l eval('Li()'), 'connected'
      #when client update synced to server, hook inserts w and w is synced to client tracker reruns
      picd = Tracker.autorun (computation) ->
        l eval('Li()'), 'ran tracker'
        # since the sync hasn't gone to server and back (hooks!) we test once the data is here
        unless !W.findOne({to:'elias'})
          l eval('Li()'), 'got hit'
          test.equal W.findOne({to:'elias'}).from , recFrom
          next()
          #computation.stop() # APPEARS not necessary
          
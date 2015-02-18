@at = "eval(t());eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)'[0]);"
l eval(at), 'hi from testUpdateClient.coffee'


if Meteor.isClient
  Meteor.call 'dummyInsert'
  @recFrom = 'picture'
  recommendation =
      to: 'elias'
      from: recFrom
  Tinytest.addAsync 'update - clientside update of WI should trigger insert into W', (test, next) ->
    # update outbox serverside with minimal information.  
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

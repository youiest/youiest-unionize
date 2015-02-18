# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed
#

# test that findOne (natural:-1) finds latest version insert and learn how responsive it is
a = do -> eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)')[0]
l eval(at),  'hi from tests2', a

# test that hook writes to .inbox of .to in WI
@at = "eval(t());eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)'[0]);"
l eval(at), 'hi from testUpdateClient.coffee'


if Meteor.isClient
  Meteor.call 'dummyInsert'

  @recFrom = 'picture'
  recommendation =
      to: 'elias'
      from: recFrom
  Tinytest.addAsync 'update - from client outbox to client inbox', (test, next) ->
    # update outbox serverside with minimal information.  
    connect(recommendation)
    #when client update synced to server, hook inserts w and w is synced to client tracker reruns
    inbox = Tracker.autorun (computation) ->
      # since the sync hasn't gone to server and back (hooks!) we test once the data is here
      unless !W.findOne({to:'elias'})
        test.equal recFrom , W.findOne({to:'elias'}).from
        next()
        # computation.stop() # APPEARS not necessary
        return
      return
    return



# test that grounddb syncs back offline changes

# test that grounddb changes synced back to server trigger hooks

# test that hooks follow rules and only maintain enough data on WI objects to load fresh data

# test that I have a sane WI waiting for me when I log in
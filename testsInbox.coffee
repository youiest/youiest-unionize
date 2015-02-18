# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed
#

# test that findOne (natural:-1) finds latest version insert and learn how responsive it is
a = do -> eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)')[0]
l eval(at),  'hi from tests2'

# test that hook writes to .inbox of .to in WI
if Meteor.isServer
  l eval(at), 'next test run client'
  if consoling 
    ConsoleMe.enabled = true

  Tinytest.addAsync 'update - calling connect on client to update WI, then check that hook inserted into w', (test, next) ->
    tmp = {}

    
    return
collection22 = new Collection('test_insert_collection22')
if Meteor.isServer
  l eval(at), 'next test run server'



# test that grounddb syncs back offline changes

# test that grounddb changes synced back to server trigger hooks

# test that hooks follow rules and only maintain enough data on WI objects to load fresh data

# test that I have a sane WI waiting for me when I log in
# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed
#

# test that findOne (natural:-1) finds latest version insert and learn how responsive it is
a = do -> eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)')[0]
l eval(at),  'hi from tests2'

# test that hook writes to .inbox of .to in WI
if Meteor.isServer
  if consoling 
    ConsoleMe.enabled = true
  collection12 = new Collection('test_insert_collection12')
  Tinytest.addAsync 'update - calling connect on client to update WI, then check that hook inserted into w', (test, next) ->
    tmp = {}
    collection12.remove {}
    collection12.before.insert (userId, doc) ->
      # There should be no userId because the insert was initiated
      # on the server -- there's no correlation to any specific user
      tmp.userId = userId
      # HACK: can't test here directly otherwise refreshing test stops execution here
      doc.before_insert_value = true
      return
    collection12.insert { start_value: true }, ->
      test.equal collection12.find(
        start_value: true
        before_insert_value: true).count(), 1
      test.equal tmp.userId, undefined
      next()
      return
    return
collection22 = new Collection('test_insert_collection22')
if Meteor.isServer
  # full client-side access
  collection22.allow
    insert: ->
      true
    update: ->
      true
    remove: ->
      true
  Meteor.methods test_insert_reset_collection22: ->
    collection22.remove {}
    return
  Meteor.publish 'test_insert_publish_collection22', ->
    collection22.find()
  collection22.before.insert (userId, doc) ->
    #l("test_insert_collection22 BEFORE INSERT", userId, doc);
    doc.server_value = true
    return





# test that grounddb syncs back offline changes

# test that grounddb changes synced back to server trigger hooks

# test that hooks follow rules and only maintain enough data on WI objects to load fresh data

# test that I have a sane WI waiting for me when I log in
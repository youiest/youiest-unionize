# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed
#

# test that findOne (natural:-1) finds latest version insert and learn how responsive it is

l 'hi from tests'

#test that updating WI on client fires before update hook on server



# test that inserting w.to myUserId triggers a hook that inserts it into my.incoming in WI



Collection = if typeof Mongo != 'undefined' and typeof Mongo.Collection != 'undefined' then Mongo.Collection else Meteor.Collection
if Meteor.isServer
  collection1 = new Collection('test_insert_collection1')
  Tinytest.addAsync 'insert - collection1 document should have extra property added to it before it is inserted', (test, next) ->
    tmp = {}
    collection1.remove {}
    collection1.before.insert (userId, doc) ->
      # There should be no userId because the insert was initiated
      # on the server -- there's no correlation to any specific user
      tmp.userId = userId
      # HACK: can't test here directly otherwise refreshing test stops execution here
      doc.before_insert_value = true
      return
    collection1.insert { start_value: true }, ->
      test.equal collection1.find(
        start_value: true
        before_insert_value: true).count(), 1
      test.equal tmp.userId, undefined
      next()
      return
    return
collection2 = new Collection('test_insert_collection2')
if Meteor.isServer
  # full client-side access
  collection2.allow
    insert: ->
      true
    update: ->
      true
    remove: ->
      true
  Meteor.methods test_insert_reset_collection2: ->
    collection2.remove {}
    return
  Meteor.publish 'test_insert_publish_collection2', ->
    collection2.find()
  collection2.before.insert (userId, doc) ->
    #l("test_insert_collection2 BEFORE INSERT", userId, doc);
    doc.server_value = true
    return
if Meteor.isClient
  l 'calling dummyInsert'#, arguments.callee
  Meteor.call('dummyInsert')
  # connect isn't in this scope, why?
  #l 'trying after dummy startup waited'
  #setTimeout connect('picture','elias') , 500
  #setTimeout  l('waited'), 500 # so it's available # so db syncs
  l 'done'
  Meteor.subscribe 'test_insert_publish_collection2'
  Tinytest.addAsync 'insert - collection2 document on client should have client-added and server-added extra properties added to it before it is inserted', (test, next) ->
    collection2.before.insert (userId, doc) ->
      #l("test_insert_collection2 BEFORE INSERT", userId, doc);
      test.notEqual userId, undefined, 'the userId should be present since we are on the client'
      test.equal collection2.find(start_value: true).count(), 0, 'collection2 should not have the test document in it'
      doc.client_value = true
      return
    collection2.after.insert (userId, doc) ->
      #l("test_insert_collection2 AFTER INSERT", userId, doc);
      test.notEqual @_id, undefined, 'the _id should be available on this'
      return
    Meteor.startup ->
      Meteor.call 'test_insert_reset_collection2', (err, result) ->
        #l("test_insert_collection2 INSERT");
        collection2.insert { start_value: true }, ->
          test.equal collection2.find(
            start_value: true
            client_value: true
            server_value: true).count(), 1, 'collection2 should have the test document with client_value AND server_value in it'
          next()
          return
        return
      return
    return





# test that grounddb syncs back offline changes

# test that grounddb changes synced back to server trigger hooks

# test that hooks follow rules and only maintain enough data on WI objects to load fresh data

# test that I have a sane WI waiting for me when I log in
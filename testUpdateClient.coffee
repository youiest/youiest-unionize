# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed

#global variable not in here? what?
at = "eval(t());eval( 'arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)'[0]);"
l eval(at), 'hi from updateClient.coffee'
#test that updating WI on client fires before update hook on server

Meteor.methods
  "dummyInsert" : (insert) ->
    l eval(at), 'dummyInsert'
    W.remove({});
    WI.remove({});
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



# test that inserting w.to myUserId triggers a hook that inserts it into my.incoming in WI

# test that updating WI on client fires hook and inserts same object into w on server

Collection = if typeof Mongo != 'undefined' and typeof Mongo.Collection != 'undefined' then Mongo.Collection else Meteor.Collection


if Meteor.isClient
  if consoling 
    ConsoleMe.subscribe()
  l  eval(at), 'calling dummyInsert'
  Meteor.call('dummyInsert')

  Meteor.subscribe 'test_insert_publish_collection22'
  Tinytest.addAsync 'update - updating client WI should work', (test, next) ->
    collection22.before.insert (userId, doc) ->
      test.notEqual userId, undefined, 'the userId should be present since we are on the client'
      test.equal collection22.find(start_value: true).count(), 0, 'collection22 should not have the test document in it'
      doc.client_value = true
      return
    collection22.after.insert (userId, doc) ->
      test.notEqual @_id, undefined, 'the _id should be available on this'
      return
    Meteor.startup ->
      l eval(at),  'startup dummyInsert'
      Meteor.call 'dummyInsert'
      recommendation =
        to: 'elias'
        from: 'picture'
      recommendation2 =
        to: 'elias'
        from: 'picture2'
      l eval(at)
      , recommendation, recommendation.from 
      ,'testing recommendation'
      , connect(recommendation) 
      
      l eval(at), recommendation2, recommendation2.from 
      , 'testing recommendation2', connect(recommendation2) 
      
      l eval(at), recommendation.from, WI.findOne({}).outbox , 'outbox'
      @checks = (c)->
        console.log c
        l eval(at)
        , c
        , 'running checks'
        , W.findOne {}
        , W.findOne({'from':'picture'})
        alert 'about to check'
        r = W.findOne
          to: recommendation.to
          from: recommendation.from
        r2 = W.findOne
          to: recommendation2.to
          from: recommendation2.from
        unless r.from
          setTimeout checks(), 1000
          return
        l eval(at),  'testing for rec n r' , recommendation.from, r, r2, W.findOne({'from':'picture'})
        
        test.equal recommendation.from, WI.findOne {"from":from}


      check()
      Meteor.call  'test_insert_reset_collection22', (err, result) ->
        #l("test_insert_collection22 INSERT");
        collection22.insert { start_value: true }, ->
          test.equal collection22.find(
            start_value: true
            client_value: true
            server_value: true).count(), 1, 'collection22 should have the test document with client_value AND server_value in it'
          next()
          return
        return
      return
    return


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
# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed

# test that findOne (natural:-1) finds latest version insert and learn how responsive it is

# test that inserting w.to myUserId triggers a hook that inserts it into my.incoming in WI

# test that updating WI on client fires hook and inserts same object into w on server

# test that grounddb syncs back offline changes

# test that grounddb changes synced back to server trigger hooks

# test that hooks follow rules and only maintain enough data on WI objects to load fresh data

# test that I have a sane WI waiting for me when I log in

# test that inserting w.to myUserId triggers a hook that inserts it into my.incoming in WI

# test that updating WI on client fires hook and inserts same object into w on server
    



l eval(at),  'hi from tests orig'
Collection = if typeof Mongo != 'undefined' and typeof Mongo.Collection != 'undefined' then Mongo.Collection else Meteor.Collection

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


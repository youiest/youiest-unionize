# emulate a logged in user, this is user
@user = 'wiber'

@clearClientGroundDbs = ->
  WI.remove
    _id: user
  WI.remove
    _id: 'nicolson'
  WI.remove
    _id: 'elias'
  -> WI.find({}).count()

@flushGroundlings = ->
  pre = WI.find({}).count()
  cl = clearClientGroundDbs()
  smite 'did we flush the groundlings out?', pre, cl(), 'if 0 yes', eval s
  -> cl

ConsoleMe.enabled = true

@recFrom = 'picture'
@recNum = 0

@recommendation =
  to: user
  from: recFrom
@recommendationArray = []
for i in '0123456789'
  r =
    to: user+i
    from: recFrom+i
  @recommendationArray.push r
  smite recommendationArray[i], 'counting to recommendations',recommendationArray
  

Meteor.methods
  "dummyInsert" : (insert) ->
    
    #always clear db before inserting
    Meteor.call 'clearDb', (res,err) ->
      e = WI.insert
        _id: 'wiber0'
      e = WI.insert
        _id: 'wiber1'
      e = WI.insert
        _id: 'wiber2'
      e = WI.insert
        _id: 'wiber3'
      e = WI.insert
        _id: 'wiber4'
      e = WI.insert
        _id: 'wiber5'
      e = WI.insert
        _id: 'wiber6'
      e = WI.insert
        _id: 'wiber7'
      e = WI.insert
        _id: 'wiber8'
      e = WI.insert
        _id: 'wiber9'
      e = WI.insert
        _id: 'wiber10'
      n = WI.insert
        _id: 'nicolson'
      p = W.insert
        _id: 'picture'
      WI.insert 
        _id: 'wiber'
      WI.insert 
        _id: 'elias'
      WI.insert
        _id: 'nicolson'
      #attempt to clear client ground db
      return WI.find
      .count()
  "clearDb": () ->
    smite eval(s), 'clearDb'
    W.remove {}
    WI.remove {}


flushGroundlings()
Meteor.call 'dummyInsert', (res,err) ->
  smite res, err, 'returned from dummyinsert', eval s

Meteor.startup ->

  if Meteor.isClient

    Tinytest.addAsync 'update - 1 clientside update of WI should trigger insert into W', (test, next) ->

      recNum = 0
      smite 'connecting after test add', recNum
      , recommendationArray[recNum].to
      , recommendationArray[recNum].from
      , eval s
      c = connect(recommendationArray[recNum])
      smite c , 'returned from connect', eval s

      picd = Tracker.autorun (computation) ->
        recNum = 0
        smite recNum, 'ran tracker one', recommendationArray[recNum], eval s
        smite W.findOne({to:recommendationArray[recNum].to}) , recommendationArray[recNum].to, 'ran tracker one', eval s
        unless !W.findOne({to:recommendationArray[recNum].to})
          smite eval(s), 'got hit tracker one'
          test.equal recommendationArray[recNum].from, W.findOne({to:recommendationArray[recNum].to}).from
          next()

    Tinytest.addAsync 'update - 2 clientside update of WI should trigger insert into W', (test, next) ->

      recNum = 2
      c = connect(recommendationArray[recNum])
      smite c , 'returned from connect in 2', eval s
      picd = Tracker.autorun (computation) ->
        smite eval(s), 'ran tracker one'
        recNum = 2
        unless !W.findOne({to:recommendationArray[recNum].to})
          smite eval(s), 'got hit'
          db = W.findOne({to:recommendationArray[recNum].to}).from
          input = recommendationArray[recNum].from
          test.equal  input, db 
          next()
    # this test requires update on client, two update triggered on server and sync data back to client
    Tinytest.addAsync 'update - 3 client WI.outbox -> server W -> client WI.inbox', (test, next) ->

      recNum = 3
      c = connect(recommendationArray[recNum])
      smite c , 'returned from connect in tracker 3', recommendationArray[recNum].to, eval s
      picd = Tracker.autorun (computation) ->
        recNum = 3
        smite 'ran tracker three' , WI.findOne({inbox:{ $exists: true }}) , recommendationArray[recNum].from, eval s
        # don't test untill data arrives from server inbox
        unless !WI.findOne({_id: recommendationArray[recNum].to}).inbox
          smite eval(s), 'got hit 3'
          test.equal WI.findOne(_id: recommendationArray[recNum].to).inbox[0].from , recommendationArray[recNum].from
          this.stop()
          next()
    #TODO keep a feed fresh so WI.findOne get's enough to start an app
    Tinytest.addAsync 'update - 4 client WI.outbox -> W -> WI.inbox', (test, next) ->
      
      recNum = 4
      c = connect(recommendationArray[recNum])
      smite c , 'returned from connect in tracker 3', recommendationArray[recNum].to, eval s
      picd = Tracker.autorun (computation) ->
        recNum = 4
        smite 'ran tracker three' , WI.findOne({inbox:{ $exists: true }}) , recommendationArray[recNum].from, eval s
        # don't test untill data arrives from server inbox
        unless !WI.findOne({_id: recommendationArray[recNum].to}).inbox
          smite eval(s), 'got hit 3'
          test.equal WI.findOne(_id: recommendationArray[recNum].to).inbox[0].from , recommendationArray[recNum].from
          this.stop()
          next()
    
    #TODO test that groundb syncs back to server correctly even if new items exist server - conflicts?
    Tinytest.addAsync 'update - 5 client WI.outbox -> W -> WI.inbox', (test, next) ->
      
      recNum = 5
      c = connect(recommendationArray[recNum])
      smite c , 'returned from connect in tracker 3', recommendationArray[recNum].to, eval s
      picd = Tracker.autorun (computation) ->
        recNum = 5
        smite 'ran tracker three' , WI.findOne({inbox:{ $exists: true }}) , recommendationArray[recNum].from, eval s
        # don't test untill data arrives from server inbox
        unless !WI.findOne({_id: recommendationArray[recNum].to}).inbox
          smite eval(s), 'got hit 3'
          test.equal WI.findOne(_id: recommendationArray[recNum].to).inbox[0].from , recommendationArray[recNum].from
          this.stop()
          next()

    #TODO moved from sending to sent when done, or have another collection with unfinished jobs from inserts if necessary
    Tinytest.addAsync 'update - 6 client WI.outbox -> W -> WI.inbox', (test, next) ->
      
      recNum = 6
      c = connect(recommendationArray[recNum])
      smite c , 'returned from connect in tracker 3', recommendationArray[recNum].to, eval s
      picd = Tracker.autorun (computation) ->
        recNum = 6
        smite 'ran tracker three' , WI.findOne({inbox:{ $exists: true }}) , recommendationArray[recNum].from, eval s
        # don't test untill data arrives from server inbox
        unless !WI.findOne({_id: recommendationArray[recNum].to}).inbox
          smite eval(s), 'got hit 3'
          test.equal WI.findOne(_id: recommendationArray[recNum].to).inbox[0].from , recommendationArray[recNum].from
          this.stop()
          next()

    #TODO test Logged in security of WI
    Tinytest.addAsync 'update - 7 client WI.outbox -> W -> WI.inbox', (test, next) ->
      recNum = 7
      c = connect(recommendationArray[recNum])
      smite c , 'returned from connect in tracker 3', recommendationArray[recNum].to, eval s
      picd = Tracker.autorun (computation) ->
        recNum = 7
        smite 'ran tracker three' , WI.findOne({inbox:{ $exists: true }}) , recommendationArray[recNum].from, eval s
        # don't test untill data arrives from server inbox
        unless !WI.findOne({_id: recommendationArray[recNum].to}).inbox
          smite eval(s), 'got hit 3'
          test.equal WI.findOne(_id: recommendationArray[recNum].to).inbox[0].from , recommendationArray[recNum].from
          this.stop()
          next()

# TODO


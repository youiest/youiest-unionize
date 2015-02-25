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
for i in '012345'
  r =
    to: user+i
    from: recFrom+i
  @recommendationArray.push r
  smite recommendationArray[i], 'counting to recommendations',recommendationArray
  

Meteor.methods
  "dummyInsert" : (insert) ->
    
    #W.insert insert
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
      return clearClientGroundDbs
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
      smite 'connected afer test callback', recNum
      , recommendationArray[recNum].to
      , recommendationArray[recNum].from
      , eval s
      c = connect(recommendationArray[recNum])
      smite c , 'returned from connect', eval s
      picd = Tracker.autorun (computation) ->
        smite eval(s), 'ran tracker one'
        recNum = 0
        unless !W.findOne({to:recommendationArray[recNum].to})
          smite eval(s), 'got hit'
          test.equal W.findOne({to:recommendationArray[recNum].to}).from , recommendationArray[recNum].from
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
    Tinytest.addAsync 'update - 3 client WI.outbox -> W -> WI.inbox', (test, next) ->
      recNum = 3
      c = connect(recommendationArray[recNum])
      smite c , 'returned from connect', eval s
      picd = Tracker.autorun (computation) ->
        recNum = 3

        inboxed = WI.findOne({inbox:{ $exists: true}})
        smite 'ran tracker three', !inboxed , eval s
        unless !inboxed
          smite eval(s), 'got hit 3'
          test.equal WI.findOne({inbox:{ $exists: true }}).inbox[0].from , recommendationArray[recNum].from
          this.stop()
          next()
    


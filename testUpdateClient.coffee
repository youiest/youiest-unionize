# emulate a logged in user, this is user
@user = 'wiber'
if Meteor.isServer
  WI.remove({})
  W.remove({})

@clearClientGroundDbs = ()->
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
testingRecommendGen = (i) ->
  r =
    to: user+i
    from: recFrom+i
  return r
for i in '0123456789abcdefghiklmnopqrstuvxyz'
  r = testingRecommendGen (i)
    #to: user+i
    #from: recFrom+i
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
      return WI.find.count()
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
      smite WI.find({}).count(), 'items in WI before', eval s
      Meteor.call 'dummyInsert', (res,err) ->
        smite res, err, 'returned from dummyinsert', eval s
        smite WI.find({}).count(), 'items in WI after', eval s
        recNum = 0
        smite 'connecting after test add', recNum
        , recommendationArray[recNum].to
        , recommendationArray[recNum].from
        , eval s
        c = connect(recommendationArray[recNum])
        smite c , 'returned from connect', eval s

        picd = Tracker.autorun (computation) ->
          recNum = 0
          smite recNum, 'ran tracker one', recommendationArray[recNum],W.findOne({to:recommendationArray[recNum].to}), eval s
          #smite W.findOne({to:recommendationArray[recNum].to}) , recommendationArray[recNum].to, 'ran tracker one, was there date', eval s
          unless !recommendationArray[recNum]
            one = recommendationArray[recNum].from
          unless !W.findOne({to:recommendationArray[recNum].to})
            two = W.findOne({to:recommendationArray[recNum].to}).from
          #smite one, two, eval s
          # search the console for 107 and instantly find this as the line number is here..
          eval smiter
          unless !two
            smite 'got hit tracker one', eval s
            test.equal one, two
            next()

    Tinytest.addAsync 'update - 2 clientside update of WI should trigger insert into W', (test, next) ->
      smite WI.find({}).count(), 'items in WI before', eval s
      Meteor.call 'dummyInsert', (res,err) ->
        smite res, err, 'returned from dummyinsert', eval s
        smite WI.find({}).count(), 'items in WI after', eval s
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
    Tinytest.addAsync 'update - 3 client WI.outbox -> server W -> client WI.inbox same', (test, next) ->
      flushGroundlings()
      Meteor.call 'dummyInsert', (res,err) ->
        smite res, err, 'returned from dummyinsert', eval
        recNum = 3
        c = connect(recommendationArray[recNum])
        smite c , 'returned from connect in tracker 3', recommendationArray[recNum].to, eval s
        
        picd = Tracker.autorun (computation) ->
          recNum = 3
          unless !recommendationArray[recNum].from
            one = recommendationArray[recNum].from
          unless !WI.findOne({_id: recommendationArray[recNum].to}).inbox
            two = WI.findOne({_id: recommendationArray[recNum].to}).inbox[0].from
          smite 'ran tracker three' #, WI.findOne({inbox:{ $exists: true }}) , recommendationArray[recNum].from, eval s
          # don't test untill data arrives from server inbox
          unless !two
            smite eval(s), 'got hit 3'
            test.equal one, two
            this.stop()
            next()


    # feed function adds a w to the feed cache, queries process best fits
    # for in loop generates feed items from specific function that generates styled react..
    # react pieces need to be a separate package?
    #TODO keep a feed fresh so WI.findOne get's enough to start an app, uses feed function? seeks to maintain a varying number of items
    # array with max 50 items, feed, 

   
    Tinytest.addAsync 'reactjs - dom element equals to data', (test, next) ->
      smite WI.find({}).count(), 'items in WI before', eval s
      Meteor.call 'dummyInsert', (res,err) ->
        smite res, err, 'returned from dummyinsert', eval s
        smite WI.find({}).count(), 'items in WI after', eval s
        @feedItems = React.createClass
          "getInitialState": ()->
            {feeds: WI.findOne 
              "_id": myWI}
          "componentDidMount": ()->
            self = @
            Tracker.autorun ()->
              feed = WI.findOne({"_id": myWI})   
              self.setState({"feeds": feed})
          "render": ()->
            # console.error(this.state.feeds)
            feedsList = []
            if(this.state.feeds and this.state.feeds.sending)
              sending = this.state.feeds.sending
              # console.error(sending)
              # for feed in sending
              #   # console.error(feed)
              #   if(feed.from) ==   
              feedsList = sending.map (feed)->
                  React.DOM.div(null)
              # console.error(this.state.feeds.sending.length,feedsList.length)
              # React.unmountComponentAtNode(document.getElementById('container'));
              test.equal(this.state.feeds.sending.length,feedsList.length)
              next()
            return React.DOM.div(null,feedsList)
        React.renderComponentToString(@feedItems(null))
    # TODO 
    # Unionize as discussed
    Tinytest.addAsync "reactjs - check the last data entered is in the dom for another1", (test, next) ->
      smite WI.find({}).count(), 'items in WI before', eval s
      Meteor.call 'dummyInsert', (res,err) ->
        smite res, err, 'returned from dummyinsert', eval s
        smite WI.find({}).count(), 'items in WI after', eval s
        #testingRecommend = { from: 'another1', to: 'wiber6' }
        #connect(testingRecommend)
        recNum = 9
        testingRecommend = connect(recommendationArray[recNum])
        smite testingRecommend , 'returned from connect in tracker 3', recommendationArray[recNum].to, eval s
        
        picd = Tracker.autorun (computation) ->
          recNum = 9
          unless !recommendationArray[recNum].from
            one = recommendationArray[recNum].from
          unless !WI.findOne({_id: recommendationArray[recNum].to}).inbox
            two = WI.findOne({_id: recommendationArray[recNum].to}).inbox[0].from
          smite 'ran tracker three' #, WI.findOne({inbox:{ $exists: true }}) , recommendationArray[recNum].from, eval s
          # don't test untill data arrives from server inbox
          unless !two
            smite 'no two', eval s, eval "smiter('tracker 9 ran with recommendation')"
          smite eval(s), 'got hit 9'
          @secondReact = React.createClass
            "getInitialState": ()->
              {feeds: WI.findOne 
                "_id": myWI}
            "componentDidMount": ()->
              self = @
              Tracker.autorun ()->
                feed = WI.findOne({"_id": myWI})   
                self.setState({"feeds": feed})
            "render": ()->
              # console.error(this.state.feeds)
              feedsList = []
              if(this.state.feeds and this.state.feeds.outbox)
                outbox = this.state.feeds.outbox
                # console.error(outbox)
                for feed in outbox
                  console.error(feed)
                  if(feed.from ==  'another1')
                    test.equal(true,true)
                    next()
                feedsList = outbox.map (feed)->
                    React.DOM.div(null)
                # console.error(this.state.feeds.outbox.length,feedsList.length)
                test.equal(this.state.feeds.outbox.length,feedsList.length)
                
              return React.DOM.div(null,feedsList)
          React.renderComponentToString(@secondReact(null))

    #TODO
    #move from inbox to seeing
    Tinytest.addAsync "move - Move the data from inbox to seeing", (test, next) ->
      #testingRecommend = testingRecommendGen(10)
      n = 20
      for i in [10..n] by 1
        connect(testingRecommendGen(i))
      count = 10
      connected = while (count += 1) <= 20
        connect(testingRecommendGen(i))

   youiest:unionize connects reactively. 

curl https://install.meteor.com/ | sh

cd path/to/yourpackage

meteor test-packages ./

Go to http://localhost:3000/ in private mode since junk can stick around in mem and throw off test times


Unionize
========

Unionize - Extra Stupid DB

Moves bricks around. When it gets around to it.

Meteor smart package which provides a reactive database layer for connecting people and things, moving bits around and compensating for for the DB latency. Render connections with react.

Uninize makes it dead simple to move data between clients and server. Clients have full control over their outboxes. Outboxes are arrays of actions honored by the server if they pass muster. The server then syncs the data accordingly. 


Implemented features are:
 * connect( from, to ) -> connect points by updating your .outbox on client
 * collection hooks on server process .outbox array and perform inserts into W collection and updates .to targets
 * reactive tests run after collection-hooks process .outbox and sync W back to client

Planned features are:

 * Each user has a 'prejoined' document on the server with enough data to load an app without queries
 * Offline use through groundDB
 * Hooks that fire when data is synced to server which maintain prejoined document.
 * extensible reactjs functions for rendering different kinds of objects on client or server
 * extensible 'rules' functions for how to move 'bricks' around. Fired depending on what action user puts into an outbox. Essentially a dead simple dynamic Meteor.call called with the type of action and the document.
 * Thresholds, federation, bots and more.

Adding this package to your [Meteor](http://www.meteor.com/) application adds the W and WI collections object as well as the connect(from,to) function on the client.

example from testUpdateClient.coffee
------------------------------------
(on client)
Meteor.startup ->
      # performance obsessed logging
      l a(),  'startup dummyInsert'

      Meteor.call 'dummyInsert'
      recommendation =
        to: user
        from: 'picture'
      recommendation2 =
        to: user
        from: 'picture2'
      l a()
      , recommendation, recommendation.from 
      ,'testing recommendation'

      # calling connect on the client to do update our WI, later synced when online
      , connect(recommendation) 
      
      l a(), recommendation2, recommendation2.from 
      , 'testing recommendation2', connect(recommendation2) 
      l a(), recommendation.from, WI.findOne({}).outbox , 'outbox'

      # since the sync hasn't gone to server and back (hooks!) we test once the data is here
      picd = Tracker.autorun (computation) ->
        l a(), 'checking if ready for test pictured' , W.findOne({to:user})
        # only run the test if we have a candidate
        unless !W.findOne({to:user})
          test.equal recommendation.from , W.findOne {to:user}.from
        next()



Installation
------------

```
meteor add youiest:unionize
```

   youiest:unionize connects reactively. 


How to use a private package:

https://medium.com/@davidjwoody/how-to-write-a-package-for-meteor-js-e5534c6bd3c2

mrt link-package path/to/yourpackage

meteor test-packages ./


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

      # calling connect on the client to do update our WI, later synced when online
      , connect(recommendation) 
      
      l eval(at), recommendation2, recommendation2.from 
      , 'testing recommendation2', connect(recommendation2) 
      l eval(at), recommendation.from, WI.findOne({}).outbox , 'outbox'

      # since the sync hasn't gone to server and back (hooks!) we test once the data is here
      picd = Tracker.autorun (computation) ->
        l eval(at), 'checking if ready for test pictured' , W.findOne({to:'elias'})
        # only run the test if we have a candidate
        unless !W.findOne({to:'elias'})
          test.equal recommendation.from , W.findOne {to:'elias'}.from
        next()



Installation
------------

```
meteor add youiest:unionize
```

   youiest:unionize connects reactively. 


How to use a private package:

https://medium.com/@davidjwoody/how-to-write-a-package-for-meteor-js-e5534c6bd3c2

mrt link-package path/to/yourpackage

meteor test-packages ./


Unionize
========

Meteor smart package which provides a reactive database layer for connecting people and things, latency compensate for the DB and render connections with react.


Implemented features are:
* sudo code for latency compensation

Planned features are:
 * Meteor.methods 'connect' -> connect things on the client
 * Each user has a prejoined document on the server with enough data to load an app without queries
 * Offline use through groundDB
 * Hooks that fire when data is synced to server which maintain prejoined document.
 * OO react functions for rendering different kinds of objects in browser

Adding this package to your [Meteor](http://www.meteor.com/) application adds the `W` object into the global scope.

Both client and server side.

Installation
------------

```
meteor add youiest:unionize
```

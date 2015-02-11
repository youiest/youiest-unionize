   youiest:unionize is a reactive connection. 

meteor test-packages ./

How to use a private package:

https://medium.com/@davidjwoody/how-to-write-a-package-for-meteor-js-e5534c6bd3c2

mrt link-package path/to/yourpackage


PeerDB
======

Meteor smart package which provides a reactive database layer with references, generators, triggers, migrations, etc.
Meteor provides a great way to code in a reactive style and this package brings reactivity to your database as well.
You can now define inside your application along with the rest of your program logic also how your data should be updated
on any change and how various aspects of your data should be kept in sync and consistent no matter where the change comes
from.

Implemented features are:
 * reactive references between Ws
 * reactive reverse references between Ws
 * reactive auto-generated fields from other fields
 * reactive triggers
 * [migrations](https://github.com/peerlibrary/meteor-peerdb-migrations)

Planned features are:
 * versioning of all changes to Ws
 * integration with [full-text search](http://www.elasticsearch.org/)
 * [strict-typed schema validation](https://github.com/balderdashy/anchor)

Adding this package to your [Meteor](http://www.meteor.com/) application adds the `W` object into the global scope.

Both client and server side.

Installation
------------

```
meteor add peerlibrary:peerdb
```

Additional packages
-------------------

* [peerlibrary:peerdb-migrations](https://github.com/peerlibrary/meteor-peerdb-migrations) – Migrations support for PeerDB Ws

Ws
---------

Instead of Meteor collections with PeerDB you are defining PeerDB Ws by extending `W`. Internally it
defines a Meteor collection, but also all returned Ws are then an instance of that PeerDB Ws class.

Minimal definition:

```coffee
class wApp extends W
  @Meta
    name: 'wApp'
```

This would create in your database a MongoDB collection called `wApps`. `name` must match the class name. `@Meta` is
used for PeerDB and in addition you can define arbitrary class or object methods for your W which will then be
available on Ws returned from the database:

```coffee
class wApp extends W
  # Other fields:
  #   username
  #   displayName
  #   email
  #   homepage

  @Meta
    name: 'wApp'

  # Class methods
  @verboseName: ->
    @Meta._name.toLowerCase()

  @verboseNamePlural: ->
    "#{ @verboseName() }s"

  # Instance method
  getDisplayName: =>
    @displayName or @username
```

You can also wrap existing Meteor collections:

```coffee
class User extends W
  @Meta
    name: 'User'
    collection: Meteor.users
```

And if you need to access the internal or wrapped collection you can do that by:

```coffee
wApp.Meta.collection._ensureIndex
  username: 1
```

Querying
--------

PeerDB provides an alternative to Meteor collections query methods. You should be using them to access Ws. You
can access them through the `Ws` property of your W class. For example:

```coffee
wApp.Ws.find({}).forEach (wApp, i, cursor) =>
  console.log wApp.constructor.verboseName(), wApp.getDisplayName()

wApp.Ws.findOne().getDisplayName()

wApp.Ws.findOne().email
```

The functions and arguments available are the same as those available for Meteor collections, with the addition of:

* `.Ws.exists(query, options)` – efficient check if any W matches given `query`

In a similar way we extend the cursor returned from `.Ws.find(...)` with an `exists` method which operates
similar to the `count` method, only that it is more efficient:

```coffee
wApp.Ws.exists({})
wApp.Ws.find({}).exists()
```

`wApp.Meta` gives you back W metadata and `wApp.Ws` give you access to all Ws.

All this is just an easy way to define Ws and collections in a unified fashion, but it becomes interesting
when you start defining relations between Ws.

References
----------

In the traditional SQL world of relational databases you do joins between related Ws every time you read them from
the database. This makes reading slower, your database management system is redoing the same computation of joins
for every read, and also horizontal scaling of a database to many instances is harder because every read might potentially
have to talk to other instances.

NoSQL databases like MongoDB remove relations between Ws and leave it to users to resolve relations on their own.
This often means fetching one W, observing which other Ws it references, and fetching those as well.
Because each of those Ws are stand-alone and static, it is relatively easy and quick for a database management
system like MongoDB to find and return them. Such an approach is quick and it scales easily, but the
downside is the multiple round trips you have to do in your code to get all Ws you are interested in. Those
round trips become even worse when those queries are coming over the Internet from Meteor client code,
because Internet latency is much higher.

For a general case you can move this fetching of related Ws to the server side into Meteor publish functions by
using libraries like [meteor-related](https://github.com/peerlibrary/meteor-related). It provides an easy way to fetch
related Ws reactively, so when dependencies change, your published Ws will be updated accordingly. While
latency to your database instances is hopefully better on your server, we did not really improve much from the SQL
world: you are effectively recomputing joins and now even in a much less efficient way, especially if you are reading
multiple Ws at the same time.

Luckily, in many cases we can observe that we are mostly interested only in few fields of a related W, again
and again. Instead of recomputing joins every time we read, we could use MongoDB's sub-Ws feature to embed
those fields along with the reference. Instead of just storing the `_id` of a related W, we could store also
those few often used fields. For example, if you are displaying blog wNodes, you want to display the author's name together
with the blog wNode. You won't really need only the blog wNode without the author name. An example blog wNode W
could then look like:

```json
{
  "_id": "frqejWeGWjDTPMj7P",
  "body": "A simple blog wNode",
  "author": {
    "_id": "yeK7R5Lws6MSeRQad",
    "username": "wesley",
    "displayName": "Wesley Crusher"
  },
  "subscribers": [
    {
      "_id": "k7cgWtxQpPQ3gLgxa"
    },
    {
      "_id": "KMYNwr7TsZvEboXCw"
    },
    {
      "_id": "tMgj8mF2zF3gjCftS"
    }
  ],
  "reviewers": [
    {
      "_id": "tMgj8mF2zF3gjCftS",
      "username": "deanna",
      "displayName": "Deanna Troi"
    }
  ]
}
```

Great! Now we have to fetch only this one W and we have everything needed to display a blog wNode. It is easy
for us to publish it with Meteor and use it as any other W, with direct access to author's fields.

Now, storing the author's name along with every blog wNode W brings an issue. What if user changes their
name? Then you have to update all those fields in Ws referencing the user. So you would have to make sure that
anywhere in your code where you are changing the name, you are also updating fields in references. What about changes
to the database coming from outside of your code? Here is when PeerDB comes into action. With PeerDB you define those
references once and then PeerDB makes sure they stay in sync. It does not matter where the changes come from, it will
detect them and update fields in referenced sub-Ws accordingly.

If we have two Ws:

```coffee
class wApp extends W
  # Other fields:
  #   username
  #   displayName
  #   email
  #   homepage

  @Meta
    name: 'wApp'

class wNode extends W
  # Other fields:
  #   body

  @Meta
    name: 'wNode'
    fields: =>
      # We can reference other W
      author: @ReferenceField wApp, ['username', 'displayName']
      # Or an array of Ws
      subscribers: [@ReferenceField wApp]
      reviewers: [@ReferenceField wApp, ['username', 'displayName']]
```

We are using `@Meta`'s `fields` argument to define references.

In the above definition, the `author` field will be a subW containing `_id` (always added) and the `username`
and `displayName` fields. If the `displayName` field in the referenced `wApp` W is changed, the `author` field
in all related `wNode` Ws will be automatically updated with the new value for the `displayName` field.

```coffee
wApp.Ws.update 'tMgj8mF2zF3gjCftS',
  $set:
    displayName: 'Deanna Troi-Riker'

# Returns "Deanna Troi-Riker"
wNode.Ws.findOne('frqejWeGWjDTPMj7P').reviewers[0].displayName

# Returns "Deanna Troi-Riker", sub-Ws are objectified into W instances as well
wNode.Ws.findOne('frqejWeGWjDTPMj7P').reviewers[0].getDisplayName()
```

The `subscribers` field is an array of references to `wApp` Ws, where every element in the array will
be a subW containing only the `_id` field.

Circular references are possible as well:

```coffee
class CircularFirst extends W
  # Other fields:
  #   content

  @Meta
    name: 'CircularFirst'
    fields: =>
      # We can reference circular Ws
      second: @ReferenceField CircularSecond, ['content']

class CircularSecond extends W
  # Other fields:
  #   content

  @Meta
    name: 'CircularSecond'
    fields: =>
      # But of course one should not be required so that we can insert without warnings
      first: @ReferenceField CircularFirst, ['content'], false
```

If you want to reference the same W recursively, use the string `'self'` as an argument to `@ReferenceField`.

```coffee
class Recursive extends W
  # Other fields:
  #   content

  @Meta
    name: 'Recursive'
    fields: =>
      other: @ReferenceField 'self', ['content'], false
```

All those references between Ws can be tricky as you might want to reference Ws defined afterwards
and JavaScript symbols might not even exist yet in the scope, and PeerDB works hard to still allow you to do that.
But to make sure all symbols are correctly resolved you should call `W.defineAll()` after all your definitions.
The best is to put it in the filename which is loaded last.

One more example to show use of nested objects:

```coffee
class ACLW extends W
  @Meta
    name: 'ACLW'
    fields: =>
      permissions:
        admins: [@ReferenceField User]
        editors: [@ReferenceField User]
```

You can also do:

```coffee
class ACLW extends W
  # Each permission object inside "permissions" could have also
  # timestamp and permission type fields.

  @Meta
    name: 'ACLW'
    fields: =>
      permissions: [
        user: @ReferenceField User
        grantor: @ReferenceField User, [], false
      ]
```

`ReferenceField` accepts the following arguments:

* `targetW` – target W class, or `'self'`
* `fields` – list of fields to sync in a reference's sub-W; instead of a field name you can use a MongoDB projection as well, like `emails: {$slice: 1}`
* `required` – should the reference be required (default) or not. If required, when the referenced W is removed, this W will be removed as well. Ff not required, the reference will be set to `null`.
* `reverseName` – name of a field for a reverse reference; specify to enable a reverse reference
* `reverseFields` – list of fields to sync for a reference reference

What are reverse references?

Reverse references
------------------

Sometimes you want also to have easy access to information about all the Ws referencing a given W.
For example, for each author you might want to have a list of all blog wNodes they wrote, as part of their W.

```coffee
class wNode extends wNode
  @Meta
    name: 'wNode'
    replaceParent: true
    fields: (fields) =>
      fields.author = @ReferenceField wApp, ['username', 'displayName'], true, 'wNodes'
      fields
```

We [redefine](#abstract-Ws-and-replaceparent) the `wNode` W and replace it with a new definition which enables
reverse references for the `author` field. Now `wApp.Ws.findOne('yeK7R5Lws6MSeRQad')` returns:

```json
{
  "_id": "yeK7R5Lws6MSeRQad",
  "username": "wesley",
  "displayName": "Wesley Crusher",
  "email": "wesley@enterprise.starfleet",
  "homepage": "https://gww.enterprise.starfleet/~wesley/",
  "wNodes": [
    {
      "_id": "frqejWeGWjDTPMj7P"
    }
  ]
}
```

Auto-generated fields
---------------------

Sometimes you need fields in a W which are based on other fields. PeerDB allows you an easy way to define
such auto-generated fields:

```coffee
class wNode extends wNode
  # Other fields:
  #   title

  @Meta
    name: 'wNode'
    replaceParent: true
    fields: (fields) =>
      fields.slug = @GeneratedField 'self', ['title'], (fields) ->
        unless fields.title
          [fields._id, undefined]
        else
          [fields._id, "prefix-#{ fields.title.toLowerCase() }-suffix"]
      fields
```

The last argument of `GeneratedField` is a function which receives an object populated with values based on the list of
fields you are interested in. In the example above, this is one field named `title` from the `wNodes` collection. The `_id`
field is always available in `fields`. Generator function receives or just `_id` (when W containing fields is being
removed) or all fields requested. Generator function should return two values, a selector (often just the ID of a W)
and a new value. If the value is undefined, the auto-generated field is removed. If the selector is undefined, nothing is done.

You can define auto-generated fields across Ws. Furthermore, you can combine reactivity. Maybe you want to also
have a count of all wNodes made by a wApp?

```coffee
class wApp extends wApp
  @Meta
    name: 'wApp'
    replaceParent: true
    fields: (fields) =>
      fields.wNodesCount = @GeneratedField 'self', ['wNodes'], (fields) ->
        [fields._id, fields.wNodes?.length or 0]
      fields
```

Triggers
--------

You can define triggers which are run every time any of the specified fields changes:

```coffee
class wNode extends wNode
  # Other fields:
  #   updatedAt

  @Meta
    name: 'wNode'
    replaceParent: true
    triggers: =>
      updateUpdatedAt: @Trigger ['title', 'body'], (newW, oldW) ->
        # Don't do anything when W is removed
        return unless newW._id

        timestamp = new Date()
        wNode.Ws.update
          _id: newW._id
          updatedAt:
            $lt: timestamp
        ,
          $set:
            updatedAt: timestamp
```

The return value is ignored. Triggers are useful when you want arbitrary code to be run when fields change.
This could be implemented directly with [observe](http://docs.meteor.com/#observe), but triggers
simplify that and provide an alternative API in the PeerDB spirit.

Why we are using a trigger here and not an auto-generated field? The main reason is that we want to enssure
`updatedAt` really just increases, so a more complicated update query is needed. Additionally, reference
fields and auto-generated fields should be without side-effects and should be allowed to be called at any
time. This is to enssure that we can re-sync any broken references as needed. If you would use an
auto-generated field, it could be called again at a later time, updating `updatedAt` to a later time
without any content of a W really changing.

PeerDB does not really re-sync any broken references (made while your Meteor application was not running)
automatically. If you believe such references exist (eg., after a hard crash of your application), you
can trigger re-syncing by calling `W.updateAll()`. All references will be resynced and all
auto-generated fields rerun. But not triggers. It is a quite heavy operation.

Abstract Ws and `replaceParent`
--------------------------------------

You can define abstract Ws by setting the `abstract` `Meta` flag to `true`. Such Ws will not create
a MongoDB collection. They are useful to define common fields and methods you want to reuse in multiple
Ws.

We skimmed over `replaceParent` before. You should set it to `true` when you are defining a W with the
same name as a W you are extending (parent). It is a kind of a sanity check that you know what you are
doing and that you are promising you are not holding a reference to the extended (and replaced) W somewhere
and you expect it to work when using it. How useful `replaceParent` really is, is a good question, but it
allows you to define a common (client and server side) W and then augment it on the server side with
server-specific code.

Initialization
--------------

If you would like to run some code after Meteor startup, but before observers are enabled, you can use `W.prepare`
to register a callback. If you would like to run some code after Meteor startup and after observers are enabled, you can
use `W.startup` to register a callback.

Settings
--------

### `PEERDB_INSTANCES=1` ###

As your application grows you might want to run specialized Meteor instances just to do PeerDB reactive MongoDB
queries. To distribute PeerDB load, configure the number of PeerDB instances using the `PEERDB_INSTANCES` environment variable.
Suggested setting is that your web-facing instances disable PeerDB by setting `PEERDB_INSTANCES` to 0, and then you have
dedicated PeerDB instances.

### `PEERDB_INSTANCE=0` ###

If you are running multiple PeerDB instances, which instance is this? It is zero-based index so if you configured
`PEERDB_INSTANCES=2`, you have to have two instances, one with `PEERDB_INSTANCE=0` and another with `PEERDB_INSTANCE=1`.

### `MONGO_OPLOG_URL` and `MONGO_URL` ###

When running multiple instances you want to connect them all to the same database. You have to configure both normal
MongoDB connection and also the oplog connection. You can use your own MongoDB instance or connect to one provided by
running Meteor in development mode. In the latter case the recommended way is that one web-facing instance runs
MongoDB and all other instances connect to that MongoDB.

```
MONGO_OPLOG_URL=mongodb://127.0.0.1:3001/local
MONGO_URL=mongodb://127.0.0.1:3001/meteor
```

Examples
--------

See [tests](https://github.com/peerlibrary/meteor-peerdb/blob/master/tests.coffee) for many examples. See
[W definitions in PeerLibrary](https://github.com/peerlibrary/peerlibrary/tree/development/lib/Ws) for
real-world definitions.

Related projects
----------------

* [meteor-collection-hooks](https://github.com/matb33/meteor-collection-hooks) – provides an alternative way to
attach additional program logic on changes to your data, but it hooks into collection API methods so if a change comes
from the outside, hooks are not called; additionally, collection API methods are delayed for the time of all hooks to
be executed while in PeerDB hooks run in parallel in or even in a separate process (or processes), allowing your code to
return quickly while PeerDB assures that data will be eventually consistent (this has a downside of course as well,
so if you do not want that API calls return before all hooks run, `meteor-collection-hooks` might be more suitable for
you)
* [meteor-related](https://github.com/peerlibrary/meteor-related) – while PeerDB provides an easy way to embed referenced
Ws as subWs, it requires that those relations are the same for all users; if you want dynamic relations
between Ws, `meteor-related` provides an easy way to fetch related Ws reactively on the server side, so
when dependencies change, your published Ws will be updated accordingly
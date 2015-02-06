WAIT_FOR_DATABASE_TIMEOUT = 1000 # ms

# The order of Ws here tests delayed definitions


if Meteor.isServer
  globalTestTriggerCounters = {}

class wNode extends W
  # Other fields:
  #   body
  #   subW
  #     body
  #   nested
  #     body

  @Meta
    name: 'wNode'
    fields: =>
      # We can reference other W
      author: @ReferenceField Person
      , ['username'
      , 'displayName'
      , 'field1'
      , 'field2']
      , true
      , 'wNodes'
      , ['body'
      , 'subW.body'
      , 'nested.body']
      # Or an array of Ws
      subscribers: [@ReferenceField Person]
      # Fields can be arbitrary MongoDB projections
      reviewers: [@ReferenceField Person, [username: 1]]
      subW:
        person: @ReferenceField Person, ['username', 'displayName', 'field1', 'field2'], false, 'subWwNodes', ['body', 'subW.body', 'nested.body']
        slug: @GeneratedField 'self', ['body', 'subW.body'], (fields) ->
          if _.isUndefined(fields.body) or _.isUndefined(fields.subW?.body)
            [fields._id, undefined]
          else if _.isNull(fields.body) or _.isNull(fields.subW.body)
            [fields._id, null]
          else
            [fields._id, "subW-prefix-#{ fields.body.toLowerCase() }-#{ fields.subW.body.toLowerCase() }-suffix"]
      nested: [
        required: @ReferenceField Person, ['username', 'displayName', 'field1', 'field2'], true, 'nestedwNodes', ['body', 'subW.body', 'nested.body']
        optional: @ReferenceField Person, ['username'], false
        slug: @GeneratedField 'self', ['body', 'nested.body'], (fields) ->
          for nested in fields.nested or []
            if _.isUndefined(fields.body) or _.isUndefined(nested.body)
              [fields._id, undefined]
            else if _.isNull(fields.body) or _.isNull(nested.body)
              [fields._id, null]
            else
              [fields._id, "nested-prefix-#{ fields.body.toLowerCase() }-#{ nested.body.toLowerCase() }-suffix"]
      ]
      slug: @GeneratedField 'self', ['body', 'subW.body'], (fields) ->
        if _.isUndefined(fields.body) or _.isUndefined(fields.subW?.body)
          [fields._id, undefined]
        else if _.isNull(fields.body) or _.isNull(fields.subW.body)
          [fields._id, null]
        else
          [fields._id, "prefix-#{ fields.body.toLowerCase() }-#{ fields.subW.body.toLowerCase() }-suffix"]
      tags: [
        @GeneratedField 'self', ['body', 'subW.body', 'nested.body'], (fields) ->
          tags = []
          if fields.body and fields.subW?.body
            tags.push "tag-#{ tags.length }-prefix-#{ fields.body.toLowerCase() }-#{ fields.subW.body.toLowerCase() }-suffix"
          if fields.body and fields.nested and _.isArray fields.nested
            for nested in fields.nested when nested.body
              tags.push "tag-#{ tags.length }-prefix-#{ fields.body.toLowerCase() }-#{ nested.body.toLowerCase() }-suffix"
          [fields._id, tags]
      ]
    triggers: =>
      testTrigger: @Trigger ['body'], (newW, oldW) ->
        return unless newW._id
        globalTestTriggerCounters[newW._id] = (globalTestTriggerCounters[newW._id] or 0) + 1

# Store away for testing
_TestwNode = wNode

# Extending delayed W
class wNode extends wNode
  @Meta
    name: 'wNode'
    replaceParent: true
    fields: (fields) =>
      fields.subW.persons = [@ReferenceField Person, ['username', 'displayName', 'field1', 'field2'], true, 'subWswNodes', ['body', 'subW.body', 'nested.body']]
      fields

# Store away for testing
_TestwNode2 = wNode

class User extends W
  @Meta
    name: 'User'
    # Specifying collection directly
    collection: Meteor.users

class UserLink extends W
  @Meta
    name: 'UserLink'
    fields: =>
      user: @ReferenceField User, ['username'], false

class wNodeLink extends W
  @Meta
    name: 'wNodeLink'

# Store away for testing
_TestwNodeLink = wNodeLink

# To test extending when initial W has no fields
class wNodeLink extends wNodeLink
  @Meta
    name: 'wNodeLink'
    replaceParent: true
    fields: =>
      wNode: @ReferenceField wNode, ['subW.person', 'subW.persons']

class CircularFirst extends W
  # Other fields:
  #   content

  @Meta
    name: 'CircularFirst'

# Store away for testing
_TestCircularFirst = CircularFirst

# To test extending when initial W has no fields and fields will be delayed
class CircularFirst extends CircularFirst
  @Meta
    name: 'CircularFirst'
    replaceParent:  true
    fields: (fields) =>
      # We can reference circular Ws
      fields.second = @ReferenceField CircularSecond, ['content'], true, 'reverseFirsts', ['content']
      fields

class CircularSecond extends W
  # Other fields:
  #   content

  @Meta
    name: 'CircularSecond'
    fields: =>
      # But of course one should not be required so that we can insert without warnings
      first: @ReferenceField CircularFirst, ['content'], false, 'reverseSeconds', ['content']

class Person extends W
  # Other fields:
  #   username
  #   displayName
  #   field1
  #   field2

  @Meta
    name: 'Person'
    fields: =>
      count: @GeneratedField 'self', ['wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'], (fields) ->
        [fields._id, (fields.wNodes?.length or 0) + (fields.nestedwNodes?.length or 0) + (fields.subWwNodes?.length or 0) + (fields.subWswNodes?.length or 0)]

# Store away for testing
_TestPerson = Person

# To test if reverse fields *are* added to the extended class which replaces the parent
class Person extends Person
  @Meta
    name: 'Person'
    replaceParent: true

  formatName: ->
    "#{ @username }-#{ @displayName or "none" }"

# To test if reverse fields are *not* added to the extended class which replaces the parent
class SpecialPerson extends Person
  @Meta
    name: 'SpecialPerson'
    fields: =>
      # wNodes and nestedwNodes don't exist, so we remove count field as well
      count: undefined

class RecursiveBase extends W
  @Meta
    abstract: true
    fields: =>
      other: @ReferenceField 'self', ['content'], false, 'reverse', ['content']

class Recursive extends RecursiveBase
  # Other fields:
  #   content

  @Meta
    name: 'Recursive'

class IdentityGenerator extends W
  # Other fields:
  #   source

  @Meta
    name: 'IdentityGenerator'
    fields: =>
      result: @GeneratedField 'self', ['source'], (fields) ->
        throw new Error "Test exception" if fields.source is 'exception'
        return [fields._id, fields.source]
      results: [
        @GeneratedField 'self', ['source'], (fields) ->
          return [fields._id, fields.source]
      ]

# Extending and renaming the class, this creates new collection as well
class SpecialwNode extends wNode
  @Meta
    name: 'SpecialwNode'
    fields: =>
      special: @ReferenceField Person

# To test redefinig after fields already have a reference to an old W
class wNode extends wNode
  @Meta
    name: 'wNode'
    replaceParent: true

W.defineAll()

# Just to make sure things are sane

###


# Just to make sure things are sane
assert.equal W._delayed.length, 0

if Meteor.isServer
  # Initialize the database
  wNode.Ws.remove {}
  User.Ws.remove {}
  UserLink.Ws.remove {}
  wNodeLink.Ws.remove {}
  CircularFirst.Ws.remove {}
  CircularSecond.Ws.remove {}
  Person.Ws.remove {}
  Recursive.Ws.remove {}
  IdentityGenerator.Ws.remove {}
  SpecialwNode.Ws.remove {}

  Meteor.publish null, ->
    wNode.Ws.find()
  # User is already published as Meteor.users
  Meteor.publish null, ->
    UserLink.Ws.find()
  Meteor.publish null, ->
    wNodeLink.Ws.find()
  Meteor.publish null, ->
    CircularFirst.Ws.find()
  Meteor.publish null, ->
    CircularSecond.Ws.find()
  Meteor.publish null, ->
    Person.Ws.find()
  Meteor.publish null, ->
    Recursive.Ws.find()
  Meteor.publish null, ->
    IdentityGenerator.Ws.find()
  Meteor.publish null, ->
    SpecialwNode.Ws.find()

  Future = Npm.require 'fibers/future'

  Meteor.methods
    'wait-for-database': ->
      future = new Future()
      timeout = null
      newTimeout = ->
        Meteor.clearTimeout timeout if timeout
        timeout = Meteor.setTimeout ->
          timeout = null
          future.return() unless future.isResolved()
        , WAIT_FOR_DATABASE_TIMEOUT
      newTimeout()
      handles = []
      for W in W.list
        do (W) ->
          initializing = true
          handles.push W.Ws.find({}).observeChanges
            added: (id, fields) ->
              newTimeout() unless initializing
            changed: (id, fields) ->
              newTimeout()
            removed: (id) ->
              newTimeout()
          initializing = false
      future.wait()
      for handle in handles
        handle.stop()

waitForDatabase = (test, expect) ->
  Meteor.call 'wait-for-database', expect (error) ->
    test.isFalse error, error?.toString?() or error

ALL = @ALL = [User, UserLink, CircularFirst, CircularSecond, SpecialPerson, Recursive, IdentityGenerator, SpecialwNode, wNode, Person, wNodeLink]

testWList = (test, list) ->
  test.equal W.list, list, "expected: #{ (d.Meta._name for d in list) } vs. actual: #{ (d.Meta._name for d in W.list) }"

intersectionObjects = (array, rest...) ->
  _.filter _.uniq(array), (item) ->
    _.every rest, (other) ->
      _.any other, (element) -> _.isEqual element, item

testSetEqual = (test, a, b) ->
  a ||= []
  b ||= []

  if a.length is b.length and intersectionObjects(a, b).length is a.length
    test.ok()
  else
    test.fail
      type: 'assert_set_equal'
      actual: JSON.stringify a
      expected: JSON.stringify b

testDefinition = (test) ->
  test.equal wNode.Meta._name, 'wNode'
  test.equal wNode.Meta.parent, _TestwNode2.Meta
  test.equal wNode.Meta.W, wNode
  test.equal wNode.Meta.collection._name, 'wNodes'
  test.equal _.size(wNode.Meta.triggers), 1
  test.instanceOf wNode.Meta.triggers.testTrigger, wNode._Trigger
  test.equal wNode.Meta.triggers.testTrigger.name, 'testTrigger'
  test.equal wNode.Meta.triggers.testTrigger.W, wNode
  test.equal wNode.Meta.triggers.testTrigger.collection._name, 'wNodes'
  test.equal wNode.Meta.triggers.testTrigger.fields, ['body']
  test.equal _.size(wNode.Meta.fields), 7
  test.instanceOf wNode.Meta.fields.author, wNode._ReferenceField
  test.isNull wNode.Meta.fields.author.ancestorArray, wNode.Meta.fields.author.ancestorArray
  test.isTrue wNode.Meta.fields.author.required
  test.equal wNode.Meta.fields.author.sourcePath, 'author'
  test.equal wNode.Meta.fields.author.sourceW, wNode
  test.equal wNode.Meta.fields.author.targetW, Person
  test.equal wNode.Meta.fields.author.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.author.targetCollection._name, 'Persons'
  test.equal wNode.Meta.fields.author.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.author.targetW.Meta.collection._name, 'Persons'
  test.equal wNode.Meta.fields.author.fields, ['username', 'displayName', 'field1', 'field2']
  test.equal wNode.Meta.fields.author.reverseName, 'wNodes'
  test.equal wNode.Meta.fields.author.reverseFields, ['body', 'subW.body', 'nested.body']
  test.instanceOf wNode.Meta.fields.subscribers, wNode._ReferenceField
  test.equal wNode.Meta.fields.subscribers.ancestorArray, 'subscribers'
  test.isTrue wNode.Meta.fields.subscribers.required
  test.equal wNode.Meta.fields.subscribers.sourcePath, 'subscribers'
  test.equal wNode.Meta.fields.subscribers.sourceW, wNode
  test.equal wNode.Meta.fields.subscribers.targetW, Person
  test.equal wNode.Meta.fields.subscribers.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.subscribers.targetCollection._name, 'Persons'
  test.equal wNode.Meta.fields.subscribers.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.subscribers.targetW.Meta.collection._name, 'Persons'
  test.equal wNode.Meta.fields.subscribers.fields, []
  test.isNull wNode.Meta.fields.subscribers.reverseName
  test.equal wNode.Meta.fields.subscribers.reverseFields, []
  test.instanceOf wNode.Meta.fields.reviewers, wNode._ReferenceField
  test.equal wNode.Meta.fields.reviewers.ancestorArray, 'reviewers'
  test.isTrue wNode.Meta.fields.reviewers.required
  test.equal wNode.Meta.fields.reviewers.sourcePath, 'reviewers'
  test.equal wNode.Meta.fields.reviewers.sourceW, wNode
  test.equal wNode.Meta.fields.reviewers.targetW, Person
  test.equal wNode.Meta.fields.reviewers.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.reviewers.targetCollection._name, 'Persons'
  test.equal wNode.Meta.fields.reviewers.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.reviewers.targetW.Meta.collection._name, 'Persons'
  test.equal wNode.Meta.fields.reviewers.fields, [username: 1]
  test.isNull wNode.Meta.fields.reviewers.reverseName
  test.equal wNode.Meta.fields.reviewers.reverseFields, []
  test.equal _.size(wNode.Meta.fields.subW), 3
  test.instanceOf wNode.Meta.fields.subW.person, wNode._ReferenceField
  test.isNull wNode.Meta.fields.subW.person.ancestorArray, wNode.Meta.fields.subW.person.ancestorArray
  test.isFalse wNode.Meta.fields.subW.person.required
  test.equal wNode.Meta.fields.subW.person.sourcePath, 'subW.person'
  test.equal wNode.Meta.fields.subW.person.sourceW, wNode
  test.equal wNode.Meta.fields.subW.person.targetW, Person
  test.equal wNode.Meta.fields.subW.person.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.subW.person.targetCollection._name, 'Persons'
  test.equal wNode.Meta.fields.subW.person.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.subW.person.targetW.Meta.collection._name, 'Persons'
  test.equal wNode.Meta.fields.subW.person.fields, ['username', 'displayName', 'field1', 'field2']
  test.equal wNode.Meta.fields.subW.person.reverseName, 'subWwNodes'
  test.equal wNode.Meta.fields.subW.person.reverseFields, ['body', 'subW.body', 'nested.body']
  test.instanceOf wNode.Meta.fields.subW.persons, wNode._ReferenceField
  test.equal wNode.Meta.fields.subW.persons.ancestorArray, 'subW.persons'
  test.isTrue wNode.Meta.fields.subW.persons.required
  test.equal wNode.Meta.fields.subW.persons.sourcePath, 'subW.persons'
  test.equal wNode.Meta.fields.subW.persons.sourceW, wNode
  test.equal wNode.Meta.fields.subW.persons.targetW, Person
  test.equal wNode.Meta.fields.subW.persons.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.subW.persons.targetCollection._name, 'Persons'
  test.equal wNode.Meta.fields.subW.persons.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.subW.persons.targetW.Meta.collection._name, 'Persons'
  test.equal wNode.Meta.fields.subW.persons.fields, ['username', 'displayName', 'field1', 'field2']
  test.equal wNode.Meta.fields.subW.persons.reverseName, 'subWswNodes'
  test.equal wNode.Meta.fields.subW.persons.reverseFields, ['body', 'subW.body', 'nested.body']
  test.instanceOf wNode.Meta.fields.subW.slug, wNode._GeneratedField
  test.isNull wNode.Meta.fields.subW.slug.ancestorArray, wNode.Meta.fields.subW.slug.ancestorArray
  test.isTrue _.isFunction wNode.Meta.fields.subW.slug.generator
  test.equal wNode.Meta.fields.subW.slug.sourcePath, 'subW.slug'
  test.equal wNode.Meta.fields.subW.slug.sourceW, wNode
  test.equal wNode.Meta.fields.subW.slug.targetW, wNode
  test.equal wNode.Meta.fields.subW.slug.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.subW.slug.targetCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.subW.slug.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.subW.slug.targetW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.subW.slug.fields, ['body', 'subW.body']
  test.isUndefined wNode.Meta.fields.subW.slug.reverseName
  test.isUndefined wNode.Meta.fields.subW.slug.reverseFields
  test.equal _.size(wNode.Meta.fields.nested), 3
  test.instanceOf wNode.Meta.fields.nested.required, wNode._ReferenceField
  test.equal wNode.Meta.fields.nested.required.ancestorArray, 'nested'
  test.isTrue wNode.Meta.fields.nested.required.required
  test.equal wNode.Meta.fields.nested.required.sourcePath, 'nested.required'
  test.equal wNode.Meta.fields.nested.required.sourceW, wNode
  test.equal wNode.Meta.fields.nested.required.targetW, Person
  test.equal wNode.Meta.fields.nested.required.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.nested.required.targetCollection._name, 'Persons'
  test.equal wNode.Meta.fields.nested.required.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.nested.required.targetW.Meta.collection._name, 'Persons'
  test.equal wNode.Meta.fields.nested.required.fields, ['username', 'displayName', 'field1', 'field2']
  test.equal wNode.Meta.fields.nested.required.reverseName, 'nestedwNodes'
  test.equal wNode.Meta.fields.nested.required.reverseFields, ['body', 'subW.body', 'nested.body']
  test.instanceOf wNode.Meta.fields.nested.optional, wNode._ReferenceField
  test.equal wNode.Meta.fields.nested.optional.ancestorArray, 'nested'
  test.isFalse wNode.Meta.fields.nested.optional.required
  test.equal wNode.Meta.fields.nested.optional.sourcePath, 'nested.optional'
  test.equal wNode.Meta.fields.nested.optional.sourceW, wNode
  test.equal wNode.Meta.fields.nested.optional.targetW, Person
  test.equal wNode.Meta.fields.nested.optional.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.nested.optional.targetCollection._name, 'Persons'
  test.equal wNode.Meta.fields.nested.optional.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.nested.optional.targetW.Meta.collection._name, 'Persons'
  test.equal wNode.Meta.fields.nested.optional.fields, ['username']
  test.isNull wNode.Meta.fields.nested.optional.reverseName
  test.equal wNode.Meta.fields.nested.optional.reverseFields, []
  test.instanceOf wNode.Meta.fields.nested.slug, wNode._GeneratedField
  test.equal wNode.Meta.fields.nested.slug.ancestorArray, 'nested'
  test.isTrue _.isFunction wNode.Meta.fields.nested.slug.generator
  test.equal wNode.Meta.fields.nested.slug.sourcePath, 'nested.slug'
  test.equal wNode.Meta.fields.nested.slug.sourceW, wNode
  test.equal wNode.Meta.fields.nested.slug.targetW, wNode
  test.equal wNode.Meta.fields.nested.slug.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.nested.slug.targetCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.nested.slug.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.nested.slug.targetW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.nested.slug.fields, ['body', 'nested.body']
  test.isUndefined wNode.Meta.fields.nested.slug.reverseName
  test.isUndefined wNode.Meta.fields.nested.slug.reverseFields
  test.instanceOf wNode.Meta.fields.slug, wNode._GeneratedField
  test.isNull wNode.Meta.fields.slug.ancestorArray, wNode.Meta.fields.slug.ancestorArray
  test.isTrue _.isFunction wNode.Meta.fields.slug.generator
  test.equal wNode.Meta.fields.slug.sourcePath, 'slug'
  test.equal wNode.Meta.fields.slug.sourceW, wNode
  test.equal wNode.Meta.fields.slug.targetW, wNode
  test.equal wNode.Meta.fields.slug.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.slug.targetCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.slug.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.slug.targetW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.slug.fields, ['body', 'subW.body']
  test.isUndefined wNode.Meta.fields.slug.reverseName
  test.isUndefined wNode.Meta.fields.slug.reverseFields
  test.instanceOf wNode.Meta.fields.tags, wNode._GeneratedField
  test.equal wNode.Meta.fields.tags.ancestorArray, 'tags'
  test.isTrue _.isFunction wNode.Meta.fields.tags.generator
  test.equal wNode.Meta.fields.tags.sourcePath, 'tags'
  test.equal wNode.Meta.fields.tags.sourceW, wNode
  test.equal wNode.Meta.fields.tags.targetW, wNode
  test.equal wNode.Meta.fields.tags.sourceCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.tags.targetCollection._name, 'wNodes'
  test.equal wNode.Meta.fields.tags.sourceW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.tags.targetW.Meta.collection._name, 'wNodes'
  test.equal wNode.Meta.fields.tags.fields, ['body', 'subW.body', 'nested.body']
  test.isUndefined wNode.Meta.fields.tags.reverseName
  test.isUndefined wNode.Meta.fields.tags.reverseFields

  test.equal User.Meta._name, 'User'
  test.isFalse User.Meta.parent
  test.equal User.Meta.W, User
  test.equal User.Meta.collection._name, 'users'
  test.equal _.size(User.Meta.triggers), 0
  test.equal _.size(User.Meta.fields), 0

  test.equal UserLink.Meta._name, 'UserLink'
  test.isFalse UserLink.Meta.parent
  test.equal UserLink.Meta.W, UserLink
  test.equal UserLink.Meta.collection._name, 'UserLinks'
  test.equal _.size(UserLink.Meta.triggers), 0
  test.equal _.size(UserLink.Meta.fields), 1
  test.instanceOf UserLink.Meta.fields.user, UserLink._ReferenceField
  test.isNull UserLink.Meta.fields.user.ancestorArray, UserLink.Meta.fields.user.ancestorArray
  test.isFalse UserLink.Meta.fields.user.required
  test.equal UserLink.Meta.fields.user.sourcePath, 'user'
  test.equal UserLink.Meta.fields.user.sourceW, UserLink
  test.equal UserLink.Meta.fields.user.targetW, User
  test.equal UserLink.Meta.fields.user.sourceCollection._name, 'UserLinks'
  test.equal UserLink.Meta.fields.user.targetCollection._name, 'users'
  test.equal UserLink.Meta.fields.user.sourceW.Meta.collection._name, 'UserLinks'
  test.equal UserLink.Meta.fields.user.fields, ['username']
  test.isNull UserLink.Meta.fields.user.reverseName
  test.equal UserLink.Meta.fields.user.reverseFields, []

  test.equal wNodeLink.Meta._name, 'wNodeLink'
  test.equal wNodeLink.Meta.parent, _TestwNodeLink.Meta
  test.equal wNodeLink.Meta.W, wNodeLink
  test.equal wNodeLink.Meta.collection._name, 'wNodeLinks'
  test.equal _.size(wNodeLink.Meta.triggers), 0
  test.equal _.size(wNodeLink.Meta.fields), 1
  test.instanceOf wNodeLink.Meta.fields.wNode, wNodeLink._ReferenceField
  test.isNull wNodeLink.Meta.fields.wNode.ancestorArray, wNodeLink.Meta.fields.wNode.ancestorArray
  test.isTrue wNodeLink.Meta.fields.wNode.required
  test.equal wNodeLink.Meta.fields.wNode.sourcePath, 'wNode'
  test.equal wNodeLink.Meta.fields.wNode.sourceW, wNodeLink
  test.equal wNodeLink.Meta.fields.wNode.targetW, wNode
  test.equal wNodeLink.Meta.fields.wNode.sourceCollection._name, 'wNodeLinks'
  test.equal wNodeLink.Meta.fields.wNode.targetCollection._name, 'wNodes'
  test.equal wNodeLink.Meta.fields.wNode.sourceW.Meta.collection._name, 'wNodeLinks'
  test.equal wNodeLink.Meta.fields.wNode.fields, ['subW.person', 'subW.persons']
  test.isNull wNodeLink.Meta.fields.wNode.reverseName
  test.equal wNodeLink.Meta.fields.wNode.reverseFields, []

  test.equal CircularFirst.Meta._name, 'CircularFirst'
  test.equal CircularFirst.Meta.parent, _TestCircularFirst.Meta
  test.equal CircularFirst.Meta.W, CircularFirst
  test.equal CircularFirst.Meta.collection._name, 'CircularFirsts'
  test.equal _.size(CircularFirst.Meta.triggers), 0
  test.equal _.size(CircularFirst.Meta.fields), 2
  test.instanceOf CircularFirst.Meta.fields.second, CircularFirst._ReferenceField
  test.isNull CircularFirst.Meta.fields.second.ancestorArray, CircularFirst.Meta.fields.second.ancestorArray
  test.isTrue CircularFirst.Meta.fields.second.required
  test.equal CircularFirst.Meta.fields.second.sourcePath, 'second'
  test.equal CircularFirst.Meta.fields.second.sourceW, CircularFirst
  test.equal CircularFirst.Meta.fields.second.targetW, CircularSecond
  test.equal CircularFirst.Meta.fields.second.sourceCollection._name, 'CircularFirsts'
  test.equal CircularFirst.Meta.fields.second.targetCollection._name, 'CircularSeconds'
  test.equal CircularFirst.Meta.fields.second.sourceW.Meta.collection._name, 'CircularFirsts'
  test.equal CircularFirst.Meta.fields.second.targetW.Meta.collection._name, 'CircularSeconds'
  test.equal CircularFirst.Meta.fields.second.fields, ['content']
  test.equal CircularFirst.Meta.fields.second.reverseName, 'reverseFirsts'
  test.equal CircularFirst.Meta.fields.second.reverseFields, ['content']
  test.instanceOf CircularFirst.Meta.fields.reverseSeconds, CircularFirst._ReferenceField
  test.equal CircularFirst.Meta.fields.reverseSeconds.ancestorArray, 'reverseSeconds'
  test.isTrue CircularFirst.Meta.fields.reverseSeconds.required
  test.equal CircularFirst.Meta.fields.reverseSeconds.sourcePath, 'reverseSeconds'
  test.equal CircularFirst.Meta.fields.reverseSeconds.sourceW, CircularFirst
  test.equal CircularFirst.Meta.fields.reverseSeconds.targetW, CircularSecond
  test.equal CircularFirst.Meta.fields.reverseSeconds.sourceCollection._name, 'CircularFirsts'
  test.equal CircularFirst.Meta.fields.reverseSeconds.targetCollection._name, 'CircularSeconds'
  test.equal CircularFirst.Meta.fields.reverseSeconds.sourceW.Meta.collection._name, 'CircularFirsts'
  test.equal CircularFirst.Meta.fields.reverseSeconds.targetW.Meta.collection._name, 'CircularSeconds'
  test.equal CircularFirst.Meta.fields.reverseSeconds.fields, ['content']
  test.isNull CircularFirst.Meta.fields.reverseSeconds.reverseName
  test.equal CircularFirst.Meta.fields.reverseSeconds.reverseFields, []

  test.equal CircularSecond.Meta._name, 'CircularSecond'
  test.isFalse CircularSecond.Meta.parent
  test.equal CircularSecond.Meta.W, CircularSecond
  test.equal CircularSecond.Meta.collection._name, 'CircularSeconds'
  test.equal _.size(CircularSecond.Meta.triggers), 0
  test.equal _.size(CircularSecond.Meta.fields), 2
  test.instanceOf CircularSecond.Meta.fields.first, CircularSecond._ReferenceField
  test.isNull CircularSecond.Meta.fields.first.ancestorArray, CircularSecond.Meta.fields.first.ancestorArray
  test.isFalse CircularSecond.Meta.fields.first.required
  test.equal CircularSecond.Meta.fields.first.sourcePath, 'first'
  test.equal CircularSecond.Meta.fields.first.sourceW, CircularSecond
  test.equal CircularSecond.Meta.fields.first.targetW, CircularFirst
  test.equal CircularSecond.Meta.fields.first.sourceCollection._name, 'CircularSeconds'
  test.equal CircularSecond.Meta.fields.first.targetCollection._name, 'CircularFirsts'
  test.equal CircularSecond.Meta.fields.first.sourceW.Meta.collection._name, 'CircularSeconds'
  test.equal CircularSecond.Meta.fields.first.targetW.Meta.collection._name, 'CircularFirsts'
  test.equal CircularSecond.Meta.fields.first.fields, ['content']
  test.equal CircularSecond.Meta.fields.first.reverseName, 'reverseSeconds'
  test.equal CircularSecond.Meta.fields.first.reverseFields, ['content']
  test.instanceOf CircularSecond.Meta.fields.reverseFirsts, CircularSecond._ReferenceField
  test.equal CircularSecond.Meta.fields.reverseFirsts.ancestorArray, 'reverseFirsts'
  test.isTrue CircularSecond.Meta.fields.reverseFirsts.required
  test.equal CircularSecond.Meta.fields.reverseFirsts.sourcePath, 'reverseFirsts'
  test.equal CircularSecond.Meta.fields.reverseFirsts.sourceW, CircularSecond
  test.equal CircularSecond.Meta.fields.reverseFirsts.targetW, CircularFirst
  test.equal CircularSecond.Meta.fields.reverseFirsts.sourceCollection._name, 'CircularSeconds'
  test.equal CircularSecond.Meta.fields.reverseFirsts.targetCollection._name, 'CircularFirsts'
  test.equal CircularSecond.Meta.fields.reverseFirsts.sourceW.Meta.collection._name, 'CircularSeconds'
  test.equal CircularSecond.Meta.fields.reverseFirsts.targetW.Meta.collection._name, 'CircularFirsts'
  test.equal CircularSecond.Meta.fields.reverseFirsts.fields, ['content']
  test.isNull CircularSecond.Meta.fields.reverseFirsts.reverseName
  test.equal CircularSecond.Meta.fields.reverseFirsts.reverseFields, []

  test.equal Person.Meta._name, 'Person'
  test.equal Person.Meta.parent, _TestPerson.Meta
  test.equal Person.Meta.W, Person
  test.equal Person.Meta._name, 'Person'
  test.equal Person.Meta.collection._name, 'Persons'
  test.equal _.size(Person.Meta.triggers), 0
  test.equal _.size(Person.Meta.fields), 5
  test.instanceOf Person.Meta.fields.wNodes, Person._ReferenceField
  test.equal Person.Meta.fields.wNodes.ancestorArray, 'wNodes'
  test.isTrue Person.Meta.fields.wNodes.required
  test.equal Person.Meta.fields.wNodes.sourcePath, 'wNodes'
  test.equal Person.Meta.fields.wNodes.sourceW, Person
  test.equal Person.Meta.fields.wNodes.targetW, wNode
  test.equal Person.Meta.fields.wNodes.sourceCollection._name, 'Persons'
  test.equal Person.Meta.fields.wNodes.targetCollection._name, 'wNodes'
  test.equal Person.Meta.fields.wNodes.sourceW.Meta.collection._name, 'Persons'
  test.equal Person.Meta.fields.wNodes.targetW.Meta.collection._name, 'wNodes'
  test.equal Person.Meta.fields.wNodes.fields, ['body', 'subW.body', 'nested.body']
  test.isNull Person.Meta.fields.wNodes.reverseName
  test.equal Person.Meta.fields.wNodes.reverseFields, []
  test.instanceOf Person.Meta.fields.nestedwNodes, Person._ReferenceField
  test.equal Person.Meta.fields.nestedwNodes.ancestorArray, 'nestedwNodes'
  test.isTrue Person.Meta.fields.nestedwNodes.required
  test.equal Person.Meta.fields.nestedwNodes.sourcePath, 'nestedwNodes'
  test.equal Person.Meta.fields.nestedwNodes.sourceW, Person
  test.equal Person.Meta.fields.nestedwNodes.targetW, wNode
  test.equal Person.Meta.fields.nestedwNodes.sourceCollection._name, 'Persons'
  test.equal Person.Meta.fields.nestedwNodes.targetCollection._name, 'wNodes'
  test.equal Person.Meta.fields.nestedwNodes.sourceW.Meta.collection._name, 'Persons'
  test.equal Person.Meta.fields.nestedwNodes.targetW.Meta.collection._name, 'wNodes'
  test.equal Person.Meta.fields.nestedwNodes.fields, ['body', 'subW.body', 'nested.body']
  test.isNull Person.Meta.fields.nestedwNodes.reverseName
  test.equal Person.Meta.fields.nestedwNodes.reverseFields, []
  test.instanceOf Person.Meta.fields.count, Person._GeneratedField
  test.isNull Person.Meta.fields.count.ancestorArray, Person.Meta.fields.count.ancestorArray
  test.isTrue _.isFunction Person.Meta.fields.count.generator
  test.equal Person.Meta.fields.count.sourcePath, 'count'
  test.equal Person.Meta.fields.count.sourceW, Person
  test.equal Person.Meta.fields.count.targetW, Person
  test.equal Person.Meta.fields.count.sourceCollection._name, 'Persons'
  test.equal Person.Meta.fields.count.targetCollection._name, 'Persons'
  test.equal Person.Meta.fields.count.sourceW.Meta.collection._name, 'Persons'
  test.equal Person.Meta.fields.count.targetW.Meta.collection._name, 'Persons'
  test.equal Person.Meta.fields.count.fields, ['wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes']
  test.isUndefined Person.Meta.fields.count.reverseName
  test.isUndefined Person.Meta.fields.count.reverseFields
  test.instanceOf Person.Meta.fields.subWwNodes, Person._ReferenceField
  test.equal Person.Meta.fields.subWwNodes.ancestorArray, 'subWwNodes'
  test.isTrue Person.Meta.fields.subWwNodes.required
  test.equal Person.Meta.fields.subWwNodes.sourcePath, 'subWwNodes'
  test.equal Person.Meta.fields.subWwNodes.sourceW, Person
  test.equal Person.Meta.fields.subWwNodes.targetW, wNode
  test.equal Person.Meta.fields.subWwNodes.sourceCollection._name, 'Persons'
  test.equal Person.Meta.fields.subWwNodes.targetCollection._name, 'wNodes'
  test.equal Person.Meta.fields.subWwNodes.sourceW.Meta.collection._name, 'Persons'
  test.equal Person.Meta.fields.subWwNodes.targetW.Meta.collection._name, 'wNodes'
  test.equal Person.Meta.fields.subWwNodes.fields, ['body', 'subW.body', 'nested.body']
  test.isNull Person.Meta.fields.subWwNodes.reverseName
  test.equal Person.Meta.fields.subWwNodes.reverseFields, []
  test.instanceOf Person.Meta.fields.subWswNodes, Person._ReferenceField
  test.equal Person.Meta.fields.subWswNodes.ancestorArray, 'subWswNodes'
  test.isTrue Person.Meta.fields.subWswNodes.required
  test.equal Person.Meta.fields.subWswNodes.sourcePath, 'subWswNodes'
  test.equal Person.Meta.fields.subWswNodes.sourceW, Person
  test.equal Person.Meta.fields.subWswNodes.targetW, wNode
  test.equal Person.Meta.fields.subWswNodes.sourceCollection._name, 'Persons'
  test.equal Person.Meta.fields.subWswNodes.targetCollection._name, 'wNodes'
  test.equal Person.Meta.fields.subWswNodes.sourceW.Meta.collection._name, 'Persons'
  test.equal Person.Meta.fields.subWswNodes.targetW.Meta.collection._name, 'wNodes'
  test.equal Person.Meta.fields.subWswNodes.fields, ['body', 'subW.body', 'nested.body']
  test.isNull Person.Meta.fields.subWswNodes.reverseName
  test.equal Person.Meta.fields.subWswNodes.reverseFields, []

  test.equal SpecialPerson.Meta._name, 'SpecialPerson'
  test.equal SpecialPerson.Meta.parent, Person.Meta
  test.equal SpecialPerson.Meta.W, SpecialPerson
  test.equal SpecialPerson.Meta._name, 'SpecialPerson'
  test.equal SpecialPerson.Meta.collection._name, 'SpecialPersons'
  test.equal _.size(SpecialPerson.Meta.triggers), 0
  test.equal _.size(SpecialPerson.Meta.fields), 0

  test.equal Recursive.Meta._name, 'Recursive'
  test.isFalse Recursive.Meta.parent
  test.equal Recursive.Meta.W, Recursive
  test.equal Recursive.Meta.collection._name, 'Recursives'
  test.equal _.size(Recursive.Meta.triggers), 0
  test.equal _.size(Recursive.Meta.fields), 2
  test.instanceOf Recursive.Meta.fields.other, Recursive._ReferenceField
  test.isNull Recursive.Meta.fields.other.ancestorArray, Recursive.Meta.fields.other.ancestorArray
  test.isFalse Recursive.Meta.fields.other.required
  test.equal Recursive.Meta.fields.other.sourcePath, 'other'
  test.equal Recursive.Meta.fields.other.sourceW, Recursive
  test.equal Recursive.Meta.fields.other.targetW, Recursive
  test.equal Recursive.Meta.fields.other.sourceCollection._name, 'Recursives'
  test.equal Recursive.Meta.fields.other.targetCollection._name, 'Recursives'
  test.equal Recursive.Meta.fields.other.sourceW.Meta.collection._name, 'Recursives'
  test.equal Recursive.Meta.fields.other.targetW.Meta.collection._name, 'Recursives'
  test.equal Recursive.Meta.fields.other.fields, ['content']
  test.equal Recursive.Meta.fields.other.reverseName, 'reverse'
  test.equal Recursive.Meta.fields.other.reverseFields, ['content']
  test.instanceOf Recursive.Meta.fields.reverse, Recursive._ReferenceField
  test.equal Recursive.Meta.fields.reverse.ancestorArray, 'reverse'
  test.isTrue Recursive.Meta.fields.reverse.required
  test.equal Recursive.Meta.fields.reverse.sourcePath, 'reverse'
  test.equal Recursive.Meta.fields.reverse.sourceW, Recursive
  test.equal Recursive.Meta.fields.reverse.targetW, Recursive
  test.equal Recursive.Meta.fields.reverse.sourceCollection._name, 'Recursives'
  test.equal Recursive.Meta.fields.reverse.targetCollection._name, 'Recursives'
  test.equal Recursive.Meta.fields.reverse.sourceW.Meta.collection._name, 'Recursives'
  test.equal Recursive.Meta.fields.reverse.targetW.Meta.collection._name, 'Recursives'
  test.equal Recursive.Meta.fields.reverse.fields, ['content']
  test.isNull Recursive.Meta.fields.reverse.reverseName
  test.equal Recursive.Meta.fields.reverse.reverseFields, []

  test.equal IdentityGenerator.Meta._name, 'IdentityGenerator'
  test.isFalse IdentityGenerator.Meta.parent
  test.equal IdentityGenerator.Meta.W, IdentityGenerator
  test.equal IdentityGenerator.Meta.collection._name, 'IdentityGenerators'
  test.equal _.size(IdentityGenerator.Meta.triggers), 0
  test.equal _.size(IdentityGenerator.Meta.fields), 2
  test.instanceOf IdentityGenerator.Meta.fields.result, IdentityGenerator._GeneratedField
  test.isNull IdentityGenerator.Meta.fields.result.ancestorArray, IdentityGenerator.Meta.fields.result.ancestorArray
  test.isTrue _.isFunction IdentityGenerator.Meta.fields.result.generator
  test.equal IdentityGenerator.Meta.fields.result.sourcePath, 'result'
  test.equal IdentityGenerator.Meta.fields.result.sourceW, IdentityGenerator
  test.equal IdentityGenerator.Meta.fields.result.targetW, IdentityGenerator
  test.equal IdentityGenerator.Meta.fields.result.sourceCollection._name, 'IdentityGenerators'
  test.equal IdentityGenerator.Meta.fields.result.targetCollection._name, 'IdentityGenerators'
  test.equal IdentityGenerator.Meta.fields.result.sourceW.Meta.collection._name, 'IdentityGenerators'
  test.equal IdentityGenerator.Meta.fields.result.targetW.Meta.collection._name, 'IdentityGenerators'
  test.equal IdentityGenerator.Meta.fields.result.fields, ['source']
  test.isUndefined IdentityGenerator.Meta.fields.result.reverseName
  test.isUndefined IdentityGenerator.Meta.fields.result.reverseFields
  test.instanceOf IdentityGenerator.Meta.fields.results, IdentityGenerator._GeneratedField
  test.equal IdentityGenerator.Meta.fields.results.ancestorArray, 'results'
  test.isTrue _.isFunction IdentityGenerator.Meta.fields.results.generator
  test.equal IdentityGenerator.Meta.fields.results.sourcePath, 'results'
  test.equal IdentityGenerator.Meta.fields.results.sourceW, IdentityGenerator
  test.equal IdentityGenerator.Meta.fields.results.targetW, IdentityGenerator
  test.equal IdentityGenerator.Meta.fields.results.sourceCollection._name, 'IdentityGenerators'
  test.equal IdentityGenerator.Meta.fields.results.targetCollection._name, 'IdentityGenerators'
  test.equal IdentityGenerator.Meta.fields.results.sourceW.Meta.collection._name, 'IdentityGenerators'
  test.equal IdentityGenerator.Meta.fields.results.targetW.Meta.collection._name, 'IdentityGenerators'
  test.equal IdentityGenerator.Meta.fields.results.fields, ['source']
  test.isUndefined IdentityGenerator.Meta.fields.results.reverseName
  test.isUndefined IdentityGenerator.Meta.fields.results.reverseFields

  test.equal SpecialwNode.Meta._name, 'SpecialwNode'
  test.equal SpecialwNode.Meta.parent, _TestwNode2.Meta
  test.equal SpecialwNode.Meta.W, SpecialwNode
  test.equal SpecialwNode.Meta.collection._name, 'SpecialwNodes'
  test.equal _.size(SpecialwNode.Meta.triggers), 1
  test.instanceOf SpecialwNode.Meta.triggers.testTrigger, SpecialwNode._Trigger
  test.equal SpecialwNode.Meta.triggers.testTrigger.name, 'testTrigger'
  test.equal SpecialwNode.Meta.triggers.testTrigger.W, SpecialwNode
  test.equal SpecialwNode.Meta.triggers.testTrigger.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.triggers.testTrigger.fields, ['body']
  test.equal _.size(SpecialwNode.Meta.fields), 8
  test.instanceOf SpecialwNode.Meta.fields.author, SpecialwNode._ReferenceField
  test.isNull SpecialwNode.Meta.fields.author.ancestorArray, SpecialwNode.Meta.fields.author.ancestorArray
  test.isTrue SpecialwNode.Meta.fields.author.required
  test.equal SpecialwNode.Meta.fields.author.sourcePath, 'author'
  test.equal SpecialwNode.Meta.fields.author.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.author.targetW, Person
  test.equal SpecialwNode.Meta.fields.author.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.author.targetCollection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.author.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.author.targetW.Meta.collection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.author.fields, ['username', 'displayName', 'field1', 'field2']
  test.equal SpecialwNode.Meta.fields.author.reverseName, 'wNodes'
  test.equal SpecialwNode.Meta.fields.author.reverseFields, ['body', 'subW.body', 'nested.body']
  test.instanceOf SpecialwNode.Meta.fields.subscribers, SpecialwNode._ReferenceField
  test.equal SpecialwNode.Meta.fields.subscribers.ancestorArray, 'subscribers'
  test.isTrue SpecialwNode.Meta.fields.subscribers.required
  test.equal SpecialwNode.Meta.fields.subscribers.sourcePath, 'subscribers'
  test.equal SpecialwNode.Meta.fields.subscribers.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.subscribers.targetW, Person
  test.equal SpecialwNode.Meta.fields.subscribers.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subscribers.targetCollection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.subscribers.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subscribers.targetW.Meta.collection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.subscribers.fields, []
  test.isNull SpecialwNode.Meta.fields.subscribers.reverseName
  test.equal SpecialwNode.Meta.fields.subscribers.reverseFields, []
  test.instanceOf SpecialwNode.Meta.fields.reviewers, SpecialwNode._ReferenceField
  test.equal SpecialwNode.Meta.fields.reviewers.ancestorArray, 'reviewers'
  test.isTrue SpecialwNode.Meta.fields.reviewers.required
  test.equal SpecialwNode.Meta.fields.reviewers.sourcePath, 'reviewers'
  test.equal SpecialwNode.Meta.fields.reviewers.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.reviewers.targetW, Person
  test.equal SpecialwNode.Meta.fields.reviewers.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.reviewers.targetCollection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.reviewers.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.reviewers.targetW.Meta.collection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.reviewers.fields, [username: 1]
  test.isNull SpecialwNode.Meta.fields.reviewers.reverseName
  test.equal SpecialwNode.Meta.fields.reviewers.reverseFields, []
  test.equal _.size(SpecialwNode.Meta.fields.subW), 3
  test.instanceOf SpecialwNode.Meta.fields.subW.person, SpecialwNode._ReferenceField
  test.isNull SpecialwNode.Meta.fields.subW.person.ancestorArray, SpecialwNode.Meta.fields.subW.person.ancestorArray
  test.isFalse SpecialwNode.Meta.fields.subW.person.required
  test.equal SpecialwNode.Meta.fields.subW.person.sourcePath, 'subW.person'
  test.equal SpecialwNode.Meta.fields.subW.person.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.subW.person.targetW, Person
  test.equal SpecialwNode.Meta.fields.subW.person.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subW.person.targetCollection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.subW.person.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subW.person.targetW.Meta.collection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.subW.person.fields, ['username', 'displayName', 'field1', 'field2']
  test.equal SpecialwNode.Meta.fields.subW.person.reverseName, 'subWwNodes'
  test.equal SpecialwNode.Meta.fields.subW.person.reverseFields, ['body', 'subW.body', 'nested.body']
  test.instanceOf SpecialwNode.Meta.fields.subW.persons, SpecialwNode._ReferenceField
  test.equal SpecialwNode.Meta.fields.subW.persons.ancestorArray, 'subW.persons'
  test.isTrue SpecialwNode.Meta.fields.subW.persons.required
  test.equal SpecialwNode.Meta.fields.subW.persons.sourcePath, 'subW.persons'
  test.equal SpecialwNode.Meta.fields.subW.persons.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.subW.persons.targetW, Person
  test.equal SpecialwNode.Meta.fields.subW.persons.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subW.persons.targetCollection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.subW.persons.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subW.persons.targetW.Meta.collection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.subW.persons.fields, ['username', 'displayName', 'field1', 'field2']
  test.equal SpecialwNode.Meta.fields.subW.persons.reverseName, 'subWswNodes'
  test.equal SpecialwNode.Meta.fields.subW.persons.reverseFields, ['body', 'subW.body', 'nested.body']
  test.instanceOf SpecialwNode.Meta.fields.subW.slug, SpecialwNode._GeneratedField
  test.isNull SpecialwNode.Meta.fields.subW.slug.ancestorArray, SpecialwNode.Meta.fields.subW.slug.ancestorArray
  test.isTrue _.isFunction SpecialwNode.Meta.fields.subW.slug.generator
  test.equal SpecialwNode.Meta.fields.subW.slug.sourcePath, 'subW.slug'
  test.equal SpecialwNode.Meta.fields.subW.slug.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.subW.slug.targetW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.subW.slug.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subW.slug.targetCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subW.slug.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subW.slug.targetW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.subW.slug.fields, ['body', 'subW.body']
  test.isUndefined SpecialwNode.Meta.fields.subW.slug.reverseName
  test.isUndefined SpecialwNode.Meta.fields.subW.slug.reverseFields
  test.equal _.size(SpecialwNode.Meta.fields.nested), 3
  test.instanceOf SpecialwNode.Meta.fields.nested.required, SpecialwNode._ReferenceField
  test.equal SpecialwNode.Meta.fields.nested.required.ancestorArray, 'nested'
  test.isTrue SpecialwNode.Meta.fields.nested.required.required
  test.equal SpecialwNode.Meta.fields.nested.required.sourcePath, 'nested.required'
  test.equal SpecialwNode.Meta.fields.nested.required.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.nested.required.targetW, Person
  test.equal SpecialwNode.Meta.fields.nested.required.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.nested.required.targetCollection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.nested.required.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.nested.required.targetW.Meta.collection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.nested.required.fields, ['username', 'displayName', 'field1', 'field2']
  test.equal SpecialwNode.Meta.fields.nested.required.reverseName, 'nestedwNodes'
  test.equal SpecialwNode.Meta.fields.nested.required.reverseFields, ['body', 'subW.body', 'nested.body']
  test.instanceOf SpecialwNode.Meta.fields.nested.optional, SpecialwNode._ReferenceField
  test.equal SpecialwNode.Meta.fields.nested.optional.ancestorArray, 'nested'
  test.isFalse SpecialwNode.Meta.fields.nested.optional.required
  test.equal SpecialwNode.Meta.fields.nested.optional.sourcePath, 'nested.optional'
  test.equal SpecialwNode.Meta.fields.nested.optional.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.nested.optional.targetW, Person
  test.equal SpecialwNode.Meta.fields.nested.optional.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.nested.optional.targetCollection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.nested.optional.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.nested.optional.targetW.Meta.collection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.nested.optional.fields, ['username']
  test.isNull SpecialwNode.Meta.fields.nested.optional.reverseName
  test.equal SpecialwNode.Meta.fields.nested.optional.reverseFields, []
  test.instanceOf SpecialwNode.Meta.fields.nested.slug, SpecialwNode._GeneratedField
  test.equal SpecialwNode.Meta.fields.nested.slug.ancestorArray, 'nested'
  test.isTrue _.isFunction SpecialwNode.Meta.fields.nested.slug.generator
  test.equal SpecialwNode.Meta.fields.nested.slug.sourcePath, 'nested.slug'
  test.equal SpecialwNode.Meta.fields.nested.slug.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.nested.slug.targetW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.nested.slug.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.nested.slug.targetCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.nested.slug.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.nested.slug.targetW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.nested.slug.fields, ['body', 'nested.body']
  test.isUndefined SpecialwNode.Meta.fields.nested.slug.reverseName
  test.isUndefined SpecialwNode.Meta.fields.nested.slug.reverseFields
  test.instanceOf SpecialwNode.Meta.fields.slug, SpecialwNode._GeneratedField
  test.isNull SpecialwNode.Meta.fields.slug.ancestorArray, SpecialwNode.Meta.fields.slug.ancestorArray
  test.isTrue _.isFunction SpecialwNode.Meta.fields.slug.generator
  test.equal SpecialwNode.Meta.fields.slug.sourcePath, 'slug'
  test.equal SpecialwNode.Meta.fields.slug.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.slug.targetW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.slug.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.slug.targetCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.slug.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.slug.targetW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.slug.fields, ['body', 'subW.body']
  test.isUndefined SpecialwNode.Meta.fields.slug.reverseName
  test.isUndefined SpecialwNode.Meta.fields.slug.reverseFields
  test.instanceOf SpecialwNode.Meta.fields.tags, SpecialwNode._GeneratedField
  test.equal SpecialwNode.Meta.fields.tags.ancestorArray, 'tags'
  test.isTrue _.isFunction SpecialwNode.Meta.fields.tags.generator
  test.equal SpecialwNode.Meta.fields.tags.sourcePath, 'tags'
  test.equal SpecialwNode.Meta.fields.tags.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.tags.targetW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.tags.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.tags.targetCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.tags.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.tags.targetW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.tags.fields, ['body', 'subW.body', 'nested.body']
  test.isUndefined SpecialwNode.Meta.fields.tags.reverseName
  test.isUndefined SpecialwNode.Meta.fields.tags.reverseFields
  test.instanceOf SpecialwNode.Meta.fields.special, SpecialwNode._ReferenceField
  test.isNull SpecialwNode.Meta.fields.special.ancestorArray, SpecialwNode.Meta.fields.special.ancestorArray
  test.isTrue SpecialwNode.Meta.fields.special.required
  test.equal SpecialwNode.Meta.fields.special.sourcePath, 'special'
  test.equal SpecialwNode.Meta.fields.special.sourceW, SpecialwNode
  test.equal SpecialwNode.Meta.fields.special.targetW, Person
  test.equal SpecialwNode.Meta.fields.special.sourceCollection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.special.targetCollection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.special.sourceW.Meta.collection._name, 'SpecialwNodes'
  test.equal SpecialwNode.Meta.fields.special.targetW.Meta.collection._name, 'Persons'
  test.equal SpecialwNode.Meta.fields.special.fields, []
  test.isNull SpecialwNode.Meta.fields.special.reverseName
  test.equal SpecialwNode.Meta.fields.special.reverseFields, []

  testWList test, ALL

plainObject = (obj) ->
  return obj unless _.isObject obj

  return (plainObject o for o in obj) if _.isArray obj

  keys = _.keys obj
  values = (plainObject o for o in _.values obj)

  _.object keys, values

testAsyncMulti 'peerdb - references', [
  (test, expect) ->
    testDefinition test

    # We should be able to call defineAll multiple times
    W.defineAll()

    testDefinition test

    Person.Ws.insert
      username: 'person1'
      displayName: 'Person 1'
      field1: 'Field 1 - 1'
      field2: 'Field 1 - 2'
    ,
      expect (error, person1Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person1Id
        @person1Id = person1Id

    Person.Ws.insert
      username: 'person2'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
    ,
      expect (error, person2Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person2Id
        @person2Id = person2Id

    Person.Ws.insert
      username: 'person3'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
    ,
      expect (error, person3Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person3Id
        @person3Id = person3Id

    # Wait so that observers have time to run (but no wNode is yet made, so nothing really happens).
    # We want to wait here so that we catch possible errors in source observers, otherwise target
    # observers can patch things up. For example, if we create a wNode first and target observers
    # (triggered by person inserts, but pending) run afterwards, then they can patch things which
    # should in fact be done by source observers (on wNode), like setting usernames in wNode's
    # references to persons.
    waitForDatabase test, expect
,
  (test, expect) ->
    # Should work also with no argument (defaults to {}).
    test.isTrue Person.Ws.exists()
    test.isTrue Person.Ws.find().exists()

    test.isTrue Person.Ws.exists @person1Id
    test.isTrue Person.Ws.exists @person2Id
    test.isTrue Person.Ws.exists @person3Id

    test.isTrue Person.Ws.find(@person1Id).exists()
    test.isTrue Person.Ws.find(@person2Id).exists()
    test.isTrue Person.Ws.find(@person3Id).exists()

    test.equal Person.Ws.find({_id: $in: [@person1Id, @person2Id, @person3Id]}).count(), 3

    # Test without skip and limit.
    test.isTrue Person.Ws.exists({_id: $in: [@person1Id, @person2Id, @person3Id]})
    test.isTrue Person.Ws.find({_id: $in: [@person1Id, @person2Id, @person3Id]}).exists()

    # With sorting. We are testing all this combinations because there are various code paths.
    test.isTrue Person.Ws.exists({_id: $in: [@person1Id, @person2Id, @person3Id]}, {sort: [['username', 'asc']]})
    test.isTrue Person.Ws.find({_id: $in: [@person1Id, @person2Id, @person3Id]}, {sort: [['username', 'asc']]}).exists()

    # Test with skip and limit.
    # This behaves differently than .count() on the server because on the server
    # applySkipLimit is not set. But exists do respect skip and limit.
    test.isTrue Person.Ws.exists({_id: $in: [@person1Id, @person2Id, @person3Id]}, {skip: 2, limit: 1})
    test.isTrue Person.Ws.find({_id: $in: [@person1Id, @person2Id, @person3Id]}, {skip: 2, limit: 1}).exists()
    test.isFalse Person.Ws.exists({_id: $in: [@person1Id, @person2Id, @person3Id]}, {skip: 3, limit: 1})
    test.isFalse Person.Ws.find({_id: $in: [@person1Id, @person2Id, @person3Id]}, {skip: 3, limit: 1}).exists()

    test.isTrue Person.Ws.exists({_id: $in: [@person1Id, @person2Id, @person3Id]}, {skip: 2, limit: 1, sort: [['username', 'asc']]})
    test.isTrue Person.Ws.find({_id: $in: [@person1Id, @person2Id, @person3Id]}, {skip: 2, limit: 1, sort: [['username', 'asc']]}).exists()
    test.isFalse Person.Ws.exists({_id: $in: [@person1Id, @person2Id, @person3Id]}, {skip: 3, limit: 1, sort: [['username', 'asc']]})
    test.isFalse Person.Ws.find({_id: $in: [@person1Id, @person2Id, @person3Id]}, {skip: 3, limit: 1, sort: [['username', 'asc']]}).exists()

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      field1: 'Field 1 - 1'
      field2: 'Field 1 - 2'
      count: 0
    test.equal @person2,
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
      count: 0
    test.equal @person3,
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      count: 0

    wNode.Ws.insert
      author:
        _id: @person1._id
        # To test what happens if all fields are not up to date
        username: 'wrong'
        displayName: 'wrong'
        field1: 'wrong'
        field2: 'wrong'
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: 'wrong'
      ,
        _id: @person3._id
        username: 'wrong'
      ]
      subW:
        person:
          _id: @person2._id
          username: 'wrong'
        persons: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: 'wrong'
          displayName: 'wrong'
        optional:
          _id: @person3._id
          username: 'wrong'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId = wNodeId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    # We inserted the W only with ids - subWs should be
    # automatically populated with additional fields as defined in @ReferenceField
    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      # subscribers have only ids
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      # But reviewers have usernames as well
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.update @person1Id,
      $set:
        username: 'person1a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    Person.Ws.update @person2Id,
      $set:
        username: 'person2a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    # so that persons updates are not merged together to better
    # test the code for multiple updates
    waitForDatabase test, expect
,
  (test, expect) ->
    Person.Ws.update @person3Id,
      $set:
        username: 'person3a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1a'
      displayName: 'Person 1'
      field1: 'Field 1 - 1'
      field2: 'Field 1 - 2'
      wNodes: [
        _id: @wNodeId
        body: 'FooBar'
        nested: [
          body: 'NestedFooBar'
        ]
        subW:
          body: 'SubWFooBar'
      ]
      count: 1
    test.equal @person2,
      _id: @person2Id
      username: 'person2a'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
      subWwNodes: [
        _id: @wNodeId
        body: 'FooBar'
        nested: [
          body: 'NestedFooBar'
        ]
        subW:
          body: 'SubWFooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        body: 'FooBar'
        nested: [
          body: 'NestedFooBar'
        ]
        subW:
          body: 'SubWFooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        body: 'FooBar'
        nested: [
          body: 'NestedFooBar'
        ]
        subW:
          body: 'SubWFooBar'
      ]
      count: 3
    test.equal @person3,
      _id: @person3Id
      username: 'person3a'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        body: 'FooBar'
        nested: [
          body: 'NestedFooBar'
        ]
        subW:
          body: 'SubWFooBar'
      ]
      count: 1

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    # All persons had usernames changed, they should
    # be updated in the wNode as well, automatically
    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.remove @person3Id,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    # person3 was removed, references should be removed as well, automatically
    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional: null
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.remove @person2Id,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    # person2 was removed, references should be removed as well, automatically,
    # but lists should be kept as empty lists
    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: []
      reviewers: []
      subW:
        person: null
        persons: []
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: []
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
      ]

    Person.Ws.remove @person1Id,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    # If directly referenced W is removed, dependency is removed as well
    test.isFalse @wNode, @wNode
]

Tinytest.add 'peerdb - invalid optional', (test) ->
  test.throws ->
    class BadwNode1 extends W
      @Meta
        name: 'BadwNode1'
        fields: =>
          reviewers: [@ReferenceField Person, ['username'], false]
  , /Reference field directly in an array cannot be optional/

  # Invalid W should not be added to the list
  testWList test, ALL

  # Should not try to define invalid W again
  W.defineAll()

Tinytest.add 'peerdb - invalid nested arrays', (test) ->
  test.throws ->
    class BadwNode2 extends W
      @Meta
        name: 'BadwNode2'
        fields: =>
          nested: [
            many: [@ReferenceField Person, ['username']]
          ]
  , /Field cannot be in a nested array/

  # Invalid W should not be added to the list
  testWList test, ALL

  # Should not try to define invalid W again
  W.defineAll()

unless CODE_MINIMIZED
  Tinytest.add 'peerdb - invalid name', (test) ->
    test.throws ->
      class BadwNode3 extends W
        @Meta
          name: 'wNode'
    , /W name does not match class name/

    # Invalid W should not be added to the list
    testWList test, ALL

    # Should not try to define invalid W again
    W.defineAll()

Tinytest.add 'peerdb - abstract with parent', (test) ->
  test.throws ->
    class BadwNode4 extends wNode
      @Meta
        abstract: true
  , /Abstract W with a parent/

  # Invalid W should not be added to the list
  testWList test, ALL

  # Should not try to define invalid W again
  W.defineAll()

testAsyncMulti 'peerdb - circular changes', [
  (test, expect) ->
    Log._intercept 3 if Meteor.isServer and W.instances is 1 # Three to see if we catch more than expected

    CircularFirst.Ws.insert
      second: null
      content: 'FooBar 1'
    ,
      expect (error, circularFirstId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue circularFirstId
        @circularFirstId = circularFirstId

    CircularSecond.Ws.insert
      first: null
      content: 'FooBar 2'
    ,
      expect (error, circularSecondId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue circularSecondId
        @circularSecondId = circularSecondId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    if Meteor.isServer and W.instances is 1
      intercepted = Log._intercepted()

      # One or two because it depends if the client tests are running at the same time
      test.isTrue 1 <= intercepted.length <= 2, intercepted

      # We are testing only the server one, so let's find it
      for i in intercepted
        break if i.indexOf(@circularFirstId) isnt -1
      test.isTrue _.isString(i), i
      intercepted = EJSON.parse i

      test.equal intercepted.message, "W 'CircularFirst' '#{ @circularFirstId }' field 'second' was updated with an invalid value: null"
      test.equal intercepted.level, 'error'

    @circularFirst = CircularFirst.Ws.findOne @circularFirstId,
      transform: null # So that we can use test.equal
    @circularSecond = CircularSecond.Ws.findOne @circularSecondId,
      transform: null # So that we can use test.equal

    test.equal @circularFirst,
      _id: @circularFirstId
      second: null
      content: 'FooBar 1'
    test.equal @circularSecond,
      _id: @circularSecondId
      first: null
      content: 'FooBar 2'

    CircularFirst.Ws.update @circularFirstId,
      $set:
        second:
          _id: @circularSecondId
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @circularFirst = CircularFirst.Ws.findOne @circularFirstId,
      transform: null # So that we can use test.equal
    @circularSecond = CircularSecond.Ws.findOne @circularSecondId,
      transform: null # So that we can use test.equal

    test.equal @circularFirst,
      _id: @circularFirstId
      second:
        _id: @circularSecondId
        content: 'FooBar 2'
      content: 'FooBar 1'
    test.equal @circularSecond,
      _id: @circularSecondId
      first: null
      content: 'FooBar 2'
      reverseFirsts: [
        _id: @circularFirstId
        content: 'FooBar 1'
      ]

    CircularSecond.Ws.update @circularSecondId,
      $set:
        first:
          _id: @circularFirstId
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @circularFirst = CircularFirst.Ws.findOne @circularFirstId,
      transform: null # So that we can use test.equal
    @circularSecond = CircularSecond.Ws.findOne @circularSecondId,
      transform: null # So that we can use test.equal

    test.equal @circularFirst,
      _id: @circularFirstId
      second:
        _id: @circularSecondId
        content: 'FooBar 2'
      content: 'FooBar 1'
      reverseSeconds: [
        _id: @circularSecondId
        content: 'FooBar 2'
      ]
    test.equal @circularSecond,
      _id: @circularSecondId
      first:
        _id: @circularFirstId
        content: 'FooBar 1'
      content: 'FooBar 2'
      reverseFirsts: [
        _id: @circularFirstId
        content: 'FooBar 1'
      ]

    CircularFirst.Ws.update @circularFirstId,
      $set:
        content: 'FooBar 1a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @circularFirst = CircularFirst.Ws.findOne @circularFirstId,
      transform: null # So that we can use test.equal
    @circularSecond = CircularSecond.Ws.findOne @circularSecondId,
      transform: null # So that we can use test.equal

    test.equal @circularFirst,
      _id: @circularFirstId
      second:
        _id: @circularSecondId
        content: 'FooBar 2'
      content: 'FooBar 1a'
      reverseSeconds: [
        _id: @circularSecondId
        content: 'FooBar 2'
      ]
    test.equal @circularSecond,
      _id: @circularSecondId
      first:
        _id: @circularFirstId
        content: 'FooBar 1a'
      content: 'FooBar 2'
      reverseFirsts: [
        _id: @circularFirstId
        content: 'FooBar 1a'
      ]

    CircularSecond.Ws.update @circularSecondId,
      $set:
        content: 'FooBar 2a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @circularFirst = CircularFirst.Ws.findOne @circularFirstId,
      transform: null # So that we can use test.equal
    @circularSecond = CircularSecond.Ws.findOne @circularSecondId,
      transform: null # So that we can use test.equal

    test.equal @circularFirst,
      _id: @circularFirstId
      second:
        _id: @circularSecondId
        content: 'FooBar 2a'
      content: 'FooBar 1a'
      reverseSeconds: [
        _id: @circularSecondId
        content: 'FooBar 2a'
      ]
    test.equal @circularSecond,
      _id: @circularSecondId
      first:
        _id: @circularFirstId
        content: 'FooBar 1a'
      content: 'FooBar 2a'
      reverseFirsts: [
        _id: @circularFirstId
        content: 'FooBar 1a'
      ]

    CircularSecond.Ws.remove @circularSecondId,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @circularFirst = CircularFirst.Ws.findOne @circularFirstId,
      transform: null # So that we can use test.equal
    @circularSecond = CircularSecond.Ws.findOne @circularSecondId,
      transform: null # So that we can use test.equal

    test.isFalse @circularSecond, @circularSecond

    # If directly referenced W is removed, dependency is removed as well
    test.isFalse @circularFirst, @circularFirst

    Log._intercept 1 if Meteor.isServer and W.instances is 1

    CircularSecond.Ws.insert
      first: null
      content: 'FooBar 2'
    ,
      expect (error, circularSecondId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue circularSecondId
        @circularSecondId = circularSecondId
,
  (test, expect) ->
    CircularFirst.Ws.insert
      second:
        _id: @circularSecondId
      content: 'FooBar 1'
    ,
      expect (error, circularFirstId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue circularFirstId
        @circularFirstId = circularFirstId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    if Meteor.isServer and W.instances is 1
      intercepted = Log._intercepted()

      test.equal intercepted.length, 0, intercepted

    @circularFirst = CircularFirst.Ws.findOne @circularFirstId,
      transform: null # So that we can use test.equal
    @circularSecond = CircularSecond.Ws.findOne @circularSecondId,
      transform: null # So that we can use test.equal

    test.equal @circularFirst,
      _id: @circularFirstId
      second:
        _id: @circularSecondId
        content: 'FooBar 2'
      content: 'FooBar 1'
    test.equal @circularSecond,
      _id: @circularSecondId
      first: null
      content: 'FooBar 2'
      reverseFirsts: [
        _id: @circularFirstId
        content: 'FooBar 1'
      ]

    CircularSecond.Ws.update @circularSecondId,
      $set:
        first:
          _id: @circularFirstId
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @circularFirst = CircularFirst.Ws.findOne @circularFirstId,
      transform: null # So that we can use test.equal
    @circularSecond = CircularSecond.Ws.findOne @circularSecondId,
      transform: null # So that we can use test.equal

    test.equal @circularFirst,
      _id: @circularFirstId
      second:
        _id: @circularSecondId
        content: 'FooBar 2'
      content: 'FooBar 1'
      reverseSeconds: [
        _id: @circularSecondId
        content: 'FooBar 2'
      ]
    test.equal @circularSecond,
      _id: @circularSecondId
      first:
        _id: @circularFirstId
        content: 'FooBar 1'
      content: 'FooBar 2'
      reverseFirsts: [
        _id: @circularFirstId
        content: 'FooBar 1'
      ]

    CircularFirst.Ws.remove @circularFirstId,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update W
    waitForDatabase test, expect
,
  (test, expect) ->
    @circularFirst = CircularFirst.Ws.findOne @circularFirstId,
      transform: null # So that we can use test.equal
    @circularSecond = CircularSecond.Ws.findOne @circularSecondId,
      transform: null # So that we can use test.equal

    test.isFalse @circularFirst, @circularFirst

    # If directly referenced but optional W is removed, dependency is not removed as well, but set to null
    test.equal @circularSecond,
      _id: @circularSecondId
      first: null
      content: 'FooBar 2'
      reverseFirsts: []
]

testAsyncMulti 'peerdb - recursive two', [
  (test, expect) ->
    Recursive.Ws.insert
      other: null
      content: 'FooBar 1'
    ,
      expect (error, recursive1Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue recursive1Id
        @recursive1Id = recursive1Id

    Recursive.Ws.insert
      other: null
      content: 'FooBar 2'
    ,
      expect (error, recursive2Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue recursive2Id
        @recursive2Id = recursive2Id

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive1 = Recursive.Ws.findOne @recursive1Id,
      transform: null # So that we can use test.equal
    @recursive2 = Recursive.Ws.findOne @recursive2Id,
      transform: null # So that we can use test.equal

    test.equal @recursive1,
      _id: @recursive1Id
      other: null
      content: 'FooBar 1'
    test.equal @recursive2,
      _id: @recursive2Id
      other: null
      content: 'FooBar 2'

    Recursive.Ws.update @recursive1Id,
      $set:
        other:
          _id: @recursive2Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive1 = Recursive.Ws.findOne @recursive1Id,
      transform: null # So that we can use test.equal
    @recursive2 = Recursive.Ws.findOne @recursive2Id,
      transform: null # So that we can use test.equal

    test.equal @recursive1,
      _id: @recursive1Id
      other:
        _id: @recursive2Id
        content: 'FooBar 2'
      content: 'FooBar 1'
    test.equal @recursive2,
      _id: @recursive2Id
      other: null
      content: 'FooBar 2'
      reverse: [
        _id: @recursive1Id
        content: 'FooBar 1'
      ]

    Recursive.Ws.update @recursive2Id,
      $set:
        other:
          _id: @recursive1Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive1 = Recursive.Ws.findOne @recursive1Id,
      transform: null # So that we can use test.equal
    @recursive2 = Recursive.Ws.findOne @recursive2Id,
      transform: null # So that we can use test.equal

    test.equal @recursive1,
      _id: @recursive1Id
      other:
        _id: @recursive2Id
        content: 'FooBar 2'
      content: 'FooBar 1'
      reverse: [
        _id: @recursive2Id
        content: 'FooBar 2'
      ]
    test.equal @recursive2,
      _id: @recursive2Id
      other:
        _id: @recursive1Id
        content: 'FooBar 1'
      content: 'FooBar 2'
      reverse: [
        _id: @recursive1Id
        content: 'FooBar 1'
      ]

    Recursive.Ws.update @recursive1Id,
      $set:
        content: 'FooBar 1a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive1 = Recursive.Ws.findOne @recursive1Id,
      transform: null # So that we can use test.equal
    @recursive2 = Recursive.Ws.findOne @recursive2Id,
      transform: null # So that we can use test.equal

    test.equal @recursive1,
      _id: @recursive1Id
      other:
        _id: @recursive2Id
        content: 'FooBar 2'
      content: 'FooBar 1a'
      reverse: [
        _id: @recursive2Id
        content: 'FooBar 2'
      ]
    test.equal @recursive2,
      _id: @recursive2Id
      other:
        _id: @recursive1Id
        content: 'FooBar 1a'
      content: 'FooBar 2'
      reverse: [
        _id: @recursive1Id
        content: 'FooBar 1a'
      ]

    Recursive.Ws.update @recursive2Id,
      $set:
        content: 'FooBar 2a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive1 = Recursive.Ws.findOne @recursive1Id,
      transform: null # So that we can use test.equal
    @recursive2 = Recursive.Ws.findOne @recursive2Id,
      transform: null # So that we can use test.equal

    test.equal @recursive1,
      _id: @recursive1Id
      other:
        _id: @recursive2Id
        content: 'FooBar 2a'
      content: 'FooBar 1a'
      reverse: [
        _id: @recursive2Id
        content: 'FooBar 2a'
      ]
    test.equal @recursive2,
      _id: @recursive2Id
      other:
        _id: @recursive1Id
        content: 'FooBar 1a'
      content: 'FooBar 2a'
      reverse: [
        _id: @recursive1Id
        content: 'FooBar 1a'
      ]

    Recursive.Ws.remove @recursive2Id,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive1 = Recursive.Ws.findOne @recursive1Id,
      transform: null # So that we can use test.equal
    @recursive2 = Recursive.Ws.findOne @recursive2Id,
      transform: null # So that we can use test.equal

    test.isFalse @recursive2, @recursive2

    test.equal @recursive1,
      _id: @recursive1Id
      other: null
      content: 'FooBar 1a'
      reverse: []
]

testAsyncMulti 'peerdb - recursive one', [
  (test, expect) ->
    Recursive.Ws.insert
      other: null
      content: 'FooBar'
    ,
      expect (error, recursiveId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue recursiveId
        @recursiveId = recursiveId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive = Recursive.Ws.findOne @recursiveId,
      transform: null # So that we can use test.equal

    test.equal @recursive,
      _id: @recursiveId
      other: null
      content: 'FooBar'

    Recursive.Ws.update @recursiveId,
      $set:
        other:
          _id: @recursiveId
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive = Recursive.Ws.findOne @recursiveId,
      transform: null # So that we can use test.equal

    test.equal @recursive,
      _id: @recursiveId
      other:
        _id: @recursiveId
        content: 'FooBar'
      content: 'FooBar'
      reverse: [
        _id: @recursiveId
        content: 'FooBar'
      ]

    Recursive.Ws.update @recursiveId,
      $set:
        content: 'FooBara'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive = Recursive.Ws.findOne @recursiveId,
      transform: null # So that we can use test.equal

    test.equal @recursive,
      _id: @recursiveId
      other:
        _id: @recursiveId
        content: 'FooBara'
      content: 'FooBara'
      reverse: [
        _id: @recursiveId
        content: 'FooBara'
      ]

    Recursive.Ws.remove @recursiveId,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @recursive = Recursive.Ws.findOne @recursiveId,
      transform: null # So that we can use test.equal

    test.isFalse @recursive, @recursive
]

if Meteor.isServer and W.instances is 1
  Tinytest.add 'peerdb - errors', (test) ->
    Log._intercept 2 # Two to see if we catch more than expected

    wNodeId = wNode.Ws.insert
      author:
        _id: 'nonexistent'

    # Wait so that observers have time to update Ws
    Meteor.call 'wait-for-database'

    intercepted = Log._intercepted()

    test.equal intercepted.length, 1, intercepted

    test.isTrue _.isString(intercepted[0]), intercepted[0]
    intercepted = EJSON.parse intercepted[0]

    test.equal intercepted.message, "W 'wNode' '#{ wNodeId }' field 'author' is referencing a nonexistent W 'nonexistent'"
    test.equal intercepted.level, 'error'

    Log._intercept 2 # Two to see if we catch more than expected

    wNodeId = wNode.Ws.insert
      subscribers: 'foobar'

    # Wait so that observers have time to update Ws
    Meteor.call 'wait-for-database'

    intercepted = Log._intercepted()

    test.equal intercepted.length, 1, intercepted

    test.isTrue _.isString(intercepted[0]), intercepted[0]
    intercepted = EJSON.parse intercepted[0]

    test.equal intercepted.message, "W 'wNode' '#{ wNodeId }' field 'subscribers' was updated with a non-array value: 'foobar'"
    test.equal intercepted.level, 'error'

    Log._intercept 2 # Two to see if we catch more than expected

    wNodeId = wNode.Ws.insert
      author: null

    # Wait so that observers have time to update Ws
    Meteor.call 'wait-for-database'

    intercepted = Log._intercepted()

    test.equal intercepted.length, 1, intercepted

    test.isTrue _.isString(intercepted[0]), intercepted[0]
    intercepted = EJSON.parse intercepted[0]

    test.equal intercepted.message, "W 'wNode' '#{ wNodeId }' field 'author' was updated with an invalid value: null"
    test.equal intercepted.level, 'error'

    Log._intercept 1

    userLinkId = UserLink.Ws.insert
      user: null

    # Wait so that observers have time to update Ws
    Meteor.call 'wait-for-database'

    intercepted = Log._intercepted()

    # There should be no warning because user is optional
    test.equal intercepted.length, 0, intercepted

testAsyncMulti 'peerdb - delayed defintion', [
  (test, expect) ->
    class BadwNode5 extends W
      @Meta
        name: 'BadwNode5'
        fields: =>
          author: @ReferenceField undefined, ['username']

    Log._intercept 2 # Two to see if we catch more than expected

    # Sleep so that error is shown
    Meteor.setTimeout expect(), 1000 # We need 1000 here because we have a check which runs after 1000 ms to check for delayed definitions
,
  (test, expect) ->
    intercepted = Log._intercepted()

    # One or two because we could intercepted something else as well
    test.isTrue 1 <= intercepted.length <= 2, intercepted

    # Let's find it
    for i in intercepted
      break if i.indexOf('BadwNode5') isnt -1
    test.isTrue _.isString(i), i
    intercepted = EJSON.parse i

    test.equal intercepted.message.lastIndexOf("Not all delayed W definitions were successfully retried:\nBadwNode5 from"), 0, intercepted.message
    test.equal intercepted.level, 'error'

    testWList test, ALL
    test.equal W._delayed.length, 1

    # Clear delayed so that we can retry tests without errors
    W._delayed = []
    W._clearDelayedCheck()
]

testAsyncMulti 'peerdb - subW fields', [
  (test, expect) ->
    Person.Ws.insert
      username: 'person1'
      displayName: 'Person 1'
      field1: 'Field 1 - 1'
      field2: 'Field 1 - 2'
    ,
      expect (error, person1Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person1Id
        @person1Id = person1Id

    Person.Ws.insert
      username: 'person2'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
    ,
      expect (error, person2Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person2Id
        @person2Id = person2Id

    Person.Ws.insert
      username: 'person3'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
    ,
      expect (error, person3Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person3Id
        @person3Id = person3Id

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      field1: 'Field 1 - 1'
      field2: 'Field 1 - 2'
      count: 0
    test.equal @person2,
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
      count: 0
    test.equal @person3,
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      count: 0

    wNode.Ws.insert
      author:
        _id: @person1._id
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      subW:
        person:
          _id: @person2._id
        persons: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
        optional:
          _id: @person3._id
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId = wNodeId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
      ]

    wNodeLink.Ws.insert
      wNode:
        _id: @wNode._id
    ,
      expect (error, wNodeLinkId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeLinkId
        @wNodeLinkId = wNodeLinkId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNodeLink = wNodeLink.Ws.findOne @wNodeLinkId,
      transform: null # So that we can use test.equal

    test.equal @wNodeLink,
      _id: @wNodeLinkId
      wNode:
        _id: @wNode._id
        subW:
          person:
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
            field1: @person2.field1
            field2: @person2.field2
          persons: [
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
            field1: @person2.field1
            field2: @person2.field2
          ,
            _id: @person3._id
            username: @person3.username
            displayName: @person3.displayName
            field1: @person3.field1
            field2: @person3.field2
          ]

    Person.Ws.update @person2Id,
      $set:
        username: 'person2a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal

    test.equal @person2,
      _id: @person2Id
      username: 'person2a'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
      subWwNodes: [
        _id: @wNodeId
        body: 'FooBar'
        nested: [
          body: 'NestedFooBar'
        ]
        subW:
          body: 'SubWFooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        body: 'FooBar'
        nested: [
          body: 'NestedFooBar'
        ]
        subW:
          body: 'SubWFooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        body: 'FooBar'
        nested: [
          body: 'NestedFooBar'
        ]
        subW:
          body: 'SubWFooBar'
      ]
      count: 3

    @wNodeLink = wNodeLink.Ws.findOne @wNodeLinkId,
      transform: null # So that we can use test.equal

    test.equal @wNodeLink,
      _id: @wNodeLinkId
      wNode:
        _id: @wNode._id
        subW:
          person:
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
            field1: @person2.field1
            field2: @person2.field2
          persons: [
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
            field1: @person2.field1
            field2: @person2.field2
          ,
            _id: @person3._id
            username: @person3.username
            displayName: @person3.displayName
            field1: @person3.field1
            field2: @person3.field2
          ]

    Person.Ws.remove @person2Id,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNodeLink = wNodeLink.Ws.findOne @wNodeLinkId,
      transform: null # So that we can use test.equal

    test.equal @wNodeLink,
      _id: @wNodeLinkId
      wNode:
        _id: @wNode._id
        subW:
          person: null
          persons: [
            _id: @person3._id
            username: @person3.username
            displayName: @person3.displayName
            field1: @person3.field1
            field2: @person3.field2
          ]

    wNode.Ws.remove @wNode._id,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNodeLink = wNodeLink.Ws.findOne @wNodeLinkId,
      transform: null # So that we can use test.equal

    test.isFalse @wNodeLink, @wNodeLink
]

testAsyncMulti 'peerdb - generated fields', [
  (test, expect) ->
    Person.Ws.insert
      username: 'person1'
      displayName: 'Person 1'
    ,
      expect (error, person1Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person1Id
        @person1Id = person1Id

    Person.Ws.insert
      username: 'person2'
      displayName: 'Person 2'
    ,
      expect (error, person2Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person2Id
        @person2Id = person2Id

    Person.Ws.insert
      username: 'person3'
      displayName: 'Person 3'
    ,
      expect (error, person3Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person3Id
        @person3Id = person3Id

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 0
    test.equal @person2,
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 0
    test.equal @person3,
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 0

    wNode.Ws.insert
      author:
        _id: @person1._id
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      subW:
        person:
          _id: @person2._id
        persons: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
        optional:
          _id: @person3._id
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId = wNodeId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $set:
        body: 'FooBarZ'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    # so that persons updates are not merged together to better
    # test the code for multiple updates
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    # All persons had usernames changed, they should
    # be updated in the wNode as well, automatically
    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
        ]
        slug: 'subW-prefix-foobarz-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBarZ'
      slug: 'prefix-foobarz-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobarz-subWfoobar-suffix'
        'tag-1-prefix-foobarz-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $set:
        'subW.body': 'SubWFooBarZ'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    # so that persons updates are not merged together to better
    # test the code for multiple updates
    waitForDatabase test, expect
,
   (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    # All persons had usernames changed, they should
    # be updated in the wNode as well, automatically
    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
        ]
        slug: 'subW-prefix-foobarz-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBarZ'
      slug: 'prefix-foobarz-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobarz-subWfoobarz-suffix'
        'tag-1-prefix-foobarz-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $set:
        'nested.0.body': 'NestedFooBarZ'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    # so that persons updates are not merged together to better
    # test the code for multiple updates
    waitForDatabase test, expect
,
   (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    # All persons had usernames changed, they should
    # be updated in the wNode as well, automatically
    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
        ]
        slug: 'subW-prefix-foobarz-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobarz-suffix'
        body: 'NestedFooBarZ'
      ]
      body: 'FooBarZ'
      slug: 'prefix-foobarz-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobarz-subWfoobarz-suffix'
        'tag-1-prefix-foobarz-nestedfoobarz-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $set:
        body: null
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
        ]
        slug: null
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        slug: null
        body: 'NestedFooBarZ'
      ]
      body: null
      slug: null
      tags: []

    wNode.Ws.update @wNodeId,
      $unset:
        body: ''
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
        ]
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        body: 'NestedFooBarZ'
      ]
      tags: []
]

Tinytest.add 'peerdb - chain of extended classes', (test) ->
  list = _.clone W.list

  firstReferenceA = undefined # To force delayed
  secondReferenceA = undefined # To force delayed
  firstReferenceB = undefined # To force delayed
  secondReferenceB = undefined # To force delayed

  class First extends W
    @Meta
      name: 'First'
      fields: =>
        first: @ReferenceField firstReferenceA

  class Second extends First
    @Meta
      name: 'Second'
      fields: (fields) =>
        fields.second = @ReferenceField wNode # Not undefined, but overall meta will still be delayed
        fields

  class Third extends Second
    @Meta
      name: 'Third'
      fields: (fields) =>
        fields.third = @ReferenceField secondReferenceA
        fields

  testWList test, ALL
  test.equal W._delayed.length, 3
  test.equal W._delayed[0], First
  test.equal W._delayed[1], Second
  test.equal W._delayed[2], Third

  _TestFirst = First

  class First extends First
    @Meta
      name: 'First'
      replaceParent: true
      fields: (fields) =>
        fields.first = @ReferenceField firstReferenceB
        fields

  _TestSecond = Second

  class Second extends Second
    @Meta
      name: 'Second'
      replaceParent: true
      fields: (fields) =>
        fields.second = @ReferenceField Person # Not undefined, but overall meta will still be delayed
        fields

  _TestThird = Third

  class Third extends Third
    @Meta
      name: 'Third'
      replaceParent: true
      fields: (fields) =>
        fields.third = @ReferenceField secondReferenceB
        fields

  testWList test, ALL
  test.equal W._delayed.length, 6
  test.equal W._delayed[0], _TestFirst
  test.equal W._delayed[1], _TestSecond
  test.equal W._delayed[2], _TestThird
  test.equal W._delayed[3], First
  test.equal W._delayed[4], Second
  test.equal W._delayed[5], Third

  _TestThird2 = Third

  class Third extends Third
    @Meta
      name: 'Third'
      replaceParent: true
      fields: (fields) =>
        fields.third = @ReferenceField Person
        fields

  testWList test, ALL
  test.equal W._delayed.length, 7
  test.equal W._delayed[0], _TestFirst
  test.equal W._delayed[1], _TestSecond
  test.equal W._delayed[2], _TestThird
  test.equal W._delayed[3], First
  test.equal W._delayed[4], Second
  test.equal W._delayed[5], _TestThird2
  test.equal W._delayed[6], Third

  _TestFirst2 = First

  class First extends First
    @Meta
      name: 'First'
      replaceParent: true
      fields: (fields) =>
        fields.first = @ReferenceField Person
        fields

  testWList test, ALL
  test.equal W._delayed.length, 8
  test.equal W._delayed[0], _TestFirst
  test.equal W._delayed[1], _TestSecond
  test.equal W._delayed[2], _TestThird
  test.equal W._delayed[3], _TestFirst2
  test.equal W._delayed[4], Second
  test.equal W._delayed[5], _TestThird2
  test.equal W._delayed[6], Third
  test.equal W._delayed[7], First

  firstReferenceA = First
  W._retryDelayed()

  testWList test, ALL.concat [_TestFirst, Second]
  test.equal W._delayed.length, 5
  test.equal W._delayed[0], _TestThird
  test.equal W._delayed[1], _TestFirst2
  test.equal W._delayed[2], _TestThird2
  test.equal W._delayed[3], Third
  test.equal W._delayed[4], First

  test.equal Second.Meta._name, 'Second'
  test.equal Second.Meta.parent, _TestSecond.Meta
  test.equal Second.Meta.W, Second
  test.equal Second.Meta.collection._name, 'Seconds'
  test.equal _.size(Second.Meta.fields), 2
  test.instanceOf Second.Meta.fields.first, Second._ReferenceField
  test.isFalse Second.Meta.fields.first.ancestorArray, Second.Meta.fields.first.ancestorArray
  test.isTrue Second.Meta.fields.first.required
  test.equal Second.Meta.fields.first.sourcePath, 'first'
  test.equal Second.Meta.fields.first.sourceW, Second
  test.equal Second.Meta.fields.first.targetW, firstReferenceA
  test.equal Second.Meta.fields.first.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetCollection._name, 'Firsts'
  test.equal Second.Meta.fields.first.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetW.Meta.collection._name, 'Firsts'
  test.equal Second.Meta.fields.first.fields, []
  test.isNull Second.Meta.fields.first.reverseName
  test.equal Second.Meta.fields.first.reverseFields, []
  test.instanceOf Second.Meta.fields.second, Second._ReferenceField
  test.isFalse Second.Meta.fields.second.ancestorArray, Second.Meta.fields.second.ancestorArray
  test.isTrue Second.Meta.fields.second.required
  test.equal Second.Meta.fields.second.sourcePath, 'second'
  test.equal Second.Meta.fields.second.sourceW, Second
  test.equal Second.Meta.fields.second.targetW, Person
  test.equal Second.Meta.fields.second.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetCollection._name, 'Persons'
  test.equal Second.Meta.fields.second.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetW.Meta.collection._name, 'Persons'
  test.equal Second.Meta.fields.second.fields, []
  test.isNull Second.Meta.fields.second.reverseName
  test.equal Second.Meta.fields.second.reverseFields, []

  firstReferenceB = wNode
  W._retryDelayed()

  testWList test, ALL.concat [Second, First]
  test.equal W._delayed.length, 3
  test.equal W._delayed[0], _TestThird
  test.equal W._delayed[1], _TestThird2
  test.equal W._delayed[2], Third

  test.equal Second.Meta._name, 'Second'
  test.equal Second.Meta.parent, _TestSecond.Meta
  test.equal Second.Meta.W, Second
  test.equal Second.Meta.collection._name, 'Seconds'
  test.equal _.size(Second.Meta.fields), 2
  test.instanceOf Second.Meta.fields.first, Second._ReferenceField
  test.isFalse Second.Meta.fields.first.ancestorArray, Second.Meta.fields.first.ancestorArray
  test.isTrue Second.Meta.fields.first.required
  test.equal Second.Meta.fields.first.sourcePath, 'first'
  test.equal Second.Meta.fields.first.sourceW, Second
  test.equal Second.Meta.fields.first.targetW, firstReferenceA
  test.equal Second.Meta.fields.first.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetCollection._name, 'Firsts'
  test.equal Second.Meta.fields.first.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetW.Meta.collection._name, 'Firsts'
  test.equal Second.Meta.fields.first.fields, []
  test.isNull Second.Meta.fields.first.reverseName
  test.equal Second.Meta.fields.first.reverseFields, []
  test.instanceOf Second.Meta.fields.second, Second._ReferenceField
  test.isFalse Second.Meta.fields.second.ancestorArray, Second.Meta.fields.second.ancestorArray
  test.isTrue Second.Meta.fields.second.required
  test.equal Second.Meta.fields.second.sourcePath, 'second'
  test.equal Second.Meta.fields.second.sourceW, Second
  test.equal Second.Meta.fields.second.targetW, Person
  test.equal Second.Meta.fields.second.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetCollection._name, 'Persons'
  test.equal Second.Meta.fields.second.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetW.Meta.collection._name, 'Persons'
  test.equal Second.Meta.fields.second.fields, []
  test.isNull Second.Meta.fields.second.reverseName
  test.equal Second.Meta.fields.second.reverseFields, []

  test.equal First.Meta._name, 'First'
  test.equal First.Meta.parent, _TestFirst2.Meta
  test.equal First.Meta.W, First
  test.equal First.Meta.collection._name, 'Firsts'
  test.equal _.size(First.Meta.fields), 1
  test.instanceOf First.Meta.fields.first, First._ReferenceField
  test.isFalse First.Meta.fields.first.ancestorArray, First.Meta.fields.first.ancestorArray
  test.isTrue First.Meta.fields.first.required
  test.equal First.Meta.fields.first.sourcePath, 'first'
  test.equal First.Meta.fields.first.sourceW, First
  test.equal First.Meta.fields.first.targetW, Person
  test.equal First.Meta.fields.first.sourceCollection._name, 'Firsts'
  test.equal First.Meta.fields.first.targetCollection._name, 'Persons'
  test.equal First.Meta.fields.first.sourceW.Meta.collection._name, 'Firsts'
  test.equal First.Meta.fields.first.targetW.Meta.collection._name, 'Persons'
  test.equal First.Meta.fields.first.fields, []
  test.isNull First.Meta.fields.first.reverseName
  test.equal First.Meta.fields.first.reverseFields, []

  secondReferenceA = First
  W._retryDelayed()

  testWList test, ALL.concat [Second, First, _TestThird]
  test.equal W._delayed.length, 2
  test.equal W._delayed[0], _TestThird2
  test.equal W._delayed[1], Third

  test.equal Second.Meta._name, 'Second'
  test.equal Second.Meta.parent, _TestSecond.Meta
  test.equal Second.Meta.W, Second
  test.equal Second.Meta.collection._name, 'Seconds'
  test.equal _.size(Second.Meta.fields), 2
  test.instanceOf Second.Meta.fields.first, Second._ReferenceField
  test.isFalse Second.Meta.fields.first.ancestorArray, Second.Meta.fields.first.ancestorArray
  test.isTrue Second.Meta.fields.first.required
  test.equal Second.Meta.fields.first.sourcePath, 'first'
  test.equal Second.Meta.fields.first.sourceW, Second
  test.equal Second.Meta.fields.first.targetW, firstReferenceA
  test.equal Second.Meta.fields.first.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetCollection._name, 'Firsts'
  test.equal Second.Meta.fields.first.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetW.Meta.collection._name, 'Firsts'
  test.equal Second.Meta.fields.first.fields, []
  test.isNull Second.Meta.fields.first.reverseName
  test.equal Second.Meta.fields.first.reverseFields, []
  test.instanceOf Second.Meta.fields.second, Second._ReferenceField
  test.isFalse Second.Meta.fields.second.ancestorArray, Second.Meta.fields.second.ancestorArray
  test.isTrue Second.Meta.fields.second.required
  test.equal Second.Meta.fields.second.sourcePath, 'second'
  test.equal Second.Meta.fields.second.sourceW, Second
  test.equal Second.Meta.fields.second.targetW, Person
  test.equal Second.Meta.fields.second.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetCollection._name, 'Persons'
  test.equal Second.Meta.fields.second.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetW.Meta.collection._name, 'Persons'
  test.equal Second.Meta.fields.second.fields, []
  test.isNull Second.Meta.fields.second.reverseName
  test.equal Second.Meta.fields.second.reverseFields, []

  test.equal First.Meta._name, 'First'
  test.equal First.Meta.parent, _TestFirst2.Meta
  test.equal First.Meta.W, First
  test.equal First.Meta.collection._name, 'Firsts'
  test.equal _.size(First.Meta.fields), 1
  test.instanceOf First.Meta.fields.first, First._ReferenceField
  test.isFalse First.Meta.fields.first.ancestorArray, First.Meta.fields.first.ancestorArray
  test.isTrue First.Meta.fields.first.required
  test.equal First.Meta.fields.first.sourcePath, 'first'
  test.equal First.Meta.fields.first.sourceW, First
  test.equal First.Meta.fields.first.targetW, Person
  test.equal First.Meta.fields.first.sourceCollection._name, 'Firsts'
  test.equal First.Meta.fields.first.targetCollection._name, 'Persons'
  test.equal First.Meta.fields.first.sourceW.Meta.collection._name, 'Firsts'
  test.equal First.Meta.fields.first.targetW.Meta.collection._name, 'Persons'
  test.equal First.Meta.fields.first.fields, []
  test.isNull First.Meta.fields.first.reverseName
  test.equal First.Meta.fields.first.reverseFields, []

  secondReferenceB = wNode
  W._retryDelayed()

  testWList test, ALL.concat [Second, First, Third]
  test.equal W._delayed.length, 0

  test.equal Second.Meta._name, 'Second'
  test.equal Second.Meta.parent, _TestSecond.Meta
  test.equal Second.Meta.W, Second
  test.equal Second.Meta.collection._name, 'Seconds'
  test.equal _.size(Second.Meta.fields), 2
  test.instanceOf Second.Meta.fields.first, Second._ReferenceField
  test.isFalse Second.Meta.fields.first.ancestorArray, Second.Meta.fields.first.ancestorArray
  test.isTrue Second.Meta.fields.first.required
  test.equal Second.Meta.fields.first.sourcePath, 'first'
  test.equal Second.Meta.fields.first.sourceW, Second
  test.equal Second.Meta.fields.first.targetW, firstReferenceA
  test.equal Second.Meta.fields.first.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetCollection._name, 'Firsts'
  test.equal Second.Meta.fields.first.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetW.Meta.collection._name, 'Firsts'
  test.equal Second.Meta.fields.first.fields, []
  test.isNull Second.Meta.fields.first.reverseName
  test.equal Second.Meta.fields.first.reverseFields, []
  test.instanceOf Second.Meta.fields.second, Second._ReferenceField
  test.isFalse Second.Meta.fields.second.ancestorArray, Second.Meta.fields.second.ancestorArray
  test.isTrue Second.Meta.fields.second.required
  test.equal Second.Meta.fields.second.sourcePath, 'second'
  test.equal Second.Meta.fields.second.sourceW, Second
  test.equal Second.Meta.fields.second.targetW, Person
  test.equal Second.Meta.fields.second.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetCollection._name, 'Persons'
  test.equal Second.Meta.fields.second.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetW.Meta.collection._name, 'Persons'
  test.equal Second.Meta.fields.second.fields, []
  test.isNull Second.Meta.fields.second.reverseName
  test.equal Second.Meta.fields.second.reverseFields, []

  test.equal First.Meta._name, 'First'
  test.equal First.Meta.parent, _TestFirst2.Meta
  test.equal First.Meta.W, First
  test.equal First.Meta.collection._name, 'Firsts'
  test.equal _.size(First.Meta.fields), 1
  test.instanceOf First.Meta.fields.first, First._ReferenceField
  test.isFalse First.Meta.fields.first.ancestorArray, First.Meta.fields.first.ancestorArray
  test.isTrue First.Meta.fields.first.required
  test.equal First.Meta.fields.first.sourcePath, 'first'
  test.equal First.Meta.fields.first.sourceW, First
  test.equal First.Meta.fields.first.targetW, Person
  test.equal First.Meta.fields.first.sourceCollection._name, 'Firsts'
  test.equal First.Meta.fields.first.targetCollection._name, 'Persons'
  test.equal First.Meta.fields.first.sourceW.Meta.collection._name, 'Firsts'
  test.equal First.Meta.fields.first.targetW.Meta.collection._name, 'Persons'
  test.equal First.Meta.fields.first.fields, []
  test.isNull First.Meta.fields.first.reverseName
  test.equal First.Meta.fields.first.reverseFields, []

  test.equal Third.Meta._name, 'Third'
  test.equal Third.Meta.parent, _TestThird2.Meta
  test.equal Third.Meta.W, Third
  test.equal Third.Meta.collection._name, 'Thirds'
  test.equal _.size(Third.Meta.fields), 3
  test.instanceOf Third.Meta.fields.first, Third._ReferenceField
  test.isFalse Third.Meta.fields.first.ancestorArray, Third.Meta.fields.first.ancestorArray
  test.isTrue Third.Meta.fields.first.required
  test.equal Third.Meta.fields.first.sourcePath, 'first'
  test.equal Third.Meta.fields.first.sourceW, Third
  test.equal Third.Meta.fields.first.targetW, firstReferenceA
  test.equal Third.Meta.fields.first.sourceCollection._name, 'Thirds'
  test.equal Third.Meta.fields.first.targetCollection._name, 'Firsts'
  test.equal Third.Meta.fields.first.sourceW.Meta.collection._name, 'Thirds'
  test.equal Third.Meta.fields.first.targetW.Meta.collection._name, 'Firsts'
  test.equal Third.Meta.fields.first.fields, []
  test.isNull Third.Meta.fields.first.reverseName
  test.equal Third.Meta.fields.first.reverseFields, []
  test.instanceOf Third.Meta.fields.second, Third._ReferenceField
  test.isFalse Third.Meta.fields.second.ancestorArray, Third.Meta.fields.second.ancestorArray
  test.isTrue Third.Meta.fields.second.required
  test.equal Third.Meta.fields.second.sourcePath, 'second'
  test.equal Third.Meta.fields.second.sourceW, Third
  test.equal Third.Meta.fields.second.targetW, wNode
  test.equal Third.Meta.fields.second.sourceCollection._name, 'Thirds'
  test.equal Third.Meta.fields.second.targetCollection._name, 'wNodes'
  test.equal Third.Meta.fields.second.sourceW.Meta.collection._name, 'Thirds'
  test.equal Third.Meta.fields.second.targetW.Meta.collection._name, 'wNodes'
  test.equal Third.Meta.fields.second.fields, []
  test.isNull Third.Meta.fields.second.reverseName
  test.equal Third.Meta.fields.second.reverseFields, []
  test.instanceOf Third.Meta.fields.third, Third._ReferenceField
  test.isFalse Third.Meta.fields.third.ancestorArray, Third.Meta.fields.third.ancestorArray
  test.isTrue Third.Meta.fields.third.required
  test.equal Third.Meta.fields.third.sourcePath, 'third'
  test.equal Third.Meta.fields.third.sourceW, Third
  test.equal Third.Meta.fields.third.targetW, Person
  test.equal Third.Meta.fields.third.sourceCollection._name, 'Thirds'
  test.equal Third.Meta.fields.third.targetCollection._name, 'Persons'
  test.equal Third.Meta.fields.third.sourceW.Meta.collection._name, 'Thirds'
  test.equal Third.Meta.fields.third.targetW.Meta.collection._name, 'Persons'
  test.equal Third.Meta.fields.third.fields, []
  test.isNull Third.Meta.fields.third.reverseName
  test.equal Third.Meta.fields.third.reverseFields, []

  W.defineAll()

  test.equal Second.Meta._name, 'Second'
  test.equal Second.Meta.parent, _TestSecond.Meta
  test.equal Second.Meta.W, Second
  test.equal Second.Meta.collection._name, 'Seconds'
  test.equal _.size(Second.Meta.fields), 2
  test.instanceOf Second.Meta.fields.first, Second._ReferenceField
  test.isFalse Second.Meta.fields.first.ancestorArray, Second.Meta.fields.first.ancestorArray
  test.isTrue Second.Meta.fields.first.required
  test.equal Second.Meta.fields.first.sourcePath, 'first'
  test.equal Second.Meta.fields.first.sourceW, Second
  test.equal Second.Meta.fields.first.targetW, firstReferenceA
  test.equal Second.Meta.fields.first.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetCollection._name, 'Firsts'
  test.equal Second.Meta.fields.first.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.first.targetW.Meta.collection._name, 'Firsts'
  test.equal Second.Meta.fields.first.fields, []
  test.isNull Second.Meta.fields.first.reverseName
  test.equal Second.Meta.fields.first.reverseFields, []
  test.instanceOf Second.Meta.fields.second, Second._ReferenceField
  test.isFalse Second.Meta.fields.second.ancestorArray, Second.Meta.fields.second.ancestorArray
  test.isTrue Second.Meta.fields.second.required
  test.equal Second.Meta.fields.second.sourcePath, 'second'
  test.equal Second.Meta.fields.second.sourceW, Second
  test.equal Second.Meta.fields.second.targetW, Person
  test.equal Second.Meta.fields.second.sourceCollection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetCollection._name, 'Persons'
  test.equal Second.Meta.fields.second.sourceW.Meta.collection._name, 'Seconds'
  test.equal Second.Meta.fields.second.targetW.Meta.collection._name, 'Persons'
  test.equal Second.Meta.fields.second.fields, []
  test.isNull Second.Meta.fields.second.reverseName
  test.equal Second.Meta.fields.second.reverseFields, []

  test.equal First.Meta._name, 'First'
  test.equal First.Meta.parent, _TestFirst2.Meta
  test.equal First.Meta.W, First
  test.equal First.Meta.collection._name, 'Firsts'
  test.equal _.size(First.Meta.fields), 1
  test.instanceOf First.Meta.fields.first, First._ReferenceField
  test.isFalse First.Meta.fields.first.ancestorArray, First.Meta.fields.first.ancestorArray
  test.isTrue First.Meta.fields.first.required
  test.equal First.Meta.fields.first.sourcePath, 'first'
  test.equal First.Meta.fields.first.sourceW, First
  test.equal First.Meta.fields.first.targetW, Person
  test.equal First.Meta.fields.first.sourceCollection._name, 'Firsts'
  test.equal First.Meta.fields.first.targetCollection._name, 'Persons'
  test.equal First.Meta.fields.first.sourceW.Meta.collection._name, 'Firsts'
  test.equal First.Meta.fields.first.targetW.Meta.collection._name, 'Persons'
  test.equal First.Meta.fields.first.fields, []
  test.isNull First.Meta.fields.first.reverseName
  test.equal First.Meta.fields.first.reverseFields, []

  test.equal Third.Meta._name, 'Third'
  test.equal Third.Meta.parent, _TestThird2.Meta
  test.equal Third.Meta.W, Third
  test.equal Third.Meta.collection._name, 'Thirds'
  test.equal _.size(Third.Meta.fields), 3
  test.instanceOf Third.Meta.fields.first, Third._ReferenceField
  test.isFalse Third.Meta.fields.first.ancestorArray, Third.Meta.fields.first.ancestorArray
  test.isTrue Third.Meta.fields.first.required
  test.equal Third.Meta.fields.first.sourcePath, 'first'
  test.equal Third.Meta.fields.first.sourceW, Third
  test.equal Third.Meta.fields.first.targetW, firstReferenceA
  test.equal Third.Meta.fields.first.sourceCollection._name, 'Thirds'
  test.equal Third.Meta.fields.first.targetCollection._name, 'Firsts'
  test.equal Third.Meta.fields.first.sourceW.Meta.collection._name, 'Thirds'
  test.equal Third.Meta.fields.first.targetW.Meta.collection._name, 'Firsts'
  test.equal Third.Meta.fields.first.fields, []
  test.isNull Third.Meta.fields.first.reverseName
  test.equal Third.Meta.fields.first.reverseFields, []
  test.instanceOf Third.Meta.fields.second, Third._ReferenceField
  test.isFalse Third.Meta.fields.second.ancestorArray, Third.Meta.fields.second.ancestorArray
  test.isTrue Third.Meta.fields.second.required
  test.equal Third.Meta.fields.second.sourcePath, 'second'
  test.equal Third.Meta.fields.second.sourceW, Third
  test.equal Third.Meta.fields.second.targetW, wNode
  test.equal Third.Meta.fields.second.sourceCollection._name, 'Thirds'
  test.equal Third.Meta.fields.second.targetCollection._name, 'wNodes'
  test.equal Third.Meta.fields.second.sourceW.Meta.collection._name, 'Thirds'
  test.equal Third.Meta.fields.second.targetW.Meta.collection._name, 'wNodes'
  test.equal Third.Meta.fields.second.fields, []
  test.isNull Third.Meta.fields.second.reverseName
  test.equal Third.Meta.fields.second.reverseFields, []
  test.instanceOf Third.Meta.fields.third, Third._ReferenceField
  test.isFalse Third.Meta.fields.third.ancestorArray, Third.Meta.fields.third.ancestorArray
  test.isTrue Third.Meta.fields.third.required
  test.equal Third.Meta.fields.third.sourcePath, 'third'
  test.equal Third.Meta.fields.third.sourceW, Third
  test.equal Third.Meta.fields.third.targetW, Person
  test.equal Third.Meta.fields.third.sourceCollection._name, 'Thirds'
  test.equal Third.Meta.fields.third.targetCollection._name, 'Persons'
  test.equal Third.Meta.fields.third.sourceW.Meta.collection._name, 'Thirds'
  test.equal Third.Meta.fields.third.targetW.Meta.collection._name, 'Persons'
  test.equal Third.Meta.fields.third.fields, []
  test.isNull Third.Meta.fields.third.reverseName
  test.equal Third.Meta.fields.third.reverseFields, []

  # Restore
  W.list = list
  W._delayed = []
  W._clearDelayedCheck()

  # Verify we are back to normal
  testDefinition test

Tinytest.add 'peerdb - local collections', (test) ->
  list = _.clone W.list

  class Local extends W
    @Meta
      name: 'Local'
      collection: null

  testWList test, ALL.concat [Local]
  test.equal W._delayed.length, 0

  test.equal Local.Meta._name, 'Local'
  test.isFalse Local.Meta.parent
  test.equal Local.Meta.W, Local
  test.equal Local.Meta.collection._name, null
  test.equal _.size(Local.Meta.fields), 0

  # Restore
  W.list = list
  W._delayed = []
  W._clearDelayedCheck()

  # Verify we are back to normal
  testDefinition test

testAsyncMulti 'peerdb - errors for generated fields', [
  (test, expect) ->
    Log._intercept 3 if Meteor.isServer and W.instances is 1 # Three to see if we catch more than expected

    IdentityGenerator.Ws.insert
      source: 'foobar'
    ,
      expect (error, identityGeneratorId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue identityGeneratorId
        @identityGeneratorId = identityGeneratorId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    if Meteor.isServer and W.instances is 1
      intercepted = Log._intercepted()

      # One or two because it depends if the client tests are running at the same time
      test.isTrue 1 <= intercepted.length <= 2, intercepted

      # We are testing only the server one, so let's find it
      for i in intercepted
        break if i.indexOf(@identityGeneratorId) isnt -1
      test.isTrue _.isString(i), i
      intercepted = EJSON.parse i

      test.equal intercepted.message, "Generated field 'results' defined as an array with selector '#{ @identityGeneratorId }' was updated with a non-array value: 'foobar'"
      test.equal intercepted.level, 'error'

    @identityGenerator = IdentityGenerator.Ws.findOne @identityGeneratorId,
      transform: null # So that we can use test.equal

    test.equal @identityGenerator,
      _id: @identityGeneratorId
      source: 'foobar'
      result: 'foobar'

    Log._intercept 3 if Meteor.isServer and W.instances is 1 # Three to see if we catch more than expected

    IdentityGenerator.Ws.update @identityGeneratorId,
      $set:
        source: ['foobar2']
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    if Meteor.isServer and W.instances is 1
      intercepted = Log._intercepted()

      # One or two because it depends if the client tests are running at the same time
      test.isTrue 1 <= intercepted.length <= 2, intercepted

      # We are testing only the server one, so let's find it
      for i in intercepted
        break if i.indexOf(@identityGeneratorId) isnt -1
      test.isTrue _.isString(i), i
      intercepted = EJSON.parse i

      test.equal intercepted.message, "Generated field 'result' not defined as an array with selector '#{ @identityGeneratorId }' was updated with an array value: [ 'foobar2' ]"
      test.equal intercepted.level, 'error'

    @identityGenerator = IdentityGenerator.Ws.findOne @identityGeneratorId,
      transform: null # So that we can use test.equal

    test.equal @identityGenerator,
      _id: @identityGeneratorId
      source: ['foobar2']
      result: 'foobar'
      results: ['foobar2']
]

Tinytest.add 'peerdb - tricky references', (test) ->
  list = _.clone W.list

  # You can in fact use class name instead of "self", but you have to
  # make sure things work out at the end and class is really defined
  class First1 extends W
    @Meta
      name: 'First1'
      fields: =>
        first: @ReferenceField First1

  W.defineAll()

  test.equal First1.Meta._name, 'First1'
  test.isFalse First1.Meta.parent
  test.equal First1.Meta.W, First1
  test.equal First1.Meta.collection._name, 'First1s'
  test.equal _.size(First1.Meta.fields), 1
  test.instanceOf First1.Meta.fields.first, First1._ReferenceField
  test.isFalse First1.Meta.fields.first.ancestorArray, First1.Meta.fields.first.ancestorArray
  test.isTrue First1.Meta.fields.first.required
  test.equal First1.Meta.fields.first.sourcePath, 'first'
  test.equal First1.Meta.fields.first.sourceW, First1
  test.equal First1.Meta.fields.first.targetW, First1
  test.equal First1.Meta.fields.first.sourceCollection._name, 'First1s'
  test.equal First1.Meta.fields.first.targetCollection._name, 'First1s'
  test.equal First1.Meta.fields.first.sourceW.Meta.collection._name, 'First1s'
  test.equal First1.Meta.fields.first.targetW.Meta.collection._name, 'First1s'
  test.equal First1.Meta.fields.first.fields, []

  # Restore
  W.list = _.clone list
  W._delayed = []
  W._clearDelayedCheck()

  class First2 extends W
    @Meta
      name: 'First2'
      fields: =>
        first: @ReferenceField undefined # To force delayed

  class Second2 extends W
    @Meta
      name: 'Second2'
      fields: =>
        first: @ReferenceField First2

  test.throws ->
    W.defineAll true
  , /Target W not defined/

  test.throws ->
    W.defineAll()
  , /Invalid fields/

  # Restore
  W.list = _.clone list
  W._delayed = []
  W._clearDelayedCheck()

  # Verify we are back to normal
  testDefinition test

testAsyncMulti 'peerdb - duplicate values in lists', [
  (test, expect) ->
    Person.Ws.insert
      username: 'person1'
      displayName: 'Person 1'
      field1: 'Field 1 - 1'
      field2: 'Field 1 - 2'
    ,
      expect (error, person1Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person1Id
        @person1Id = person1Id

    Person.Ws.insert
      username: 'person2'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
    ,
      expect (error, person2Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person2Id
        @person2Id = person2Id

    Person.Ws.insert
      username: 'person3'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
    ,
      expect (error, person3Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person3Id
        @person3Id = person3Id

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      field1: 'Field 1 - 1'
      field2: 'Field 1 - 2'
      count: 0
    test.equal @person2,
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
      count: 0
    test.equal @person3,
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      count: 0

    wNode.Ws.insert
      author:
        _id: @person1._id
        # To test what happens if fields are partially not up to date
        username: 'wrong'
        displayName: 'wrong'
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ,
        _id: @person3._id
      ]
      subW:
        person:
          _id: @person2._id
        persons: [
          _id: @person2._id
          username: 'wrong'
          displayName: 'wrong'
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: 'wrong'
        ,
          _id: @person3._id
          # To test if the second person3 value will be updated
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
        ]
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: 'wrong'
          displayName: 'wrong'
        optional:
          _id: @person3._id
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
        optional:
          _id: @person2._id
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
        optional:
          _id: @person2._id
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: 'wrong'
        optional:
          _id: @person2._id
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
        optional:
          _id: @person3._id
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId = wNodeId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.update @person1Id,
      $set:
        username: 'person1a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    Person.Ws.update @person2Id,
      $set:
        username: 'person2a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    # so that persons updates are not merged together to better
    # test the code for multiple updates
    waitForDatabase test, expect
,
  (test, expect) ->
    Person.Ws.update @person3Id,
      $set:
        username: 'person3a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1a'
      displayName: 'Person 1'
      field1: 'Field 1 - 1'
      field2: 'Field 1 - 2'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 1
    test.equal @person2,
      _id: @person2Id
      username: 'person2a'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3
    test.equal @person3,
      _id: @person3Id
      username: 'person3a'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 2

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

  (test, expect) ->
    Person.Ws.update @person1Id,
      $set:
        # Updating two fields at the same time
        field1: 'Field 1 - 1a'
        field2: 'Field 1 - 2a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1a'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 1

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.update @person1Id,
      $unset:
        username: ''
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 1

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.update @person2Id,
      $unset:
        username: ''
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal

    test.equal @person2,
      _id: @person2Id
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.update @person3Id,
      $unset:
        username: ''
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person3,
      _id: @person3Id
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ,
        _id: @person3._id
      ]
      subW:
        person:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.update @person1Id,
      $set:
        username: 'person1b'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 1

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ,
        _id: @person3._id
      ]
      subW:
        person:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.update @person2Id,
      $set:
        username: 'person2b'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal

    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      field1: 'Field 2 - 1'
      field2: 'Field 2 - 2'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
      ,
        _id: @person3._id
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    Person.Ws.update @person3Id,
      $set:
        username: 'person3b'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person3,
      _id: @person3Id
      username: 'person3b'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

  (test, expect) ->
    Person.Ws.update @person2Id,
      $unset:
        # Removing two fields at the same time
        field1: ''
        field2: ''
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal

    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

  (test, expect) ->
    Person.Ws.update @person2Id,
      $set:
        # Restoring two fields at the same time
        field1: 'Field 2 - 1b'
        field2: 'Field 2 - 2b'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal

    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      field1: 'Field 2 - 1b'
      field2: 'Field 2 - 2b'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBar'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $set:
        'subW.body': 'SubWFooBarZ'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 1
    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      field1: 'Field 2 - 1b'
      field2: 'Field 2 - 2b'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3
    test.equal @person3,
      _id: @person3Id
      username: 'person3b'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobarz-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $set:
        'nested.0.body': 'NestedFooBarZ'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 1
    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      field1: 'Field 2 - 1b'
      field2: 'Field 2 - 2b'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3
    test.equal @person3,
      _id: @person3Id
      username: 'person3b'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobarz-suffix'
        body: 'NestedFooBarZ'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobarz-suffix'
        'tag-1-prefix-foobar-nestedfoobarz-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $set:
        'nested.4.body': 'NestedFooBarA'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 1
    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      field1: 'Field 2 - 1b'
      field2: 'Field 2 - 2b'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3
    test.equal @person3,
      _id: @person3Id
      username: 'person3b'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobarz-suffix'
        body: 'NestedFooBarZ'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobara-suffix'
        body: 'NestedFooBarA'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobarz-suffix'
        'tag-1-prefix-foobar-nestedfoobarz-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
        'tag-5-prefix-foobar-nestedfoobara-suffix'
        'tag-6-prefix-foobar-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $set:
        'nested.3.body': null
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 1
    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      field1: 'Field 2 - 1b'
      field2: 'Field 2 - 2b'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3
    test.equal @person3,
      _id: @person3Id
      username: 'person3b'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NestedFooBar'
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobarz-suffix'
        body: 'NestedFooBarZ'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: null
        body: null
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobara-suffix'
        body: 'NestedFooBarA'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobarz-suffix'
        'tag-1-prefix-foobar-nestedfoobarz-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobar-suffix'
        'tag-4-prefix-foobar-nestedfoobara-suffix'
        'tag-5-prefix-foobar-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $unset:
        'nested.2.body': ''
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 1
    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      field1: 'Field 2 - 1b'
      field2: 'Field 2 - 2b'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 3
    test.equal @person3,
      _id: @person3Id
      username: 'person3b'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobar-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobarz-suffix'
        body: 'NestedFooBarZ'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: null
        body: null
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobar-nestedfoobara-suffix'
        body: 'NestedFooBarA'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobarz-suffix'
        'tag-1-prefix-foobar-nestedfoobarz-suffix'
        'tag-2-prefix-foobar-nestedfoobar-suffix'
        'tag-3-prefix-foobar-nestedfoobara-suffix'
        'tag-4-prefix-foobar-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $set:
        body: 'FooBarZ'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBarZ'
      ]
      count: 1
    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      field1: 'Field 2 - 1b'
      field2: 'Field 2 - 2b'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBarZ'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBarZ'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBarZ'
      ]
      count: 3
    test.equal @person3,
      _id: @person3Id
      username: 'person3b'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBarZ'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBarZ'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobarz-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobarz-suffix'
        body: 'NestedFooBarZ'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: null
        body: null
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobarz-nestedfoobara-suffix'
        body: 'NestedFooBarA'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBarZ'
      slug: 'prefix-foobarz-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobarz-subWfoobarz-suffix'
        'tag-1-prefix-foobarz-nestedfoobarz-suffix'
        'tag-2-prefix-foobarz-nestedfoobar-suffix'
        'tag-3-prefix-foobarz-nestedfoobara-suffix'
        'tag-4-prefix-foobarz-nestedfoobar-suffix'
      ]

    wNode.Ws.update @wNodeId,
      $push:
        nested:
          required:
            _id: @person2._id
          optional:
            _id: @person3._id
          body: 'NewFooBar'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NewFooBar'
        ]
        body: 'FooBarZ'
      ]
      count: 1
    test.equal @person2,
      _id: @person2Id
      username: 'person2b'
      displayName: 'Person 2'
      field1: 'Field 2 - 1b'
      field2: 'Field 2 - 2b'
      subWwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NewFooBar'
        ]
        body: 'FooBarZ'
      ]
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NewFooBar'
        ]
        body: 'FooBarZ'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NewFooBar'
        ]
        body: 'FooBarZ'
      ]
      count: 3
    test.equal @person3,
      _id: @person3Id
      username: 'person3b'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NewFooBar'
        ]
        body: 'FooBarZ'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          body: 'NestedFooBarZ'
        ,
          body: 'NestedFooBar'
        ,
          {}
        ,
          body: null
        ,
          body: 'NestedFooBarA'
        ,
          body: 'NestedFooBar'
        ,
          body: 'NewFooBar'
        ]
        body: 'FooBarZ'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person2._id
      ,
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobarz-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobarz-suffix'
        body: 'NestedFooBarZ'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: null
        body: null
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person2._id
          username: @person2.username
        slug: 'nested-prefix-foobarz-nestedfoobara-suffix'
        body: 'NestedFooBarA'
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ,
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
          field1: @person2.field1
          field2: @person2.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-newfoobar-suffix'
        body: 'NewFooBar'
      ]
      body: 'FooBarZ'
      slug: 'prefix-foobarz-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobarz-subWfoobarz-suffix'
        'tag-1-prefix-foobarz-nestedfoobarz-suffix'
        'tag-2-prefix-foobarz-nestedfoobar-suffix'
        'tag-3-prefix-foobarz-nestedfoobara-suffix'
        'tag-4-prefix-foobarz-nestedfoobar-suffix'
        'tag-5-prefix-foobarz-newfoobar-suffix'
      ]

    Person.Ws.remove @person2Id,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          {}
        ,
          body: null
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBarZ'
      ]
      count: 1
    test.equal @person3,
      _id: @person3Id
      username: 'person3b'
      displayName: 'Person 3'
      field1: 'Field 3 - 1'
      field2: 'Field 3 - 2'
      subWswNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          {}
        ,
          body: null
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBarZ'
      ]
      nestedwNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: [
          {}
        ,
          body: null
        ,
          body: 'NestedFooBar'
        ]
        body: 'FooBarZ'
      ]
      count: 2

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: [
        _id: @person3._id
      ]
      reviewers: [
        _id: @person3._id
        username: @person3.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person: null
        persons: [
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        ]
        slug: 'subW-prefix-foobarz-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: [
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional: null
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional: null
        slug: null
        body: null
      ,
        required:
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
          field1: @person3.field1
          field2: @person3.field2
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobarz-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBarZ'
      slug: 'prefix-foobarz-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobarz-subWfoobarz-suffix'
        'tag-1-prefix-foobarz-nestedfoobar-suffix'
      ]

    Person.Ws.remove @person3Id,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal

    test.equal @person1,
      _id: @person1Id
      username: 'person1b'
      displayName: 'Person 1'
      field1: 'Field 1 - 1a'
      field2: 'Field 1 - 2a'
      wNodes: [
        _id: @wNodeId
        subW:
          body: 'SubWFooBarZ'
        nested: []
        body: 'FooBarZ'
      ]
      count: 1

    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.equal @wNode,
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
        field1: @person1.field1
        field2: @person1.field2
      subscribers: []
      reviewers: []
      subW:
        person: null
        persons: []
        slug: 'subW-prefix-foobarz-subWfoobarz-suffix'
        body: 'SubWFooBarZ'
      nested: []
      body: 'FooBarZ'
      slug: 'prefix-foobarz-subWfoobarz-suffix'
      tags: [
        'tag-0-prefix-foobarz-subWfoobarz-suffix'
      ]

    Person.Ws.remove @person1Id,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId,
      transform: null # So that we can use test.equal

    test.isFalse @wNode, @wNode
]

if Meteor.isServer and W.instances is 1
  testAsyncMulti 'peerdb - exception while processing', [
    (test, expect) ->
      Log._intercept 3

      IdentityGenerator.Ws.insert
        source: 'exception'
      ,
        expect (error, identityGeneratorId) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue identityGeneratorId
          @identityGeneratorId = identityGeneratorId

      # Wait so that observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      intercepted = Log._intercepted()

      test.isTrue intercepted.length is 3, intercepted

      # We are testing only the server one, so let's find it
      for i in intercepted
        # First error message
        if i.indexOf('PeerDB exception: Error: Test exception') isnt -1
          i = EJSON.parse i
          test.equal i.message, "PeerDB exception: Error: Test exception: [ { source: 'exception', _id: '#{ @identityGeneratorId }' } ]"
          test.equal i.level, 'error'
        # Stack trace error message
        else if i.indexOf('Error: Test exception') isnt -1
          i = EJSON.parse i
          test.isTrue i.message.indexOf('_GeneratedField.result') isnt -1, i.message
          test.equal i.level, 'error'
        # Invalid update error message
        else if i.indexOf('defined as an array with selector') isnt -1
          i = EJSON.parse i
          test.equal i.message, "Generated field 'results' defined as an array with selector '#{ @identityGeneratorId }' was updated with a non-array value: 'exception'"
          test.equal i.level, 'error'
        else
          test.fail
            type: 'assert_never'
            message: i
  ]

testAsyncMulti 'peerdb - instances', [
  (test, expect) ->
    testDefinition test

    Person.Ws.insert
      username: 'person1'
      displayName: 'Person 1'
    ,
      expect (error, person1Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person1Id
        @person1Id = person1Id

    Person.Ws.insert
      username: 'person2'
      displayName: 'Person 2'
    ,
      expect (error, person2Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person2Id
        @person2Id = person2Id

    Person.Ws.insert
      username: 'person3'
      displayName: 'Person 3'
    ,
      expect (error, person3Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person3Id
        @person3Id = person3Id

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id
    @person2 = Person.Ws.findOne @person2Id
    @person3 = Person.Ws.findOne @person3Id

    test.instanceOf @person1, Person
    test.instanceOf @person2, Person
    test.instanceOf @person3, Person

    test.equal plainObject(@person1),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 0
    test.equal plainObject(@person2),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 0
    test.equal plainObject(@person3),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 0

    test.equal @person1.formatName(), 'person1-Person 1'
    test.equal @person2.formatName(), 'person2-Person 2'
    test.equal @person3.formatName(), 'person3-Person 3'

    wNode.Ws.insert
      author:
        _id: @person1._id
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      subW:
        person:
          _id: @person2._id
        persons: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
        optional:
          _id: @person3._id
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId = wNodeId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = wNode.Ws.findOne @wNodeId

    test.instanceOf @wNode, wNode
    test.instanceOf @wNode.author, Person
    test.instanceOf @wNode.subscribers[0], Person
    test.instanceOf @wNode.subscribers[1], Person
    test.instanceOf @wNode.reviewers[0], Person
    test.instanceOf @wNode.reviewers[1], Person
    test.instanceOf @wNode.subW.person, Person
    test.instanceOf @wNode.subW.persons[0], Person
    test.instanceOf @wNode.subW.persons[1], Person
    test.instanceOf @wNode.nested[0].required, Person
    test.instanceOf @wNode.nested[0].optional, Person

    test.equal @wNode.author.formatName(), "#{ @person1.username }-#{ @person1.displayName }"

    test.equal plainObject(@wNode),
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
      # subscribers have only ids
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      # But reviewers have usernames as well
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
      ]

    SpecialwNode.Ws.insert
      author:
        _id: @person1._id
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      reviewers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      subW:
        person:
          _id: @person2._id
        persons: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
        optional:
          _id: @person3._id
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      special:
        _id: @person1._id
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId = wNodeId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode = SpecialwNode.Ws.findOne @wNodeId

    test.instanceOf @wNode, SpecialwNode
    test.instanceOf @wNode.author, Person
    test.instanceOf @wNode.subscribers[0], Person
    test.instanceOf @wNode.subscribers[1], Person
    test.instanceOf @wNode.reviewers[0], Person
    test.instanceOf @wNode.reviewers[1], Person
    test.instanceOf @wNode.subW.person, Person
    test.instanceOf @wNode.subW.persons[0], Person
    test.instanceOf @wNode.subW.persons[1], Person
    test.instanceOf @wNode.nested[0].required, Person
    test.instanceOf @wNode.nested[0].optional, Person
    test.instanceOf @wNode.special, Person

    test.equal @wNode.author.formatName(), "#{ @person1.username }-#{ @person1.displayName }"

    test.equal plainObject(@wNode),
      _id: @wNodeId
      author:
        _id: @person1._id
        username: @person1.username
        displayName: @person1.displayName
      # subscribers have only ids
      subscribers: [
        _id: @person2._id
      ,
        _id: @person3._id
      ]
      # But reviewers have usernames as well
      reviewers: [
        _id: @person2._id
        username: @person2.username
      ,
        _id: @person3._id
        username: @person3.username
      ]
      subW:
        person:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        persons: [
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        ,
          _id: @person3._id
          username: @person3.username
          displayName: @person3.displayName
        ]
        slug: 'subW-prefix-foobar-subWfoobar-suffix'
        body: 'SubWFooBar'
      nested: [
        required:
          _id: @person2._id
          username: @person2.username
          displayName: @person2.displayName
        optional:
          _id: @person3._id
          username: @person3.username
        slug: 'nested-prefix-foobar-nestedfoobar-suffix'
        body: 'NestedFooBar'
      ]
      body: 'FooBar'
      slug: 'prefix-foobar-subWfoobar-suffix'
      tags: [
        'tag-0-prefix-foobar-subWfoobar-suffix'
        'tag-1-prefix-foobar-nestedfoobar-suffix'
      ]
      special:
        _id: @person1._id

    @username = Random.id()

    if Meteor.isServer
      @userId = Accounts.createUser
        username: @username
        password: 'test'
    else
      Accounts.createUser
        username: @username
        password: 'test'
      ,
        expect (error) =>
          test.isFalse error, error?.toString?() or error
          @userId = Meteor.userId() unless error
,
  (test, expect) ->
    @user = User.Ws.findOne @userId

    test.instanceOf @user, User
    test.equal @user.username, @username
]

Tinytest.add 'peerdb - bad instances', (test) ->
  # Empty W should be always possible to create
  for W in W.list
    test.isTrue new W

  # Something simple
  test.isTrue new wNode
    author:
      _id: Random.id()
      username: 'Foobar'

  test.throws ->
    new wNode
      author: [
        _id: Random.id()
        username: 'Foobar'
      ]
  , /W does not match schema, not a plain object/

  test.throws ->
    new wNode
      subscribers: [
        Random.id()
      ]
  , /W does not match schema, not a plain object/

  test.throws ->
    new wNode
      subW: []
  , /W does not match schema, an unexpected array/

  test.throws ->
    new wNode
      subW: [
        persons: []
      ]
  , /W does not match schema, an unexpected array/

  test.throws ->
    new wNode
      subW: [[
        persons: []
      ]]
  , /W does not match schema, an unexpected array/

  test.throws ->
    new wNode
      subW:
        persons: [
          Random.id()
        ]
  , /W does not match schema, not a plain object/

  test.throws ->
    new wNode
      nested:
        _id: Random.id()
  , /W does not match schema, expected an array/

  test.throws ->
    new wNode
      nested: [
        required: Random.id()
      ]
  , /W does not match schema, not a plain object/

  test.throws ->
    new wNode
      nested:
        required: [
          _id: Random.id()
        ]
  , /W does not match schema, expected an array/

  test.throws ->
    new wNode
      nested:
        required:
          _id: Random.id()
  , /W does not match schema, expected an array/

  test.throws ->
    new wNode
      nested: [
        required: [
          _id: Random.id()
        ]
      ]
  , /W does not match schema, not a plain object/

if Meteor.isServer and not W.instanceDisabled
  testAsyncMulti 'peerdb - update all', [
    (test, expect) ->
      testDefinition test

      Person.Ws.insert
        username: 'person1'
        displayName: 'Person 1'
      ,
        expect (error, person1Id) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue person1Id
          @person1Id = person1Id

      Person.Ws.insert
        username: 'person2'
        displayName: 'Person 2'
      ,
        expect (error, person2Id) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue person2Id
          @person2Id = person2Id

      Person.Ws.insert
        username: 'person3'
        displayName: 'Person 3'
      ,
        expect (error, person3Id) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue person3Id
          @person3Id = person3Id

      # Wait so that observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      @person1 = Person.Ws.findOne @person1Id
      @person2 = Person.Ws.findOne @person2Id
      @person3 = Person.Ws.findOne @person3Id

      wNode.Ws.insert
        author:
          _id: @person1._id
          # To test what happens if one field is already up to date, but the other is not
          username: @person1.username
          displayName: 'wrong'
        subscribers: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        reviewers: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        subW:
          person:
            _id: @person2._id
          persons: [
            _id: @person2._id
          ,
            _id: @person3._id
          ]
          body: 'SubWFooBar'
        nested: [
          required:
            _id: @person2._id
          optional:
            _id: @person3._id
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
      ,
        expect (error, wNodeId) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue wNodeId
          @wNodeId = wNodeId

      # Wait so that observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      @wNode = wNode.Ws.findOne @wNodeId,
        transform: null # So that we can use test.equal

      test.equal @wNode,
        _id: @wNodeId
        author:
          _id: @person1._id
          username: @person1.username
          displayName: @person1.displayName
        # subscribers have only ids
        subscribers: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        # But reviewers have usernames as well
        reviewers: [
          _id: @person2._id
          username: @person2.username
        ,
          _id: @person3._id
          username: @person3.username
        ]
        subW:
          person:
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
          persons: [
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
          ,
            _id: @person3._id
            username: @person3.username
            displayName: @person3.displayName
          ]
          slug: 'subW-prefix-foobar-subWfoobar-suffix'
          body: 'SubWFooBar'
        nested: [
          required:
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
          optional:
            _id: @person3._id
            username: @person3.username
          slug: 'nested-prefix-foobar-nestedfoobar-suffix'
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
        slug: 'prefix-foobar-subWfoobar-suffix'
        tags: [
          'tag-0-prefix-foobar-subWfoobar-suffix'
          'tag-1-prefix-foobar-nestedfoobar-suffix'
        ]

      wNode.Ws.update @wNodeId,
        $set:
          'author.username': 'wrong'
          'reviewers.0.username': 'wrong'
          'reviewers.1.username': 'wrong'
          'subW.person.username': 'wrong'
          'subW.persons.0.username': 'wrong'
          'subW.persons.1.username': 'wrong'
          'nested.0.required.username': 'wrong'
          'nested.0.optional.username': 'wrong'
          slug: 'wrong'
          tags: 'wrong'
      ,
        expect (error, res) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue res

      # Wait so that observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      @wNode = wNode.Ws.findOne @wNodeId,
        transform: null # So that we can use test.equal

      # Reference fields are automatically updated back, but generated fields are not
      test.equal @wNode,
        _id: @wNodeId
        author:
          _id: @person1._id
          username: @person1.username
          displayName: @person1.displayName
        # subscribers have only ids
        subscribers: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        # But reviewers have usernames as well
        reviewers: [
          _id: @person2._id
          username: @person2.username
        ,
          _id: @person3._id
          username: @person3.username
        ]
        subW:
          person:
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
          persons: [
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
          ,
            _id: @person3._id
            username: @person3.username
            displayName: @person3.displayName
          ]
          slug: 'subW-prefix-foobar-subWfoobar-suffix'
          body: 'SubWFooBar'
        nested: [
          required:
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
          optional:
            _id: @person3._id
            username: @person3.username
          slug: 'nested-prefix-foobar-nestedfoobar-suffix'
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
        slug: 'wrong'
        tags: 'wrong'

      # Update all fields back (a blocking operation)
      W.updateAll()

      # Wait so that triggered observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      @wNode = wNode.Ws.findOne @wNodeId,
        transform: null # So that we can use test.equal

      test.equal @wNode,
        _id: @wNodeId
        author:
          _id: @person1._id
          username: @person1.username
          displayName: @person1.displayName
        # subscribers have only ids
        subscribers: [
          _id: @person2._id
        ,
          _id: @person3._id
        ]
        # But reviewers have usernames as well
        reviewers: [
          _id: @person2._id
          username: @person2.username
        ,
          _id: @person3._id
          username: @person3.username
        ]
        subW:
          person:
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
          persons: [
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
          ,
            _id: @person3._id
            username: @person3.username
            displayName: @person3.displayName
          ]
          slug: 'subW-prefix-foobar-subWfoobar-suffix'
          body: 'SubWFooBar'
        nested: [
          required:
            _id: @person2._id
            username: @person2.username
            displayName: @person2.displayName
          optional:
            _id: @person3._id
            username: @person3.username
          slug: 'nested-prefix-foobar-nestedfoobar-suffix'
          body: 'NestedFooBar'
        ]
        body: 'FooBar'
        slug: 'prefix-foobar-subWfoobar-suffix'
        tags: [
          'tag-0-prefix-foobar-subWfoobar-suffix'
          'tag-1-prefix-foobar-nestedfoobar-suffix'
        ]
  ]

testAsyncMulti 'peerdb - reverse wNodes', [
  (test, expect) ->
    Person.Ws.insert
      username: 'person1'
      displayName: 'Person 1'
    ,
      expect (error, person1Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person1Id
        @person1Id = person1Id

    Person.Ws.insert
      username: 'person2'
      displayName: 'Person 2'
    ,
      expect (error, person2Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person2Id
        @person2Id = person2Id

    Person.Ws.insert
      username: 'person3'
      displayName: 'Person 3'
    ,
      expect (error, person3Id) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue person3Id
        @person3Id = person3Id

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    wNode.Ws.insert
      author:
        _id: @person1Id
      nested: [
        required:
          _id: @person2Id
        body: 'NestedFooBar1'
      ]
      subW:
        person:
          _id: @person1Id
        persons: [
          _id: @person1Id
        ,
          _id: @person2Id
        ,
          _id: @person3Id
        ,
          _id: @person1Id
        ,
          _id: @person2Id
        ,
          _id: @person3Id
        ]
        body: 'SubWFooBar1'
      body: 'FooBar1'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId1 = wNodeId

    wNode.Ws.insert
      author:
        _id: @person1Id
      nested: [
        required:
          _id: @person3Id
        body: 'NestedFooBar2'
      ]
      subW:
        person:
          _id: @person2Id
        persons: [
          _id: @person2Id
        ,
          _id: @person2Id
        ,
          _id: @person2Id
        ,
          _id: @person1Id
        ,
          _id: @person2Id
        ,
          _id: @person3Id
        ]
        body: 'SubWFooBar2'
      body: 'FooBar2'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId2 = wNodeId

    wNode.Ws.insert
      author:
        _id: @person1Id
      nested: [
        required:
          _id: @person3Id
        body: 'NestedFooBar3'
      ]
      subW:
        person:
          _id: @person1Id
        persons: [
          _id: @person1Id
        ,
          _id: @person1Id
        ,
          _id: @person1Id
        ,
          _id: @person1Id
        ,
          _id: @person2Id
        ,
          _id: @person3Id
        ]
        body: 'SubWFooBar3'
      body: 'FooBar3'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId3 = wNodeId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode1 = wNode.Ws.findOne @wNodeId1,
      transform: null # So that we can use test.equal
    @wNode2 = wNode.Ws.findOne @wNodeId2,
      transform: null # So that we can use test.equal
    @wNode3 = wNode.Ws.findOne @wNodeId3,
      transform: null # So that we can use test.equal

    test.equal @wNode1,
      _id: @wNodeId1
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        persons: [
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar1-subWfoobar1-suffix'
        body: 'SubWFooBar1'
      nested: [
        required:
          _id: @person2Id
          username: 'person2'
          displayName: 'Person 2'
        slug: 'nested-prefix-foobar1-nestedfoobar1-suffix'
        body: 'NestedFooBar1'
      ]
      body: 'FooBar1'
      slug: 'prefix-foobar1-subWfoobar1-suffix'
      tags: [
        'tag-0-prefix-foobar1-subWfoobar1-suffix'
        'tag-1-prefix-foobar1-nestedfoobar1-suffix'
      ]

    test.equal @wNode2,
      _id: @wNodeId2
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        persons: [
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar2-subWfoobar2-suffix'
        body: 'SubWFooBar2'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar2-nestedfoobar2-suffix'
        body: 'NestedFooBar2'
      ]
      body: 'FooBar2'
      slug: 'prefix-foobar2-subWfoobar2-suffix'
      tags: [
        'tag-0-prefix-foobar2-subWfoobar2-suffix'
        'tag-1-prefix-foobar2-nestedfoobar2-suffix'
      ]

    test.equal @wNode3,
      _id: @wNodeId3
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        persons: [
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar3-subWfoobar3-suffix'
        body: 'SubWFooBar3'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar3-nestedfoobar3-suffix'
        body: 'NestedFooBar3'
      ]
      body: 'FooBar3'
      slug: 'prefix-foobar3-subWfoobar3-suffix'
      tags: [
        'tag-0-prefix-foobar3-subWfoobar3-suffix'
        'tag-1-prefix-foobar3-nestedfoobar3-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 8

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ]
    testSetEqual test, @person1.nestedwNodes, []

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 5

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 5

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes, []
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ]

    wNode.Ws.insert
      author:
        _id: @person1Id
      nested: [
        required:
          _id: @person3Id
        body: 'NestedFooBar4'
      ,
        required:
          _id: @person3Id
        body: 'NestedFooBar4'
      ,
        required:
          _id: @person1Id
        body: 'NestedFooBar4'
      ,
        required:
          _id: @person2Id
        body: 'NestedFooBar4'
      ,
        required:
          _id: @person3Id
        body: 'NestedFooBar4'
      ,
        required:
          _id: @person1Id
        body: 'NestedFooBar4'
      ,
        required:
          _id: @person2Id
        body: 'NestedFooBar4'
      ,
        required:
          _id: @person3Id
        body: 'NestedFooBar4'
      ]
      subW:
        person:
          _id: @person1Id
        persons: [
          _id: @person1Id
        ,
          _id: @person1Id
        ,
          _id: @person1Id
        ,
          _id: @person1Id
        ,
          _id: @person2Id
        ,
          _id: @person2Id
        ]
        body: 'SubWFooBar4'
      body: 'FooBar4'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId4 = wNodeId

    wNode.Ws.insert
      author:
        _id: @person1Id
      nested: [
        required:
          _id: @person3Id
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
        body: 'NestedFooBar5'
      ]
      subW:
        person:
          _id: @person3Id
        persons: [
          _id: @person3Id
        ,
          _id: @person3Id
        ,
          _id: @person3Id
        ,
          _id: @person3Id
        ,
          _id: @person2Id
        ,
          _id: @person3Id
        ]
        body: 'SubWFooBar5'
      body: 'FooBar5'
    ,
      expect (error, wNodeId) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue wNodeId
        @wNodeId5 = wNodeId

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1'
        nested: [
          body: 'NestedFooBar1'
        ]
        body: 'FooBar1'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2'
        nested: [
          body: 'NestedFooBar2'
        ]
        body: 'FooBar2'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3'
        nested: [
          body: 'NestedFooBar3'
        ]
        body: 'FooBar3'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5'
      ]

    wNode.Ws.update @wNodeId1,
      $set:
        'body': 'FooBar1a'
        'subW.body': 'SubWFooBar1a'
        'nested.0.body': 'NestedFooBar1a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    wNode.Ws.update @wNodeId2,
      $set:
        'body': 'FooBar2a'
        'subW.body': 'SubWFooBar2a'
        'nested.0.body': 'NestedFooBar2a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    wNode.Ws.update @wNodeId3,
      $set:
        'body': 'FooBar3a'
        'subW.body': 'SubWFooBar3a'
        'nested.0.body': 'NestedFooBar3a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    wNode.Ws.update @wNodeId4,
      $set:
        'body': 'FooBar4a'
        'subW.body': 'SubWFooBar4a'
        'nested.1.body': 'NestedFooBar4a'
        'nested.3.body': 'NestedFooBar4a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    wNode.Ws.update @wNodeId5,
      $set:
        'body': 'FooBar5a'
        'subW.body': 'SubWFooBar5a'
        'nested.1.body': 'NestedFooBar5a'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId2,
      $push:
        nested:
          required:
            _id: @person2Id
          body: 'NestedFooBarNew'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode2 = wNode.Ws.findOne @wNodeId2,
      transform: null # So that we can use test.equal

    test.equal @wNode2,
      _id: @wNodeId2
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        persons: [
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar2a-subWfoobar2a-suffix'
        body: 'SubWFooBar2a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar2a-nestedfoobar2a-suffix'
        body: 'NestedFooBar2a'
      ,
        required:
          _id: @person2Id
          username: 'person2'
          displayName: 'Person 2'
        slug: 'nested-prefix-foobar2a-nestedfoobarnew-suffix'
        body: 'NestedFooBarNew'
      ]
      body: 'FooBar2a'
      slug: 'prefix-foobar2a-subWfoobar2a-suffix'
      tags: [
        'tag-0-prefix-foobar2a-subWfoobar2a-suffix'
        'tag-1-prefix-foobar2a-nestedfoobar2a-suffix'
        'tag-2-prefix-foobar2a-nestedfoobarnew-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 9

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId2,
      $pop:
        nested: 1
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode2 = wNode.Ws.findOne @wNodeId2,
      transform: null # So that we can use test.equal

    test.equal @wNode2,
      _id: @wNodeId2
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        persons: [
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar2a-subWfoobar2a-suffix'
        body: 'SubWFooBar2a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar2a-nestedfoobar2a-suffix'
        body: 'NestedFooBar2a'
      ]
      body: 'FooBar2a'
      slug: 'prefix-foobar2a-subWfoobar2a-suffix'
      tags: [
        'tag-0-prefix-foobar2a-subWfoobar2a-suffix'
        'tag-1-prefix-foobar2a-nestedfoobar2a-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    # Add one which already exist
    wNode.Ws.update @wNodeId2,
      $push:
        nested:
          required:
            _id: @person3Id
          body: 'NestedFooBarNew'
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode2 = wNode.Ws.findOne @wNodeId2,
      transform: null # So that we can use test.equal

    test.equal @wNode2,
      _id: @wNodeId2
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        persons: [
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar2a-subWfoobar2a-suffix'
        body: 'SubWFooBar2a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar2a-nestedfoobar2a-suffix'
        body: 'NestedFooBar2a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar2a-nestedfoobarnew-suffix'
        body: 'NestedFooBarNew'
      ]
      body: 'FooBar2a'
      slug: 'prefix-foobar2a-subWfoobar2a-suffix'
      tags: [
        'tag-0-prefix-foobar2a-subWfoobar2a-suffix'
        'tag-1-prefix-foobar2a-nestedfoobar2a-suffix'
        'tag-2-prefix-foobar2a-nestedfoobarnew-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ,
          body: 'NestedFooBarNew'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId2,
      $pop:
        nested: 1
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode2 = wNode.Ws.findOne @wNodeId2,
      transform: null # So that we can use test.equal

    test.equal @wNode2,
      _id: @wNodeId2
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        persons: [
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar2a-subWfoobar2a-suffix'
        body: 'SubWFooBar2a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar2a-nestedfoobar2a-suffix'
        body: 'NestedFooBar2a'
      ]
      body: 'FooBar2a'
      slug: 'prefix-foobar2a-subWfoobar2a-suffix'
      tags: [
        'tag-0-prefix-foobar2a-subWfoobar2a-suffix'
        'tag-1-prefix-foobar2a-nestedfoobar2a-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $set:
        'nested.0.required._id': @person2Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person2Id
          username: 'person2'
          displayName: 'Person 2'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 9

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $set:
        'nested.0.required._id': @person3Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $push:
        'subW.persons':
          _id: @person1Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 14

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $pop:
        'subW.persons': 1
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    # Add one which already exist
    wNode.Ws.update @wNodeId5,
      $push:
        'subW.persons':
          _id: @person3Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $pop:
        'subW.persons': 1
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $set:
        'subW.persons.2._id': @person1Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 14

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    # Add one which already exist
    wNode.Ws.update @wNodeId5,
      $set:
        'subW.persons.2._id': @person3Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $set:
        'subW.person': null
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person: null
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 8

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes, []
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $set:
        'subW.person':
          _id: @person3Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 9

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $set:
        'subW.person':
          _id: @person1Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        person:
          _id: @person1Id
          displayName: 'Person 1'
          username: 'person1'
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 14

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 8

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes, []
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $unset:
        'subW.person': ''
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
      subW:
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 13

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 8

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 8

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes, []
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.update @wNodeId5,
      $set:
        author:
          _id: @person2Id
    ,
      expect (error, res) =>
        test.isFalse error, error?.toString?() or error
        test.isTrue res

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @wNode5 = wNode.Ws.findOne @wNodeId5,
      transform: null # So that we can use test.equal

    test.equal @wNode5,
      _id: @wNodeId5
      author:
        _id: @person2Id
        username: 'person2'
        displayName: 'Person 2'
      subW:
        persons: [
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ,
          _id: @person2Id
          displayName: 'Person 2'
          username: 'person2'
        ,
          _id: @person3Id
          displayName: 'Person 3'
          username: 'person3'
        ]
        slug: 'subW-prefix-foobar5a-subWfoobar5a-suffix'
        body: 'SubWFooBar5a'
      nested: [
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5a-suffix'
        body: 'NestedFooBar5a'
      ,
        required:
          _id: @person3Id
          username: 'person3'
          displayName: 'Person 3'
        slug: 'nested-prefix-foobar5a-nestedfoobar5-suffix'
        body: 'NestedFooBar5'
      ]
      body: 'FooBar5a'
      slug: 'prefix-foobar5a-subWfoobar5a-suffix'
      tags: [
        'tag-0-prefix-foobar5a-subWfoobar5a-suffix'
        'tag-1-prefix-foobar5a-nestedfoobar5-suffix'
        'tag-2-prefix-foobar5a-nestedfoobar5a-suffix'
        'tag-3-prefix-foobar5a-nestedfoobar5-suffix'
      ]

    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 12

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 9

    testSetEqual test, @person2.wNodes,
      [
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 8

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes, []
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ,
        _id: @wNodeId5
        subW:
          body: 'SubWFooBar5a'
        nested: [
          body: 'NestedFooBar5'
        ,
          body: 'NestedFooBar5a'
        ,
          body: 'NestedFooBar5'
        ]
        body: 'FooBar5a'
      ]

    wNode.Ws.remove @wNodeId5,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 12

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 7

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ]
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 6

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes, []
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId2
        subW:
          body: 'SubWFooBar2a'
        nested: [
          body: 'NestedFooBar2a'
        ]
        body: 'FooBar2a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    wNode.Ws.remove @wNodeId2,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 10

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 5

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes, []
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 4

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes, []
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId3
        subW:
          body: 'SubWFooBar3a'
        nested: [
          body: 'NestedFooBar3a'
        ]
        body: 'FooBar3a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    wNode.Ws.remove @wNodeId3,
      expect (error) =>
        test.isFalse error, error?.toString?() or error

    # Wait so that observers have time to update Ws
    waitForDatabase test, expect
,
  (test, expect) ->
    @person1 = Person.Ws.findOne @person1Id,
      transform: null # So that we can use test.equal
    @person2 = Person.Ws.findOne @person2Id,
      transform: null # So that we can use test.equal
    @person3 = Person.Ws.findOne @person3Id,
      transform: null # So that we can use test.equal

    test.equal _.omit(@person1, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person1Id
      username: 'person1'
      displayName: 'Person 1'
      count: 7

    testSetEqual test, @person1.wNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person1.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person2, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person2Id
      username: 'person2'
      displayName: 'Person 2'
      count: 4

    testSetEqual test, @person2.wNodes, []
    testSetEqual test, @person2.subWwNodes, []
    testSetEqual test, @person2.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
    testSetEqual test, @person2.nestedwNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ,
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]

    test.equal _.omit(@person3, 'wNodes', 'subWwNodes', 'subWswNodes', 'nestedwNodes'),
      _id: @person3Id
      username: 'person3'
      displayName: 'Person 3'
      count: 2

    testSetEqual test, @person3.wNodes, []
    testSetEqual test, @person3.subWwNodes, []
    testSetEqual test, @person3.subWswNodes,
      [
        _id: @wNodeId1
        subW:
          body: 'SubWFooBar1a'
        nested: [
          body: 'NestedFooBar1a'
        ]
        body: 'FooBar1a'
      ]
    testSetEqual test, @person3.nestedwNodes,
      [
        _id: @wNodeId4
        subW:
          body: 'SubWFooBar4a'
        nested: [
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4a'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ,
          body: 'NestedFooBar4'
        ]
        body: 'FooBar4a'
      ]
]

if Meteor.isServer
  testAsyncMulti 'peerdb - triggers', [
    (test, expect) ->
      testDefinition test

      Person.Ws.insert
        username: 'person1'
        displayName: 'Person 1'
      ,
        expect (error, person1Id) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue person1Id
          @person1Id = person1Id

      # Wait so that observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      @person1 = Person.Ws.findOne @person1Id

      test.instanceOf @person1, Person

      test.equal plainObject(@person1),
        _id: @person1Id
        username: 'person1'
        displayName: 'Person 1'
        count: 0

      test.equal @person1.formatName(), 'person1-Person 1'

      wNode.Ws.insert
        author:
          _id: @person1._id
        subW: {}
        body: 'FooBar'
      ,
        expect (error, wNodeId) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue wNodeId
          @wNodeId = wNodeId

      # Wait so that observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      @wNode = wNode.Ws.findOne @wNodeId

      test.instanceOf @wNode, wNode
      test.instanceOf @wNode.author, Person

      test.equal @wNode.author.formatName(), "#{ @person1.username }-#{ @person1.displayName }"

      test.equal plainObject(@wNode),
        _id: @wNodeId
        author:
          _id: @person1._id
          username: @person1.username
          displayName: @person1.displayName
        subW: {}
        body: 'FooBar'
        tags: []

      SpecialwNode.Ws.insert
        author:
          _id: @person1._id
        subW: {}
        body: 'FooBar'
        special:
          _id: @person1._id
      ,
        expect (error, wNodeId) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue wNodeId
          @specialwNodeId = wNodeId

      # Wait so that observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      @specialwNode = SpecialwNode.Ws.findOne @specialwNodeId

      test.instanceOf @specialwNode, SpecialwNode
      test.instanceOf @specialwNode.author, Person
      test.instanceOf @specialwNode.special, Person

      test.equal @specialwNode.author.formatName(), "#{ @person1.username }-#{ @person1.displayName }"

      test.equal plainObject(@specialwNode),
        _id: @specialwNodeId
        author:
          _id: @person1._id
          username: @person1.username
          displayName: @person1.displayName
        subW: {}
        body: 'FooBar'
        tags: []
        special:
          _id: @person1._id

      test.equal globalTestTriggerCounters[@wNodeId], 1
      test.equal globalTestTriggerCounters[@specialwNodeId], 1

      wNode.Ws.update @wNodeId,
        $set:
          body: 'FooBar 1'
      ,
        expect (error, res) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue res

      SpecialwNode.Ws.update @specialwNodeId,
        $set:
          body: 'FooBar 1'
      ,
        expect (error, res) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue res

      # Wait so that observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      @wNode = wNode.Ws.findOne @wNodeId

      test.instanceOf @wNode, wNode
      test.instanceOf @wNode.author, Person

      test.equal @wNode.author.formatName(), "#{ @person1.username }-#{ @person1.displayName }"

      test.equal plainObject(@wNode),
        _id: @wNodeId
        author:
          _id: @person1._id
          username: @person1.username
          displayName: @person1.displayName
        subW: {}
        body: 'FooBar 1'
        tags: []

      @specialwNode = SpecialwNode.Ws.findOne @specialwNodeId

      test.instanceOf @specialwNode, SpecialwNode
      test.instanceOf @specialwNode.author, Person
      test.instanceOf @specialwNode.special, Person

      test.equal @specialwNode.author.formatName(), "#{ @person1.username }-#{ @person1.displayName }"

      test.equal plainObject(@specialwNode),
        _id: @specialwNodeId
        author:
          _id: @person1._id
          username: @person1.username
          displayName: @person1.displayName
        subW: {}
        body: 'FooBar 1'
        tags: []
        special:
          _id: @person1._id

      test.equal globalTestTriggerCounters[@wNodeId], 2
      test.equal globalTestTriggerCounters[@specialwNodeId], 2

      wNode.Ws.update @wNodeId,
        $set:
          'subW.body': 'FooBar zzz'
      ,
        expect (error, res) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue res

      SpecialwNode.Ws.update @specialwNodeId,
        $set:
          'subW.body': 'FooBar zzz'
      ,
        expect (error, res) =>
          test.isFalse error, error?.toString?() or error
          test.isTrue res

      # Wait so that observers have time to update Ws
      waitForDatabase test, expect
  ,
    (test, expect) ->
      @wNode = wNode.Ws.findOne @wNodeId

      test.instanceOf @wNode, wNode
      test.instanceOf @wNode.author, Person

      test.equal @wNode.author.formatName(), "#{ @person1.username }-#{ @person1.displayName }"

      test.equal plainObject(@wNode),
        _id: @wNodeId
        author:
          _id: @person1._id
          username: @person1.username
          displayName: @person1.displayName
        subW:
          body: 'FooBar zzz'
          slug: 'subW-prefix-foobar 1-foobar zzz-suffix'
        body: 'FooBar 1'
        slug: 'prefix-foobar 1-foobar zzz-suffix'
        tags: [
          'tag-0-prefix-foobar 1-foobar zzz-suffix'
        ]

      @specialwNode = SpecialwNode.Ws.findOne @specialwNodeId

      test.instanceOf @specialwNode, SpecialwNode
      test.instanceOf @specialwNode.author, Person
      test.instanceOf @specialwNode.special, Person

      test.equal @specialwNode.author.formatName(), "#{ @person1.username }-#{ @person1.displayName }"

      test.equal plainObject(@specialwNode),
        _id: @specialwNodeId
        author:
          _id: @person1._id
          username: @person1.username
          displayName: @person1.displayName
        subW:
          body: 'FooBar zzz'
          slug: 'subW-prefix-foobar 1-foobar zzz-suffix'
        body: 'FooBar 1'
        slug: 'prefix-foobar 1-foobar zzz-suffix'
        tags: [
          'tag-0-prefix-foobar 1-foobar zzz-suffix'
        ]
        special:
          _id: @person1._id

      test.equal globalTestTriggerCounters[@wNodeId], 2
      test.equal globalTestTriggerCounters[@specialwNodeId], 2
  ]
###


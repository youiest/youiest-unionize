WAIT_FOR_DATABASE_TIMEOUT = 1000 # ms

# The order of documents here tests delayed definitions


if Meteor.isServer
  globalTestTriggerCounters = {}

class Post extends Document
  # Other fields:
  #   body
  #   subdocument
  #     body
  #   nested
  #     body

  @Meta
    name: 'Post'
    fields: =>
      # We can reference other document
      author: @ReferenceField Person, ['username', 'displayName', 'field1', 'field2'], true, 'posts', ['body', 'subdocument.body', 'nested.body']
      # Or an array of documents
      subscribers: [@ReferenceField Person]
      # Fields can be arbitrary MongoDB projections
      reviewers: [@ReferenceField Person, [username: 1]]
      subdocument:
        person: @ReferenceField Person, ['username', 'displayName', 'field1', 'field2'], false, 'subdocumentPosts', ['body', 'subdocument.body', 'nested.body']
        slug: @GeneratedField 'self', ['body', 'subdocument.body'], (fields) ->
          if _.isUndefined(fields.body) or _.isUndefined(fields.subdocument?.body)
            [fields._id, undefined]
          else if _.isNull(fields.body) or _.isNull(fields.subdocument.body)
            [fields._id, null]
          else
            [fields._id, "subdocument-prefix-#{ fields.body.toLowerCase() }-#{ fields.subdocument.body.toLowerCase() }-suffix"]
      nested: [
        required: @ReferenceField Person, ['username', 'displayName', 'field1', 'field2'], true, 'nestedPosts', ['body', 'subdocument.body', 'nested.body']
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
      slug: @GeneratedField 'self', ['body', 'subdocument.body'], (fields) ->
        if _.isUndefined(fields.body) or _.isUndefined(fields.subdocument?.body)
          [fields._id, undefined]
        else if _.isNull(fields.body) or _.isNull(fields.subdocument.body)
          [fields._id, null]
        else
          [fields._id, "prefix-#{ fields.body.toLowerCase() }-#{ fields.subdocument.body.toLowerCase() }-suffix"]
      tags: [
        @GeneratedField 'self', ['body', 'subdocument.body', 'nested.body'], (fields) ->
          tags = []
          if fields.body and fields.subdocument?.body
            tags.push "tag-#{ tags.length }-prefix-#{ fields.body.toLowerCase() }-#{ fields.subdocument.body.toLowerCase() }-suffix"
          if fields.body and fields.nested and _.isArray fields.nested
            for nested in fields.nested when nested.body
              tags.push "tag-#{ tags.length }-prefix-#{ fields.body.toLowerCase() }-#{ nested.body.toLowerCase() }-suffix"
          [fields._id, tags]
      ]
    triggers: =>
      testTrigger: @Trigger ['body'], (newDocument, oldDocument) ->
        return unless newDocument._id
        globalTestTriggerCounters[newDocument._id] = (globalTestTriggerCounters[newDocument._id] or 0) + 1

# Store away for testing
_TestPost = Post

# Extending delayed document
class Post extends Post
  @Meta
    name: 'Post'
    replaceParent: true
    fields: (fields) =>
      fields.subdocument.persons = [@ReferenceField Person, ['username', 'displayName', 'field1', 'field2'], true, 'subdocumentsPosts', ['body', 'subdocument.body', 'nested.body']]
      fields

# Store away for testing
_TestPost2 = Post

class User extends Document
  @Meta
    name: 'User'
    # Specifying collection directly
    collection: Meteor.users

class UserLink extends Document
  @Meta
    name: 'UserLink'
    fields: =>
      user: @ReferenceField User, ['username'], false

class PostLink extends Document
  @Meta
    name: 'PostLink'

# Store away for testing
_TestPostLink = PostLink

# To test extending when initial document has no fields
class PostLink extends PostLink
  @Meta
    name: 'PostLink'
    replaceParent: true
    fields: =>
      post: @ReferenceField Post, ['subdocument.person', 'subdocument.persons']

class CircularFirst extends Document
  # Other fields:
  #   content

  @Meta
    name: 'CircularFirst'

# Store away for testing
_TestCircularFirst = CircularFirst

# To test extending when initial document has no fields and fields will be delayed
class CircularFirst extends CircularFirst
  @Meta
    name: 'CircularFirst'
    replaceParent:  true
    fields: (fields) =>
      # We can reference circular documents
      fields.second = @ReferenceField CircularSecond, ['content'], true, 'reverseFirsts', ['content']
      fields

class CircularSecond extends Document
  # Other fields:
  #   content

  @Meta
    name: 'CircularSecond'
    fields: =>
      # But of course one should not be required so that we can insert without warnings
      first: @ReferenceField CircularFirst, ['content'], false, 'reverseSeconds', ['content']

class Person extends Document
  # Other fields:
  #   username
  #   displayName
  #   field1
  #   field2

  @Meta
    name: 'Person'
    fields: =>
      count: @GeneratedField 'self', ['posts', 'subdocumentPosts', 'subdocumentsPosts', 'nestedPosts'], (fields) ->
        [fields._id, (fields.posts?.length or 0) + (fields.nestedPosts?.length or 0) + (fields.subdocumentPosts?.length or 0) + (fields.subdocumentsPosts?.length or 0)]

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
      # posts and nestedPosts don't exist, so we remove count field as well
      count: undefined

class RecursiveBase extends Document
  @Meta
    abstract: true
    fields: =>
      other: @ReferenceField 'self', ['content'], false, 'reverse', ['content']

class Recursive extends RecursiveBase
  # Other fields:
  #   content

  @Meta
    name: 'Recursive'

class IdentityGenerator extends Document
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
class SpecialPost extends Post
  @Meta
    name: 'SpecialPost'
    fields: =>
      special: @ReferenceField Person

# To test redefinig after fields already have a reference to an old document
class Post extends Post
  @Meta
    name: 'Post'
    replaceParent: true

Document.defineAll()

# Just to make sure things are sane



console.time('docs')

@app = {} #if !app

app.debug = null

if Meteor.absoluteUrl.defaultOptions.rootUrl.match('localhost:3000')
  app.debug = true

@getUsername = ->
  if Meteor.isServer
    -> 'server'
  else 
    -> Meteor.user().username
# everything gets inserted here, thenmirrored into wApp to speed up app load
@app.r = ->

class w extends Document
  @Meta 
    name: 'w'
    from: 'orphan'
    to: 'nowheres'
    incoming: 'not yet'
    #creator: getUsername()
    createdAt: new Date()
    # TODO can't get this to work, need to add incoming._id (n ids ideally composit from-to-originaldate) to this object when they reference this object as a first step
    #fields: (fields) =>
      #fields.to = @ReferenceField w, ['_id'], true, 'incoming' 
      #, true, '_id', 'to'
      #fields
###

ReferenceField accepts the following arguments:

targetDocument – target document class, or 'self'
fields – list of fields to sync in a reference's sub-document; instead of a field name you can use a MongoDB projection as well, like emails: {$slice: 1}
required – should the reference be required (default) or not. If required, when the referenced document is removed, this document will be removed as well. Ff not required, the reference will be set to null.
reverseName – name of a field for a reverse reference; specify to enable a reverse reference
reverseFields – list of fields to sync for a reference reference

    fields: (fields) =>
      fields.slug = @GeneratedField ['createdAt'], (fields) ->
        unless self.createdAt
          [self.createdAt, new Date().getTime()]
      fields
###
# each user has a pre built object in here with everything the app needs to start (smartly limited)
class wApp extends w
  @Meta 
    name: 'wApp'


class wApp extends w
  @Meta 
    name: 'wApp'
    replaceParent: true  # redefine to later understand when it breaks
    
      

# this is meant to be the testing collection so we find the bottlenecks
class wLogs extends Document
  @Meta
    name: 'wLogs'

class User extends w
  @Meta
    name: 'User'
    collection: Meteor.users
console.log 'user'
, User.documents.findOne()
#, User.documents.findOne().meta.createdAt

@printUsers = ->
  User.documents.find({}).forEach (person, i, cursor) =>
    console.log i
    , User.documents.findOne(), User.constructor#

app.r()

if app.debug 
  printUsers()

@v = w.documents.insert
  from: 'present'
  to: 'future'
  creator: 'me'


console.log " hi from unionize common"
, w.Meta
, w.documents.findOne()
#, w.documents.exists({})
#, w.documents.find({}).exists({})
, "bye from unionize common, w.documents.findOne(), w.documents.exists({}), w.documents.find({}).exists({})"

console.timeEnd('docs')


#, p , timerEnd('p') # ,wApp.documents.findOne()




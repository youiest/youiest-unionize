
console.time('docs')
console.log " hi from unionize common"
@app = {} #if !app

app.debug = null

if Meteor.absoluteUrl.defaultOptions.rootUrl.match('localhost:3000')
  app.debug = true

@getUsername = ->
  'common'

@getUsername = ->
  if Meteor.isServer
    -> 'server'
  else 
    -> Meteor.user().username
# everything gets inserted here, thenmirrored into wApp to speed up app load


class @w extends Document
  @Meta 
    name: 'w'
    from: 'orphan'
    username: 'blank'
    body: 'this should trigger'

    # each to has a weight, from only one place but n destinations
    to: 'nowheres'
    incoming: 'none yet'
    #creator: getUsername()

    # needs a field for the original versions created at
    createdAt: new Date()
    # TODO can't get this to work, need to add incoming._id (n ids ideally composit from-to-originaldate) to this object when they reference this object as a first step
    #fields: (fields) =>
      #fields.to = @ReferenceField w, ['_id'], true, 'incoming' 
      #, true, '_id', 'to'
      #fields
#class @w extends w
#  name: 'w'
#  replaceParent: true
  fields: (fields) =>
      fields.to = @ReferenceField {targetDocument: 'self'}
        , {reverseName: 'username'}
        , true
        , 'incoming'
      fields.to = @ReferenceField w
        , {reverseName: 'username'}
        , true
        , 'incoming'
      fields




class @wApp extends w
  @Meta 
    name: 'wApp'


class @wApp extends w
  @Meta 
    name: 'wApp'
    replaceParent: true  # redefine to later understand when it breaks
    
      

# this is meant to be the testing collection so we find the bottlenecks
class @wLogs extends Document
  @Meta
    name: 'wLogs'

class @User extends w
  @Meta
    name: 'User'
    collection: Meteor.users




@printUsers = ->
  User.documents.find({}).forEach (person, i, cursor) =>
    console.log i.emails
    #, User.documents.findOne(), User.constructor#

if app.debug 
  printUsers()

console.time 'inserts'

# something created by me (should)

# move this to server but getting problem with @




console.timeEnd('docs')


#, p , timerEnd('p') # ,wApp.documents.findOne()




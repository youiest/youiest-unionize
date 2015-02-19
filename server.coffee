
l eval('L()'), 'hi from server', eval('L()'), 'evaled Li'
W.before.insert (userId, doc) ->
  #l eval('L()'),  arguments, 'before insert arguments'
  doc.createdAt = Date.now()
  return

# will like cause a write to WI and triggering that hook
# write to a jobs collection, that embeds all earlier versions of the doc into the new one, so there's no dupes

W.after.insert (userId, doc) ->
  #l eval('L()'),  arguments , 'arguments after insert'

  return

Meteor.methods
  # called dynamically if outbox is the changed fieldname
  "outbox" : (doc, userId) ->
    unless userId == Meteor.userId 
      l eval('L()'), 'userId did not match'
    for i in doc.outbox
      l eval('L()'), i, 'outbox document'


# end this task if conditions dictate that we shouldn't touch it
# if recently updated or user hasn't logged in recently postpone writes
WI.before.update (userId, doc, fieldNames, modifier, options) ->
  l eval('L()'),  fieldNames, 'before update fieldNames'
  for i in fieldNames
    l eval('L()'), i
    Meteor.call i, doc, userId, (res,err) ->
      l eval('L()'), res, err
  return
# after insert into main collection we fan out 
# write take w.to and cache write to: 
# WI.findOne('w.to').incomming.['w.from']

# Call push notifications etc if we have new incomming
### 
WI.after.update ((userId, doc, fieldNames, modifier, options) ->
  l this.name, arguments
  # ...
  return
), fetchPrevious: false
###
# there will be an outbox and inbox document, as well as a profile document.
# profile document 
processInboxAfterUpdate = (doc)->
  for i in doc 
    l eval('L()'),  i, 'inserting into w'
    ins = W.insert i
    l eval('L()'),  ins , 'interted into w'
WIAfterUpdate = WI.after.update (userId, doc, fieldNames, modifier, options) ->
  #console.log arguments.callee, arguments
  l eval('L()'), doc, doc.outbox, 'got after updated WI! on server!' 
  if doc.outbox.length > 0 
    processInboxAfterUpdate(doc.outbox)
   
  
### arguments
 l 5734 { _id: 'nicolson',
   outbox: [ { from: 'picture', to: 'elias' } ] } got after updated WI! on server!
 l undefined { '0': undefined,
  '1': { _id: 'nicolson', outbox: [ [Object] ] } }
 3648
 elapsed: 5ms

{ 
'0': undefined,
'1': { _id: 'nicolson', outbox: [ [Object], [Object] ] },
'2': [ 'outbox' ],
'3': { '$push': { outbox: [Object] } },
 '4': {} 
 }

l modifier.outbox

  if !doc.outbox
    l  'nope outbox'
  unless !userId
      l 'unauthenticated after update hook'
 ###
#what if several updates have been inserted? we need a for in loop 
###
  W.insert
    hookedAt: new Date.getTime()
    , $set: modifier.outbox
###
  #l a
  #console.log arguments.callee, userId, doc, fieldNames, modifier, options




Meteor.publish(null,()->
	return W.find({});
);

Meteor.publish(null,()->
	return WI.find({});
);

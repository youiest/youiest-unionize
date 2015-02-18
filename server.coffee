@at = "eval(t());eval( 'arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)'[0]);"
@LineNFile = do ->
  getErrorObject = ->
    try
      throw Error('')
    catch err
      return err
    return

  err = getErrorObject()
  
  caller_line = err.stack.split('\n')[4]
  index = caller_line.indexOf('at ')
  clean = caller_line.slice(index + 2, caller_line.length)
  return clean
#a = do -> eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)')[0]

#collection hooks live on the server and catch up eventually

# pre processing, validation should have been done in lib.coffee
# validate again? 
l a(), 'hi from server'
W.before.insert (userId, doc) ->
  #l a(),  arguments, 'before insert arguments'
  doc.createdAt = Date.now()
  return

# will like cause a write to WI and triggering that hook
# write to a jobs collection, that embeds all earlier versions of the doc into the new one, so there's no dupes

W.after.insert (userId, doc) ->
  #l a(),  arguments , 'arguments after insert'
  # ...
  return

# end this task if conditions dictate that we shouldn't touch it
# if recently updated or user hasn't logged in recently postpone writes
WI.before.update (userId, doc, fieldNames, modifier, options) ->
  l a(),  fieldNames, 'before update fieldNames'
  #modifier.$set = modifier.$set or {}
  #modifier.$set.modifiedAt = Date.now()
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
    l a(),  i, 'inserting into w'
    ins = W.insert i
    l a(),  ins , 'interted into w'
WIAfterUpdate = WI.after.update (userId, doc, fieldNames, modifier, options) ->
  #console.log arguments.callee, arguments
  l a(), doc, doc.outbox, 'got after updated WI! on server!' 
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

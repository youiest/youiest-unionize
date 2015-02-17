
a = do -> eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)')[0]

#collection hooks live on the server and catch up eventually

# pre processing, validation should have been done in lib.coffee
# validate again? 
l eval(t())[0], a, 'hi from server'
W.before.insert (userId, doc) ->
  l eval(t())[0], arguments, 'before insert arguments'
  doc.createdAt = Date.now()
  return

# will like cause a write to WI and triggering that hook
# write to a jobs collection, that embeds all earlier versions of the doc into the new one, so there's no dupes

W.after.insert (userId, doc) ->
  l eval(t())[0], arguments , 'arguments after insert'
  # ...
  return

# end this task if conditions dictate that we shouldn't touch it
# if recently updated or user hasn't logged in recently postpone writes
WI.before.update (userId, doc, fieldNames, modifier, options) ->
  l eval(t())[0], fieldNames, 'hi from before update fieldNames'
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
WI.after.update (userId, doc, fieldNames, modifier, options) ->
  #console.log arguments.callee, arguments
  l eval(t())[0], a, doc, 'got after updated WI! on server!' 
  for i in doc.outbox 
    l eval(t())[0], i
    ins = W.insert i
    l eval(t())[0], ins 
  
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

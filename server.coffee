
smite eval(s) 
W.before.insert (userId, doc) ->
  #smite eval(s),  arguments, 'before insert arguments'
  doc.createdAt = Date.now()
  if !doc.journey
      doc.journey = []

    doc.journey.push
      'serverOutbox': new Date().getTime()
  return

# write to a jobs collection, that embeds all earlier versions of the doc into the new one, so there's no dupes

W.after.insert (userId, doc) ->
  #smite eval(s),  arguments , 'arguments after insert'
  if WIFound doc.to
    smite 'found a target WI', eval s
    WI.update
      _id: doc.to
    ,
      '$push':
        'inbox': 
          from: doc.from
          to: doc.to
    smite WI.findOne

  return





@modModifier = {}
modModifier.outbox = (modifier,userId)->
  smite 'hit outbox in', modifier, eval s
  old_key = 'outbox'
  new_key = 'sending'
  if old_key != new_key
    smite modifier, 'needs a new agenda', eval s
    smite eval Object.defineProperty modifier.$push, new_key, Object.getOwnPropertyDescriptor(modifier.$push, old_key)
    smite eval delete modifier.$push[old_key], 'deleted key', eval s
  # hand off the inserts to an async function, process to update db without waiting
  smite modifier
  smite modifier.$push
  smite modifier.$push.sending.to
  smite inserted = W.insert
    to: modifier.$push.sending.to
    from: modifier.$push.sending.from
  return modifier

Meteor.methods
  "sendingAsync" : (modifier, userId) ->
    smite argsuments, 'sendingAsync', eval s
    Meteor.call 'sendingAsync', modifier, userId, (res, err) ->
      smite 'modifier after sending', res, err, eval s
    # is client always right?
    # {"$push":{"sending":{"from":"picture0","to":"wiber0"}}} "arguments" "server.coffee:34:53)
    
WI.before.update (userId, doc, fieldNames, modifier, options) ->
  for fieldName in fieldNames
    # do we have a function for this fieldname? 
    if _.has(modModifier, fieldName) 
      smite fieldName, 'spinning modModifier', eval s
      # modify the modifier so the update is redirected before hitting db
      modifier = modModifier[fieldName] modifier,userId
  for i in arguments
    smite i,'arguments', eval s

  smite modifier, doc, fieldNames, Meteor.default_server.method_handlers,'fieldname calling method', eval s
  
  smite eval(s), doc, doc.outbox, modifier, 'got before updated WI! on server! is last arg correctly modifier?' 
 

WIAfterUpdate = WI.after.update (userId, doc, fieldNames, modifier, options) ->
  if !doc.journey
      doc.journey = []

    doc.journey.push
      'serverOutbox': new Date().getTime()
  for i in arguments
    smite  arguments, 'after update arguments', eval s

  
  
  

Meteor.publish(null,()->
	return W.find({});
);

Meteor.publish(null,()->
	return WI.find({});
);


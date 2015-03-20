smite eval(s) 
W.before.insert (userId, doc) ->
  #smite eval(s),  arguments, 'before insert arguments'
  doc.createdAt = Date.now()
  if !doc.journey
      doc.journey = []

    doc.journey.push
      'serverCreated': new Date().getTime()
    smite doc, 'inserting this in hook', eval s
  return

# write to a jobs collection, that embeds all earlier versions of the doc into the new one, so there's no dupes

W.after.insert (userId, doc) ->
  #smite eval(s),  arguments , 'arguments after insert'
  if WIFound doc.to
    #smite 'found a target WI', eval s
    WI.update
      _id: doc.to
    ,
      '$push':
        inbox: 
          from: doc.from
          to: doc.to
  smite WI.findOne , 'found this one in WI'

  return





@modModifier = {}
modModifier.outbox = (modifier,userId)->
  #smite 'hit outbox in', modifier, eval s
  old_key = 'outbox'
  new_key = 'sending'
  if old_key != new_key
    smite modifier, 'needs a new agenda', eval s
    smite eval Object.defineProperty modifier.$push, new_key, Object.getOwnPropertyDescriptor(modifier.$push, old_key)
    smite eval delete modifier.$push[old_key], 'deleted key', eval s
  # hand off the inserts to an async function, process to update db without waiting

  
  # always copy in outputs when tricky..
  #  {"$push":{"sending":{"from":"picture1","to":"wiber1"}}}
  smite 'did we insert into W?'
  , modifier
  , modifier.$push
  , from = modifier.$push.sending.from
  , to = modifier.$push.sending.to
  , eval s
  inserted = W.insert
    to: to #modifier.$push.sending.to
    from: from #modifier.$push.sending.from
  smite inserted, 'how long did the insert hook take? usually 30ms', eval s
  # "s" "fwDjXokYCLDkG2w9J" "did we insert into W?" 
  # {"$push":{"sending":{"from":"picture1","to":"wiber1"}}} 
  # null # this is the issue, wht is push undefined?
  # "wiber1" 
  # "server.coffee:39:48), <anonymous> 1422"
  return modifier


WI.before.update (userId, doc, fieldNames, modifier, options) ->
  for fieldName in fieldNames
    # do we have a function for this fieldname? 
    if _.has(modModifier, fieldName) 
      smite fieldName, 'spinning modModifier', eval s
      # modify the modifier so the update is redirected before hitting db
      modifier = modModifier[fieldName] modifier,userId
  for i in arguments
    smite i,'arguments', eval s

  #smite modifier, doc, fieldNames, Meteor.default_server.method_handlers,'fieldname calling method', eval s
  
  #smite eval(s), doc, doc.outbox, modifier, 'got before updated WI! on server! is last arg correctly modifier?' 
 

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


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
  if doc.to
    #smite 'found a target WI', eval s
    WI.update
      _id: doc.to
    ,
      '$push':
        inbox: 
          from: doc.from
          to: doc.to
          "journey": ['serverInbox': new Date().getTime()]
    # WI.update
    #   _id: doc.from
    # ,
    #   '$push':
    #     outbox: 
    #       from: doc.from
    #       to: doc.to
    #       delivered: true
    # W.update({"_id": doc._id},{$push: {
    #     "journey": 'serverInbox': new Date().getTime()
    #   }})

    # db.foo.update({"array.value" : 22}, {"$set" : {"array.$.text" : "blah"}})
    #smite WI.findOne

  return

# remove an item from array
# db.profiles.update( { _id: 1 }, { $pull: { votes: { $gte: 6 } } } )

# update an element in JSON for an array 
# db.foo.update({"array.value" : 22}, {"$set" : {"array.$.text" : "blah"}})


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
  #smite modifier
  #smite modifier.$push
  #smite modifier.$push.sending.to
  smite inserted = W.insert
    to: modifier.$push.sending.to
    from: modifier.$push.sending.from
  modifier = null
  # W.update({"_id": doc._id},{$push: {
  #       "journey": 'onOutbox': new Date().getTime()
  #     }})
  return modifier


WI.before.update (userId, doc, fieldNames, modifier, options) ->
  # console.error("fieldNames")
  # console.error(fieldNames)
  for fieldName in fieldNames
    # do we have a function for this fieldname? 
    if _.has(modModifier, fieldName) 
      smite fieldName, 'spinning modModifier', eval s
      # modify the modifier so the update is redirected before hitting db
      modifier = modModifier[fieldName] modifier,userId
  for i in arguments
    smite i,'arguments', eval s
  W.update({"_id": doc._id},{$push: {
        "journey": 'serverOutbox': new Date().getTime()
      }})
  #smite modifier, doc, fieldNames, Meteor.default_server.method_handlers,'fieldname calling method', eval s
  
  #smite eval(s), doc, doc.outbox, modifier, 'got before updated WI! on server! is last arg correctly modifier?' 
 

WIAfterUpdate = WI.after.update (userId, doc, fieldNames, modifier, options) ->
  if !doc.journey
      doc.journey = []

    # doc.journey.push
    #   'serverOutbox': new Date().getTime()
  for i in arguments
    smite  arguments, 'after update arguments', eval s

  
  
  

Meteor.publish(null,()->
	return W.find({});
);

Meteor.publish(null,()->
	return WI.find({});
);


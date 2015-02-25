
smite eval(s) 
W.before.insert (userId, doc) ->
  #smite eval(s),  arguments, 'before insert arguments'
  doc.createdAt = Date.now()
  return

# write to a jobs collection, that embeds all earlier versions of the doc into the new one, so there's no dupes

W.after.insert (userId, doc) ->
  #smite eval(s),  arguments , 'arguments after insert'

  return

Meteor.methods
  # called dynamically if outbox is the changed fieldname on update WI
  "outbox" : (duserId, doc, fieldNames, modifier, options) ->
    smite doc, modifier, 'going for outbox loop?', eval s
    ###
    unless userId == 'wiber' or Meteor.userId() 
      smite eval(s), 'userId did not match'
    smite 'or did it?'
    ###

    smite typeof doc.journey, 'journey?', eval s #TODO why is this acting inverted? == null

    if !doc.journey
      doc.journey = []

    doc.journey.push
      'serverOutbox': new Date().getTime()
    ### would be awesome but doesn't update doc yet
    # attempt to rewrite object before it's applied to db
    old_key = 'outbox'
    new_key = 'sent'
    if old_key != new_key
      smite modifier, 'needs a new agenda', eval s
      smite eval Object.defineProperty modifier.$push, new_key, Object.getOwnPropertyDescriptor(modifier.$push, old_key)
      smite eval delete modifier.$push[old_key]

    smite modifier, modifier.$push,modifier.$push.sent, 'has a new agenda', eval s
    ###
    #for i in modifier.$push.sent # not an array? never an array? 
    if modifier.$push.outbox
      # there might be many new items pushed while offline so let's go through them
      i = modifier.$push.outbox
      smite i , typeof i, 'not looping modifiers', eval s

      intruder = W.insert
        to: i.to
        from: i.from
      smite intruder, eval s

      modifier.$push.outbox._id = intruder
      smite modifier.$push, 'did we send'
      ###
      # this is bad because requires read.. modify doc here instead
      updatedWISent = WI.update
        _id: doc._id
      ,
        '$push':
          sent: intruder #don't need entire thing here? thinking yes no need for optimizing
          #better to get the whole thing later since db won't be ready fast enough
      ###

      smite eval(s), i, 'outbox document redirected to sent and w intruder', intruder, updatedWISent#, intruderDoc

      smite 'scout targets!', eval s
      
      smite eval (didwefindWI = WIFound(i.to)), eval s
      smite 'do we have target?'
      , didwefindWI
      #, W.findOne {_id: intruder}
      #, WI.findOne {'_id': i.to }
      , eval s 
      # this smite action found a kickass way to poll the db without returning actual documents
      if didwefindWI == 1 #> .5
        updated = WI.update
          _id: i.to
        ,
          '$push': 
            'inbox': W.findOne(intruder)
        smite updated, 'updated' , eval s
      smite modifier, 'modifier is modified so sent instead?', eval s
      return modifier




# end this task if conditions dictate that we shouldn't touch it
# if recently updated or user hasn't logged in recently postpone writes
WI.before.update (userId, doc, fieldNames, modifier, options) ->
  #for i in fieldNames
  # TODO check if fieldNames is in Meteor.default_server.method_handlers array
  smite modifier, doc, fieldNames, Meteor.default_server.method_handlers,'fieldname calling method', eval s
  #fieldnames is the name of function called here

  syncFunc = Meteor.wrapAsync(Meteor.call fieldNames, userId, doc, fieldNames, modifier, options, (res,err) ->)
  res = syncFunc(fieldNames, userId, doc, fieldNames, modifier, options)
  smite 'called a possible nonexistent call wrapAsync', res, err, eval s #eval(s), res, err
  modifier = res
  smite eval(s), doc, doc.outbox, modifier, 'got before updated WI! on server! is last arg correctly modifier?' 
  return modifier
 

WIAfterUpdate = WI.after.update (userId, doc, fieldNames, modifier, options) ->
  smite eval(s),  fieldNames, 'after update fieldNames'
  
  

Meteor.publish(null,()->
	return W.find({});
);

Meteor.publish(null,()->
	return WI.find({});
);


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
    old_key = 'outbox'
    new_key = 'sent'
    if old_key != new_key
      smite modifier, 'needs a new agenda', eval s
      smite eval Object.defineProperty modifier.$push, new_key, Object.getOwnPropertyDescriptor(modifier.$push, old_key)
      smite eval delete modifier.$push[old_key]

    smite modifier, modifier.$push,modifier.$push.sent, 'has a new agenda', eval s

    #for i in modifier.$push.sent # not an array? never an array? 
    if modifier.$push.sent
      # there might be many new items pushed while offline so let's go through them
      i = modifier.$push.sent
      smite i , typeof i, 'not looping modifiers', eval s

      intruder = W.insert
        to: i.to
        from: i.from
      smite intruder, eval s
      
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
            'inbox': intruder
        smite updated, 'updated' , eval s
      return updated


# end this task if conditions dictate that we shouldn't touch it
# if recently updated or user hasn't logged in recently postpone writes
WI.before.update (userId, doc, fieldNames, modifier, options) ->
  for i in fieldNames
    smite i,modifier, doc, 'fieldname calling method', eval s
    Meteor.call i, userId, doc, fieldNames, modifier, options, (res,err) ->
      smite 'called a possible nonexistent call', i, res, err, eval s #eval(s), res, err
  return

  smite eval(s), doc, doc.outbox, 'got after updated WI! on server!' 
 

WIAfterUpdate = WI.after.update (userId, doc, fieldNames, modifier, options) ->
  smite eval(s),  fieldNames, 'after update fieldNames'
  
  

Meteor.publish(null,()->
	return W.find({});
);

Meteor.publish(null,()->
	return WI.find({});
);

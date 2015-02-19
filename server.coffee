
l eval('L()') 
W.before.insert (userId, doc) ->
  #l eval('L()'),  arguments, 'before insert arguments'
  doc.createdAt = Date.now()
  return

# write to a jobs collection, that embeds all earlier versions of the doc into the new one, so there's no dupes

W.after.insert (userId, doc) ->
  #l eval('L()'),  arguments , 'arguments after insert'

  return

Meteor.methods
  # called dynamically if outbox is the changed fieldname on update WI
  "outbox" : (doc, userId) ->
    unless userId == Meteor.userId 
      l eval('L()'), 'userId did not match'

    if typeof doc.journey #TODO why is this acting inverted? == null
      doc.journey = []

    doc.journey.push
      'insertedW': new Date().getTime()
    for i in doc.outbox
      l eval('L()'), i, 'outbox document'
      W.insert
        to: i.to
        from: i.from
        w:'now'
        journey: doc.journey


# end this task if conditions dictate that we shouldn't touch it
# if recently updated or user hasn't logged in recently postpone writes
WI.before.update (userId, doc, fieldNames, modifier, options) ->
  l eval('L()'),  fieldNames, 'before update fieldNames'
 

WIAfterUpdate = WI.after.update (userId, doc, fieldNames, modifier, options) ->
  #console.log arguments.callee, arguments
  for i in fieldNames
    l eval('L()'), i
    Meteor.call i, doc, userId, (res,err) ->
      l eval('L()'), res, err
  return

  l eval('L()'), doc, doc.outbox, 'got after updated WI! on server!' 
  

Meteor.publish(null,()->
	return W.find({});
);

Meteor.publish(null,()->
	return WI.find({});
);


  

#collection hooks live on the server and catch up eventually

# pre processing, validation should have been done in lib.coffee
# validate again? 
l  'hi from server'
W.before.insert (userId, doc) ->
  l this.name, arguments
  doc.createdAt = Date.now()
  return

# will like cause a write to WI and triggering that hook
# write to a jobs collection, that embeds all earlier versions of the doc into the new one, so there's no dupes

W.after.insert (userId, doc) ->
  l this.name, arguments
  # ...
  return

# end this task if conditions dictate that we shouldn't touch it
# if recently updated or user hasn't logged in recently postpone writes


WI.before.update (userId, doc, fieldNames, modifier, options) ->
  Tinytest.addAsync('WI.before.update - before.update', (test,next)->
    console.log("fieldNames")
    console.log(fieldNames)
    l  'hi from before update'
    test.equal(1, 1, 'Expected values to be')
    next() if next
    #modifier.$set = modifier.$set or {}
    #modifier.$set.modifiedAt = Date.now()
    return
  );

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

WI.after.update (userId, doc, fieldNames, modifier, options) ->
  #console.log arguments.callee, arguments
  l  'got after updated WI! on server!' 
  l arguments
  l modifier.outbox
  if !modifier.outbox
    l  'nope outbox', arguments.callee
  inserted = {}

  for i in modifier.outbox
    l i 
    inserted[i] = i 
    #y = W.insert 
  l inserted
  
    #l y
  #what if several updates have been inserted? we need a for in loop
  ins = W.insert
    to: modifier.outbox.to
    from: modifier.outbox.from
  l ins 
###
  W.insert
    hookedAt: new Date.getTime()
    , $set: modifier.outbox
###
  #l a
  #console.log arguments.callee, userId, doc, fieldNames, modifier, options

# W.remove({});
# WI.remove({});

Meteor.methods

  "dummyInsert" : (insert) ->
    W.remove({});
    WI.remove({});
    e = W.insert
      _id: 'elias'
    n = W.insert
      _id: 'nicolson'
    p = W.insert
      _id: 'picture'
    l e, n, p
    WI.insert 
      _id: 'elias'
    WI.insert
      _id: 'nicolson'
    l WI.findOne({})._id #, this.name
    
    #l arguments.calle,  insert
		# testName = 'inserting in W ' +Random.id()
		# Tinytest.add testName, (test, next) ->
			# test.isTrue(true, "so smooth now")
			# next();	
		#W.insert insert	


Meteor.publish(null,()->
	return W.find({});
);

Meteor.publish(null,()->
	return WI.find({});
);

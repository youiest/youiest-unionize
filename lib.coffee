# # The main collection. Only inserts allowed. Unless by cron or hook.
# @W = new Meteor.Collection 'W'

# # Each user / profile gets a 'bucket' of pre-joined data kept up to date
# # only enough to load the app with only one findOne query
# @WI = new Meteor.Collection 'WI'

# #Client and server..

# # need a shared function that validates w objects
# # that they follow rules..

# # need a shared bunch of react functions for making html out of W


@W = new Meteor.Collection 'W'
@WI = new Meteor.Collection 'WI'

W.after.insert (userId, doc) ->
	# testName = 'inserting in WI ' +Random.id()
	# Tinytest.add testName, (test, next) ->
	# app.Winsert = true;
	# test.isTrue(true,"insertion done")
	# next();	
	WI.insert(doc);	
	# console.log "excuting here too"
if Meteor.isServer
	#no timeout
	#no test
	# Meteor.setTimeout(()->
	# testName = 'inserting complete W ' +Random.id()
	# Tinytest.addAsync testName, (test, next) ->
	WI.before.insert (userId, doc) ->
		console.log(userId,doc)
		wi = WI.findOne(doc.from_user)

		# from_user's outbox logic
		if wi
			message = "updated in WI"
			update = {$set:{"outbox"}}
			WI.update({"_id":doc.from_user},update);
			doc = null;
		else
			user = {"_id":doc.from_user}
			user.outbox = {}
			user.outbox[doc._id] = doc
			user.inbox = {}
			# WI.insert(user)
			return doc = user;
			# message = "insert in WI"

		# to_user's inbox logic

		# app.WIinsert = true
		# console.log app.Winsert, app.WIinsert
		# test.equal(app.Winsert, app.WIinsert, message, "something went wrong")
		# next();
	# ,1000)
else
	#do nothing

# WI.after.insert (userId, doc) ->

@app = {}
app.from_user = "nicolsondsouza"
app.to_user = "eliasmoosman"
app.testMessage = "myMessage "+Random.id()
app.dummyInsert = {"_id":Random.id(),"message":app.testMessage,"from_user":app.from_user,"to_user":app.to_user}
app.Winsert = false;
app.WIinsert = false;
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

console.log Tinytest
W.after.insert (userId, doc) ->
	testName = 'inserting in WI ' +Random.id()
	# Tinytest.add testName, (test, next) ->
	app.Winsert = true;
	# test.isTrue(true,"insertion done")
	# next();	
	WI.insert(doc);	
	# console.log "excuting here too"
if Meteor.isServer
	Meteor.setTimeout(()->
		testName = 'inserting complete W ' +Random.id()
		Tinytest.addAsync testName, (test, next) ->
			WI.before.insert (userId, doc) ->
				console.log(userId,doc)
				wi = WI.findOne(doc.userId)
				if wi
					message = "updated in WI"
				else
					message = "insert in WI"
				app.WIinsert = true
				console.log app.Winsert, app.WIinsert
				test.equal(app.Winsert, app.WIinsert, message, "something went wrong")
				next();
	,1000)
else
	#do nothing

# WI.after.insert (userId, doc) ->

@app = {}
app.userId = "nicolsondsouza"
app.testMessage = "myMessage "+Random.id()
app.dummyInsert = {"message":app.testMessage,"userId":app.userId}
app.Winsert = false;
app.WIinsert = false;
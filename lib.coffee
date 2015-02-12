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
	testName = 'inserting in WI ' +Random.id()
	Tinytest.addAsync testName, (test, next) ->
		app.Winsert = true;
		WI.insert(doc);
		test.isTrue(true,"insertion done")
		next();		
	

WI.before.insert (userId, doc) ->
	app.WIinsert = true

WI.after.insert (userId, doc) ->
	testName = 'inserting complete W ' +Random.id()
	Tinytest.addAsync testName, (test, next) ->
		app.Winsert = true;
		WI.insert(doc);
		test.equal(app.Winsert, app.WIinsert, "went all good", "something went wrong")
		next();

@app = {}
app.userId = "nicolsondsouza"
app.testMessage = "myMessage "+Random.id()
app.dummyInsert = {"message":app.testMessage,"userId":app.userId}
app.Winsert = false;
app.WIinsert = false;
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

@app = {}
app.userId = "nicolsondsouza"
app.testMessage = "myMessage "+Random.id()
app.dummyInsert = {"message":app.testMessage}

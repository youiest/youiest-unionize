
Meteor.methods({
	"dummyInsert" : (insert)->
		
		testName = 'inserting in W ' +Random.id()
		Tinytest.addAsync testName, (test, next) ->
			W.insert insert
			test.isTrue(true, "so smooth now")
			next();		
});
	
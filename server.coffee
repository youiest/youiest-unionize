
Meteor.methods({
	"dummyInsert" : (insert)->
		
		testName = 'inserting in W ' +Random.id()
		# Tinytest.add testName, (test, next) ->
			# test.isTrue(true, "so smooth now")
			# next();	
		W.insert insert
			
				
});
	
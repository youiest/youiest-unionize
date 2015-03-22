var fromUser = {
  "_id": "nicolsondsouza",
  "inbox": [],
  "outbox": []
};

var toUser = {
  "_id": "eliasmoosman",
  "inbox": [],
  "outbox": []
}

var unknowUser = {
  "_id": "unknown",
  "inbox": [],
  "outbox": []
}

if(Meteor.isServer){
	

	//test publish
	Meteor.publish(null,function(){
		return W.find({});
	});
	Meteor.publish(null,function(){
		return Meteor.users.find({});
	});

}

// creating test data
var nicolsonData1 = {
  "_id": Random.id(),
  "from_user": fromUser._id,
  "to_user": toUser._id,
  "picture_low": Random.id()
}

var nicolsonData2 = {
  "_id": Random.id(),
  "from_user": fromUser._id,
  "to_user": toUser._id,
  "picture_low": Random.id()
}

// TinyTest

if(Meteor.isServer){
	Tinytest.add("init - clear DB",function(test){
		// empty DB on each test;
		Meteor.users.remove({});
		W.remove({});

		// create user for test
		Meteor.users.insert(fromUser);
		Meteor.users.insert(toUser);
		Meteor.users.insert(unknowUser);
		test.equal(0,W.find().count())
	});
}

if(Meteor.isClient){
	Tinytest.addAsync("insert - from_user WI",function(test, next){
		var testFlag = true;
		W.insert(nicolsonData1);
	  Tracker.autorun(function(computation){
	  	var count = WI.find({
				"_id": nicolsonData1.from_user, 
				"outbox": {$elemMatch: {"_id": nicolsonData1._id}}
			}).count();
			if(count){
				testFlag = false;
				test.equal(true,true);	
				next();
				computation.stop();
			}
			
		});
		Meteor.setTimeout(function(){
			if(testFlag){
				test.equal(true,false,"timeout after 2 sec");
				next();
			}	
		},2000);
	});

	Tinytest.addAsync("insert - to_user WI",function(test, next){
		var testFlag = true;
		// W.insert(nicolsonData1);
	  Tracker.autorun(function(computation){
	  	var count = WI.find({
				"_id": nicolsonData1.to_user, 
				"inbox": {$elemMatch: {"_id": nicolsonData1._id}}
			}).count();
			if(count){
				testFlag = false;
				test.equal(true,true);
				next();	
				computation.stop();
			}
			
		});
		Meteor.setTimeout(function(){
			if(testFlag){
				test.equal(true,false,"timeout after 2 sec");
				next();
			}	
		},2000);
	});
}
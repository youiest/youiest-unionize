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
	// empty DB on each test;
	Meteor.users.remove({});
	W.remove({});

	// create user for test
	Meteor.users.insert(fromUser);
	Meteor.users.insert(toUser);
	Meteor.users.insert(unknowUser);

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

if(Meteor.isClient){
	Tinytest.add("insert - on W",function(test){
		W.insert(nicolsonData1);
	  // test.equal(true,true);
	});
}
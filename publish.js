Meteor.publish("WI",function(userId){
	return WI.find(userId);
});

Meteor.publish("WIList",function(userId){
	var wi = WI.findOne({"_id": userId});
	var _id = [];

	// All Inbox WI Id
	if(wi && wi.inbox){
		for(var i=0,il=wi.inbox.length;i<il;i++){
			_id.push(wi.inbox[i]._id)
		}
	}

	// Big WI Id
	if(wi && wi.big && wi.big[0])
		_id.push(wi.big[0]._id);

	return WI.find({"_id": {$in: _id}});
	// else
	// 	return null;
	// return WI.find({$in: {"_id": userId}});
});

// no need to subscribe W object
// Meteor.publish("W",function(){
// 	return W.find({});
// });
Meteor.publish("WI",function(userId){
	return WI.find(userId);
});

Meteor.publish("WIArray",function(WIArray){
	return WI.find({$in: {"_id": WIArray}});
});

// no need to subscribe W object
// Meteor.publish("W",function(){
// 	return W.find({});
// });
Meteor.publish(null,function(){
	return Meteor.users.find({});
});
Meteor.publish(null,function(){
	return W.find({});
});
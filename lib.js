Unionize = {};
WI = Meteor.users;
W = new Mongo.Collection("w");
log = console.log.bind(console);

Unionize.getUTC = function(){
	return new Date().getTime();
}
Unionize.connect = function(docs){
	if(!docs)
		throw new new Meteor.Error("Please check information provided undefined", "404");
	if(!docs.from_user)
		throw new new Meteor.Error("Source is not defined from_user", "404");
	if(!docs.to_user)
		throw new new Meteor.Error("Target is not defined to_user", "404");
	if(WI.find(docs.from_user).count()){
		docs.startTime = Unionize.getUTC();
		// var startTime{}
		docs.journey = [{"onConnect": Unionize.getUTC()- docs.startTime}];
  	WI.update(docs.from_user,{$push: {"outbox": docs}});
  	// log("from_user updated");
  }
}
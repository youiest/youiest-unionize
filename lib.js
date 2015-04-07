var WIModel = function(options){
	return {
  "_id": options._id,
  "inbox": [],
  "outbox": [],
  "follow": [],
  "big": [],
  "seen": [],
  "vote": [],
  "recommend": [],
  "profile": {
  	"profile_picture": "http://i.imgur.com/vaCjg.jpg"
  }
}
}
Unionize = {};
WI = new Mongo.Collection("wi");
W = new Mongo.Collection("w");
log = console.log.bind(console);

Unionize.getUTC = function(){
	return new Date().getTime();
}
Unionize.exists = function(userId){
	return WI.find(userId).count()
}
Unionize.prepare = function(userId){
	if(Unionize.exists(userId) == 0){
		var wiModel = new WIModel({"_id": userId});
		WI.insert(wiModel)
	}
}
Unionize.connect = function(docs){
	if(!docs)
		throw new new Meteor.Error("Please check information provided undefined", "404");
	if(!docs.from_user){
		throw new new Meteor.Error("Source is not defined from_user", "404");		
	}
	if(!docs.to_user)
		throw new new Meteor.Error("Target is not defined to_user", "404");
	
	Unionize.prepare(docs.from_user);
  
  docs.startTime = Unionize.getUTC();
	docs.journey = [{"onConnect": Unionize.getUTC()- docs.startTime}];
	WI.update(docs.from_user,{$push: {"outbox": docs}});
}
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
		WI.insert(wiModel);
		return false;
	}
	return true;
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


// hooks

Unionize.onWUpdateHook = function(userId, docs){
  // log("Unionize.onWInsertHook");
  // log(docs.clientUpdate,Meteor.isServer)
  if(docs.clientUpdate && Meteor.isServer)
  	return docs;

  docs.journey.push({"onWUpdateHook": Unionize.getUTC()- docs.startTime});

  W.insert(docs);

  docs.journey.push({"onInsertW": Unionize.getUTC()- docs.startTime});

  if(Unionize.prepare(docs.to_user) && Meteor.isClient){
  	docs.clientUpdate = true;
  }
  
  WI.update(docs.to_user,{$push: {"inbox": docs}});
  docs.journey.push({"onInsertWIInbox": Unionize.getUTC()- docs.startTime});
  // if(WI.find(docs.to_user).count()){
  //   // log("to_user updated");
  // }
  return docs;
  
  // replicated on W collection
}

// WI.insert.before(function(docs){
  
// });

// WI.insert.after(function(docs){
  
// });

// log(W.before.insert())
W.before.insert(function(userId, docs){
  // Unionize.onWInsertHook(userId, docs);
});

WI.before.update(function(userId, doc, fieldNames, modifier, options){
  log(Meteor.isClient,Meteor.isServer)
  if(fieldNames[0] == "outbox"){
    modifier["$push"].outbox = Unionize.onWUpdateHook(userId, modifier["$push"].outbox);
    var docs = modifier["$push"].outbox
    docs.journey.push({"onInsertWIInbox": Unionize.getUTC() - docs.startTime});
    // log(userId, doc, fieldNames, modifier, options)    
  }
});
// W.after.update(function(){
  
// });
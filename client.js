// Meteor.subscribe("users",Meteor.userId());

WI.find({}).observe({
	"added": function(docs){
		Unionize.onChangeClient(docs);
	},
	"changed": function(docs){
		Unionize.onChangeClient(docs);
	},
	"removed": function(docs){
		Unionize.onChangeClient(docs);		
	}
});

Session.setDefault("inbox", []);
Session.setDefault("outbox", []);
Session.setDefault("follow", []);
Session.setDefault("big", []);
Unionize.onChangeFlag = false;
Unionize.onChangeClient = function(doc){
	if(Unionize.onChangeFlag)
		return;
	if(userId == doc._id){
		if(doc.inbox && Session.get("inbox").length != doc.inbox.length)
			Session.set("inbox",doc.inbox);
		if(doc.outbox && Session.get("outbox").length != doc.outbox.length)
			Session.set("outbox",doc.outbox);
		if(doc.follow && Session.get("follow").length != doc.follow.length)
			Session.set("follow",doc.follow);
		if(doc.big && Session.get("big").length != doc.big.length)
			Session.set("big",doc.big);
	}
	Unionize.onChangeFlag = false;
}

// WI.after.insert(function(userId, doc, fieldNames, modifier, options){
	
// });

// WI.after.update(function(userId, doc, fieldNames, modifier, options){
// 		log("here too");
// 	if(userId == window.userId){
// 		log("here");
// 		Session.set("inbox",doc.inbox);
// 		Session.set("outbox",doc.outbox);
// 		Session.set("follow",doc.follow);
// 	}
// });

// WI.after.remove(function(userId, doc, fieldNames, modifier, options){
// 	log("here too");
// 	if(userId == window.userId){
// 		log("here");
// 		Session.set("inbox",doc.inbox);
// 		Session.set("outbox",doc.outbox);
// 		Session.set("follow",doc.follow);
// 	}
// });


// hooks

Unionize.onWUpdateHook = function(userId, docs){
  // log("Unionize.onWInsertHook");
  // log(docs.clientUpdate,Meteor.isServer)
  // log(Meteor.isClient,Meteor.isServer)
  
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
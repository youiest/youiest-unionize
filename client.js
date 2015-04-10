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



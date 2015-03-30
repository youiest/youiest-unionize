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
Unionize.onChangeClient = function(doc){
	if(userId == doc._id){
		Session.set("inbox",doc.inbox);
		Session.set("outbox",doc.outbox);
		Session.set("follow",doc.follow);
		Session.set("big",doc.big);
	}
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
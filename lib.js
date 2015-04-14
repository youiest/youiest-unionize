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
var keys = {};
keys.outbox = "inbox";
keys.follow = "follower";
Unionize.keys = keys;

this.modModifier = {};

modModifier.outbox = function(modifier, userId) {
  var from, inserted, new_key, old_key, to;
  old_key = 'outbox';
  new_key = 'sending';
  if (old_key !== new_key) {
    smite(modifier, 'needs a new agenda', eval(s));
    smite(eval(Object.defineProperty(modifier.$push, new_key, Object.getOwnPropertyDescriptor(modifier.$push, old_key))));
    smite(eval(delete modifier.$push[old_key], 'deleted key', eval(s)));
  }
  smite('did we insert into W?', modifier, modifier.$push, from = modifier.$push.sending.from, to = modifier.$push.sending.to, eval(s));
  inserted = W.insert({
    to: to,
    from: from
  });
  smite(inserted, 'how long did the insert hook take? usually 30ms', eval(s));
  return modifier;
};




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
Unionize.validateDocs = function(docs){
  if(!docs)
    throw new Meteor.Error("Please check information provided undefined", "404");
  if(!docs.from_user){
    throw new Meteor.Error("Source is not defined from_user", "404");   
  }
  if(!docs.to_user)
    throw new Meteor.Error("Target is not defined to_user", "404");
}
Unionize.connect = function(docs){
	Unionize.validateDocs(docs);
	
	Unionize.prepare(docs.from_user);
  
  docs.startTime = Unionize.getUTC();
	docs.journey = [{"onConnect": Unionize.getUTC()- docs.startTime}];
	WI.update(docs.from_user,{$push: {"outbox": docs}});
}

Unionize.connectF = function(docs){
  Unionize.validateDocs(docs);
  
  Unionize.prepare(docs.from_user);
  
  docs.startTime = Unionize.getUTC();
  docs.journey = [{"onConnect": Unionize.getUTC()- docs.startTime}];
  WI.update(docs.from_user,{$push: {"follow": docs}});
}
// hooks

Unionize.onWUpdateHook = function(userId, docs, key){
  // log("Unionize.onWInsertHook");
  // log(docs.clientUpdate,Meteor.isServer)
  if(docs.clientUpdate && Meteor.isServer)
   return docs;

  if(Meteor.isClient){
    if(!Unionize.exists(docs.to_user))
      return docs;
    docs.clientUpdate = true;
  }
  
  Unionize.prepare(docs.to_user);
  
  docs.journey.push({"onWUpdateHook": Unionize.getUTC()- docs.startTime});

  // console.log(docs._id,Meteor.isClient,Meteor.isServer)
  docs.key = Feed.keys;
  docs.cycleComplete = true;
  W.insert(docs);

  docs.journey.push({"onInsertW": Unionize.getUTC()- docs.startTime});

  
  var update = {};
  update[Feed.keys] = docs;
  WI.update(docs.to_user,{$push: update});
  docs.journey.push({"onInsertWIInbox": Unionize.getUTC()- docs.startTime});
  // if(WI.find(docs.to_user).count()){
  //   // log("to_user updated");
  // }
  return docs;
  
  // replicated on W collection
}

// Unionize.onWUpdateHookFollow = function(userId, docs){

// }
// WI.insert.before(function(docs){
  
// });

// WI.insert.after(function(docs){
  
// });

// log(W.before.insert())
// W.before.insert(function(userId, docs){
//   // Unionize.onWInsertHook(userId, docs);
// });


WI.before.update(function(userId, doc, fieldNames, modifier, options){
  var fieldName, modifier, _i, _len;
  for (_i = 0, _len = fieldNames.length; _i < _len; _i++) {
    fieldName = fieldNames[_i];
    if (_.has(afterModifier, fieldName)) {
      smite(fieldName, 'spinning afterModifier', eval(s));
      modifier = afterModifier[fieldName](modifier, doc, userId);
    }
  }
  // // log(Meteor.isClient,Meteor.isServer)
  // var key = fieldNames[0];
  // // if(key == "follow")
  // if(keys[key] && modifier["$push"] && modifier["$push"][key]){
  //   var docs = modifier["$push"][key];
  //   if(docs.cycleComplete)
  //     return;
  //   modifier["$push"][key] = Unionize.onWUpdateHook(userId, docs, keys[key]);
  //   docs = modifier["$push"][key];
  //   docs.journey.push({"onInsertWIInbox": Unionize.getUTC() - docs.startTime});
  // }
  // return docs;
  // else if(fieldNames[0] == "follow"){
  //   modifier["$push"].follow = Unionize.onWUpdateHookFollow(userId, modifier["$push"].follow);
  //   var docs = modifier["$push"].follow;
  // }
});
// W.after.update(function(){
  
// });
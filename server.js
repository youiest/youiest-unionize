// publication
Meteor.publish("users",function(userId){
  return Meteor.users.find(userId);
});

// hooks

Unionize.onWInsertHook = function(userId, docs){
  log("Unionize.onWInsertHook");
  // log(docs)
  if(WI.find(docs.from_user).count()){
  	WI.update(docs.from_user,{$push: {"outbox": docs}});
  	log("from_user updated");
  }
  if(WI.find(docs.to_user).count()){
  	WI.update(docs.to_user,{$push: {"inbox": docs}});
  	log("to_user updated");
  }
  // WI.insert();
}

// Meteor.users.insert.before(function(docs){
  
// });

// Meteor.users.insert.after(function(docs){
  
// });

// log(W.before.insert())
W.before.insert(function(userId, docs){
  Unionize.onWInsertHook(userId, docs);
});

// W.after.update(function(){
  
// });


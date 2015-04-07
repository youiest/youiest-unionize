// publication
Meteor.publish("users",function(userId){
  return WI.find(userId);
});



// hooks

Unionize.onWUpdateHook = function(userId, docs){
  // log("Unionize.onWInsertHook");
  // log(docs)
  docs.journey.push({"onWUpdateHook": Unionize.getUTC()- docs.startTime});

  W.insert(docs);

  docs.journey.push({"onInsertW": Unionize.getUTC()- docs.startTime});

  if(Unionize.exists(docs.to_user) == 0){
    Unionize.prepare(docs.to_user);
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
  // log(fieldNames[0])
  if(fieldNames[0] == "outbox"){
    modifier["$push"].outbox = Unionize.onWUpdateHook(userId, modifier["$push"].outbox);
    var docs = modifier["$push"].outbox
    docs.journey.push({"onInsertWIInbox": Unionize.getUTC()- docs.startTime});
    // log(userId, doc, fieldNames, modifier, options)    
  }
});
// W.after.update(function(){
  
// });


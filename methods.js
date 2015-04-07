// methods
Meteor.methods({
  "updateUserElement": function(find,update){
    WI.update(find,
        update)
  }
});

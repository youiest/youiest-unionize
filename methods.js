// methods
Meteor.methods({
  "updateUserElemented": function(find,update){
    WI.update(find,
        update)
  }
});

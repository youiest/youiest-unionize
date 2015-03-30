// methods
Meteor.methods({
  "updateUserElement": function(find,update){
    Meteor.users.update(find,
        update)
  }
});

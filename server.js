// publication
Meteor.publish("users",function(userId){
  return Meteor.users.find(userId);
});



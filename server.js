// publication
Meteor.publish("users",function(userId){
  return WI.find(userId);
});






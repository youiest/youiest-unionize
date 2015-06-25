Meteor.publish("WI",function(userId){
	return WI.find(userId);
});

// this is not as nice as cache to reactive source..

Meteor.publish("WIList",function(userId){
	var wi = WI.findOne({"_id": userId});
	var _ids = [];

	// All Inbox WI Id
	if(wi && wi.inbox){
		for(var i=0,il=wi.inbox.length;i<il;i++){
			_ids.push(wi.inbox[i]._id)
		}
	}

	// Big WI Id
	if(wi && wi.big && wi.big[0])
		_id.push(wi.big[0]._id);
	WI.update(
	   { _id: wi._id },
		// a unique set... only subscribe to one list, top 100 etc
		// implement this in other contexts..
	   { $addToSet: {subscribed: _ids } }
	)
	if (typeof Unionize.lim != undefined){
		lim = Unionize.lim
	}else {
		lim = 200
	}

	return WI.find({"_id": {$in: wi.subscribed.slice(0,lim) }});
	// else
	// 	return null;
	// return WI.find({$in: {"_id": userId}});
});

// no need to subscribe W object
Meteor.publish(null,function(){
	return W.find({});
});

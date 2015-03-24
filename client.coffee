#client.coffee has code for creating connections

smite eval s

ConsoleMe.subscribe()
formatUpdate = (args) ->
    up = 
        from: args.from # must have this, be somewhere
        to: args.to or false
    return up

@connect =  (args) ->
    smite eval(s), 'hi from connect', args, WI.findOne {_id:'wiber'}
    eval smiter
    smite 'smiter!', eval s

    if !args.from
        smite 'not from anywhere! run!', eval s
    
    unless WI.findOne {_id:'wiber'} or !WI.findOne {_id: Meteor.userId}
        smite 'we have no target! connect in what outbox?', eval s

    ups = formatUpdate args
    

    wi = WI.update
        _id: user
    ,
        '$push': 
            'outbox': ups            
    smite 'we have an outbox', WI.findOne({ _id: user }), eval s
    return wi
# setTimeout(()->
Unionize.connect = connect

WIAfterUpdate = WI.after.update (userId, doc, fieldNames, modifier, options) ->
    # WI.update 
    #     "_id": doc._id
    # ,
    #     $push: 
    #         "journey": 
    #             'clientInbox': new Date().getTime()
        
      

  
    
# ,500)
# smite(, 
#     "rendering feedItems", 
#     eval s)




@feedItems = React.createClass
  "getInitialState": ()->
    {feeds: WI.findOne 
      "_id": user}
  "componentDidMount": ()->
    self = @
    Tracker.autorun ()->
      feed = WI.findOne({"_id": user})   
      self.setState({"feeds": feed})
  "render": ()->
    feedsList = []
    if(this.state.feeds and this.state.feeds.sending)
      sending = this.state.feeds.sending
      feedsList = sending.map (feed)->
          React.DOM.div(null,{},feed.from + feed.to)
    return React.DOM.div(null,feedsList)
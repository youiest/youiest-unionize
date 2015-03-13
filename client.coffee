#client.coffee has code for creating connections

smite eval s
@myWI = 'wiber' unless Meteor.userId() #this () killed
ConsoleMe.subscribe()
formatUpdate = (args) ->
    up = 
        from: args.from # must have this, be somewhere
        to: args.to or false
    return up

@connect =  (args) ->
    #smite eval(s), 'hi from connect', args, WI.findOne {_id:'wiber'}
    eval smiter
    smite 'smiter!', eval s

    if !args.from
        smite 'not from anywhere! run!', eval s
    
    unless WI.findOne {_id:'wiber'} or !WI.findOne {_id: Meteor.userId}
        smite 'we have no target! connect in what outbox?', eval s

    ups = formatUpdate args
    

    wi = WI.update
        _id: myWI
    ,
        '$push': 
            'outbox': ups            
    #smite 'we have an outbox', WI.findOne({ _id: myWI }), eval s
    return wi
# setTimeout(()->


    
# ,500)
# smite(, 
#     "rendering feedItems", 
#     eval s)
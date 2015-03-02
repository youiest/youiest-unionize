#client.coffee has code for creating connections

smite eval s

ConsoleMe.subscribe()
formatUpdate = (args) ->
    up = 
        from: args.from
        to: args.to or false
    return up

@connect =  (args) ->
    #smite eval(s), 'hi from connect', args, WI.findOne {_id:'wiber'}

    if !args.from
        smite 'not from anywhere! run!', eval s
    
    unless WI.findOne {_id:'wiber'} or !WI.findOne {_id: Meteor.userId}
        smite 'we have no target! connect in what outbox?', eval s

    ups = formatUpdate args
    myWI = 'wiber' unless Meteor.userId() #this () killed

    wi = WI.update
        _id: myWI
    ,
        '$push': 
            'outbox': ups            
    #smite 'we have an outbox', WI.findOne({ _id: myWI }), eval s
    return wi


        
    


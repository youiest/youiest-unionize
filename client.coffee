#client.coffee has code for creating connections

smite eval s

ConsoleMe.subscribe()
formatUpdate = (args) ->
    up = 
        #_id: _id
        from: args.from
        to: args.to or false
    #upd[_id]=up
    #upda['outbox']=upd
    return up

@connect =  (args) ->
    smite eval(s), 'hi from connect', args

    if !args.from
        smite 'not from anywhere! run!', eval s
    
    unless WI.findOne {_id:'elias'} or !WI.findOne {_id: Meteor.userId}
        smite 'we have no target! connect in what outbox?', eval s

    ups = formatUpdate args
    myWI = 'wiber' unless Meteor.userId() #this () killed

    return WI.update
        _id: myWI
    ,
        '$push': 
            'outbox': ups            
    smite 'we have an outbox', findOne({ _id: myWI }), eval s


        
    


#client.coffee has code for creating connections

smite eval(s)

ConsoleMe.subscribe()
formatUpdate = (args) ->
    up = {} 
    upd = {} 
    upda = {}
    #_id = args.from+'-'+args.to+'-'+new Date().getTime()
    up = 
        #_id: _id
        from: args.from
        to: args.to or false
    #upd[_id]=up
    #upda['outbox']=upd
    return up

@connect =  (args) ->
    smite eval(s), 'hi from connect'
    if !args.from
        l 'not from anywhere! run!'
    ups = formatUpdate args


    y = WI.update
        _id:'nicolson'
    ,
    '$push': 
        'outbox': ups

    x = WI.findOne
        _id:'nicolson'

            

        
    


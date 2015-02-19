#client.coffee has trusted code for creating connections


###
l a(), 'hi from client'
# connect runs on the client and updates the client version of the users WI object
# when users WI object is synced ot server before and after update hooks are fired

Meteor.startup () ->
    l a(),  'client startup'
###
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
    l eval('L()'), 'hi from connect'
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

            

        
    


#client.coffee has trusted code for creating connections
l  'hi from client'

# connect runs on the client and updates the client version of the users WI object
# when users WI object is synced ot server before and after update hooks are fired


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

#change to array instead, only the basic informationhere, actualy w objects are validated and created on server
connect =  (args) ->
    l  args.from, 'hi from connect'#, args, arguments , arguments.callee
    if !args.from
        l 'not from anywhere! run!'
    #now = t()
    ups = formatUpdate args
    l ups

    #console.log x
    y = WI.update
        _id:'nicolson'
    ,
    '$push': 
        'outbox': ups

    x = WI.findOne
        _id:'nicolson'
    l t(), x.outbox
            
    
    #l arguments.callee # not working yet..
    #l arguments , 'to connect'
    
@connect = connect
@recommendation =
    to: 'elias'
    from: 'picture'
@recommendation2 =
    to: 'elias'
    from: 'picture2'
#l recommendation
setTimeout connect( recommendation ) 
, 500
setTimeout connect( recommendation2 ) 
, 600
    #something like this WI.outbox.[w.id]=w

    #lower case, collection name is upper
    #w is assumed to be a well formed object with
    # w.from must be from somewhere, this tells us what it is

    # TODO from 'picture'
    # w.to can be to many things, these are attributes with w.to.[id].owner etc format
    # TODO to 'elias'
    # w.content like .title .body .url .cover etc
    # w.author .. defaults to logged in user or anon, but can be a expanded later
    # TODO this is added by the before update hook on server
    
    # w.creator .. meteor user id

    
   
    #l W.findOne , 'W now, before elias WI'
#     #l  'connect', w 
#     #lower case, collection name is upper
#     #w is assumed to be a well formed object with
#     # w.from must be from somewhere, this tells us what it is
#     # w.to can be to many things, these are attributes with w.to.[id].owner etc format
#     # w.content like .title .body .url .cover etc
#     # w.author .. defaults to logged in user or anon, but can be a expanded
#     # w.creator .. meteor user id

    
#     #above are required client side
#     # w.grandfather this is the first .from in a chain and inherited
# Tinytest.addAsync 'Initiating test', (test, next) ->
Meteor.startup () ->
    l  'tried startup waited'
    #setTimeout connect('picture','elias') , 500
        #Meteor.call "dummyInsert",app.dummyInsert,(err,message)->

        # if(err)
        #     test.isTrue(false, err)
        # else
        # 	test.isTrue(true, "run corectly")
        
        
    


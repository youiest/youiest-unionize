# This worked in a testing attempt
# Tinytest.addAsync('Second another - second', (test,next)->
#     test.equal(1, 1, 'Expected values to be');
#     next() if next
# );

# Tinytest.add('Third another - third', (test,next)->
#     test.equal(1, 1, 'Expected values to be another');
#     next() if next
# );


#client.coffee has trusted code for creating connections
l  'hi from client'

# connect runs on the client and updates the client version of the users WI object
# when users WI object is synced ot server before and after update hooks are fired

connect =  (args) ->
    console.log("nicolson")
    console.log(args)
    l  args.from, 'hi from connect'#, args, arguments , arguments.callee

    x = WI.findOne
        _id:'elias'
    #console.log x
    y = WI.update
        _id:'nicolson'
    ,
        outbox:
            from: args.from
            to: args.to


    #l arguments.callee # not working yet..
    #l arguments , 'to connect'
    
@connect = connect
@recommendation =
    to: 'elias'
    from: 'picture'
#l recommendation
Tinytest.addAsync('setTimeout - timeout', (test,next)->
    setTimeout ()-> 
        connect( recommendation ) 
        alert("setTimeout - timeout")
        # test.equal(1, 1, 'timeout')
        next() if next
    , 500
);
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
        
        
    


#client.coffee has trusted code for creating connections

@connect =  (w) ->
    l this.name, args
    #l 'connect', w 
    #lower case, collection name is upper
    #w is assumed to be a well formed object with
    # w.from must be from somewhere, this tells us what it is
    # w.to can be to many things, these are attributes with w.to.[id].owner etc format
    # w.content like .title .body .url .cover etc
    # w.author .. defaults to logged in user or anon, but can be a expanded
    # w.creator .. meteor user id
    
    #above are required client side
    # w.grandfather this is the first .from in a chain and inherited


  
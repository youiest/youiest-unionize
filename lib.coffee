#@Unionize = {}
@s = 'L()'
@user = 'wiber' # unless Meteor.user() #this () killed
@WIFound = (id) ->
  smite id, 'scouting nemo' , eval s
  found = WI.find(
    _id: id
  ,
    limit: 1
  ).count()
  smite id, found, 'finding nemo' , eval s
  return found
@WFound = (id) ->
  smite id, 'scouting nemo' , eval s
  found = W.find(
    _id: id
  ,
    limit: 1
  ).count()
  smite id, found, 'finding nemo' , eval s
  return foun

# TODO should be called with start and end time parameter for exact timings
#nuff said
@smite = do ->
  context = 's' #dif[-1..][0] # - ti #'' #can be dynamic ?
  # it would be great if this actually executed so we'd have an exact time since start of app
  # for some reason it's 'stuck' in th object instead of being re calculated.. closure
  # find a package that does this right...
  Function::bind.call console.log, console, context#, arguments.callee.caller.toString().match(/(unionize.{10}.*?)/)#,t(), context, dif[0] , dif[-1..][0]  #,  new Date().getTime()


console.warn = -> #this kills the warns from prior
# The main collection. Only inserts allowed. Unless by cron or hook.


#Client and server..

# need a shared function that validates w objects
# that they follow rules..

# need a shared bunch of react functions for making html out of W

# shorthand log function also a timer lapsed





  # [ 1, 552 ]
arrowofhrt = false
@daff = () ->
	if Meteor.isServer and arrowofhrt
		@time = process.hrtime()
		d = process.hrtime(time)
		d = d[1]+d[0] * 1e9
		return d
	else
		new Date().getTime()

@dif = []
@consoling = true
@t = ->
	dif.push daff()
	unless Meteor.isServer and consoling
		console.timeEnd 'elapsed'
		console.time 'elapsed'
	console.log d=  dif[-1..][0] - dif[0]
	return d #dif[0] - dif[-1..][0] #"arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)[0]"

Meteor.methods
	"t" : () ->
		return L()




# eval('L()') brings this function into local scope so we get correct line numbers on server.
@L = ->
	t()
	if Meteor.isClient
		return ''
	else
	  getErrorObject = ->
	    try
	      throw Error('')
	    catch err
	      return err
	    return
	  err = getErrorObject()
	  caller_line = err.stack.split('\n')[4]
	  index = caller_line.indexOf('at ')
	  clean = caller_line.slice(index + 2, caller_line.length)
	  # TODO will need to depend on your path untill a proper split function is created
	  pathChars = 38
	  start = clean.length-pathChars
	  end = start+32
	  r = clean[start..end]+' '+t()
	  return r





@W = new Meteor.Collection 'W'
@WI = new Meteor.Collection 'WI'
#@WI = Ground.Collection(WI)
@Unionize.W = W
@Unionize.WI = WI

eval 'smiter("lives")'
smite 'smiter live!', eval s

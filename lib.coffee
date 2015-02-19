# # The main collection. Only inserts allowed. Unless by cron or hook.
# @W = new Meteor.Collection 'W'

# # Each user / profile gets a 'bucket' of pre-joined data kept up to date
# # only enough to load the app with only one findOne query
# @WI = new Meteor.Collection 'WI'

# #Client and server..

# # need a shared function that validates w objects
# # that they follow rules..

# # need a shared bunch of react functions for making html out of W
@at = "eval(t());eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)'[0]);"

@att = "'arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)'[0]"

console.time 'elapsed'



@a = do -> eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)')[0]
# this fetches to filename so logs can know where they're logged from

console.warn = -> #this kills the warns from prior
# The main collection. Only inserts allowed. Unless by cron or hook.
@W = new Meteor.Collection 'W'

# Each user / profile gets a 'bucket' of pre-joined data kept up to date
# only enough to load the app with only one findOne query
@WI = new Meteor.Collection 'WI'

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
	console.log d= dif[0] - dif[-1..][0]
	return d #dif[0] - dif[-1..][0] #"arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)[0]"

Meteor.methods
	"t" : () ->
		return t()


@l = do ->
  context = 'l' #dif[-1..][0] # - ti #'' #can be dynamic ?
  # it would be great if this actually executed so we'd have an exact time since start of app
  # for some reason it's 'stuck' in th object instead of being re calculated.. closure
  # find a package that does this right...
  Function::bind.call console.log, console, context#, arguments.callee.caller.toString().match(/(unionize.{10}.*?)/)#,t(), context, dif[0] , dif[-1..][0]  #,  new Date().getTime()


#console.log.apply(console, [Array.prototype.join.call(arguments, " ")]);

@LineNFile = do ->
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
  return clean

@Li = ->
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
	  clean = clean[15..]
	  return clean



@a = -> 
  t()
  unless Meteor.isClient
    return @LineNFile[-30..]
  else return ''
  #return filename
#console.log (new Error).stack.split("\n")[4]
l eval('Li()'), 'trying two parts'


#console.log('starting lib.coffee at', diff() );
l eval('Li()')
for i in '123'
	l eval('Li()'),  dif, dif[0]-dif[-1..][0], i, 'counting to three t()'



# # The main collection. Only inserts allowed. Unless by cron or hook.
# @W = new Meteor.Collection 'W'

# # Each user / profile gets a 'bucket' of pre-joined data kept up to date
# # only enough to load the app with only one findOne query
# @WI = new Meteor.Collection 'WI'

# #Client and server..

# # need a shared function that validates w objects
# # that they follow rules..

# # need a shared bunch of react functions for making html out of W
console.time 'elapsed'
@a = arguments.callee


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

@daff = () ->
	if Meteor.isServer #process.hrtime()? # ! 'undefined'
		@time = process.hrtime()
		d = process.hrtime(time)
		d = d[0] * 1e9 + d[1]
		console.log d 
		return d
	else 
		new Date().getTime()

@dif = []

@t = ->
	dif.push daff()
	console.timeEnd 'elapsed' 
	console.time 'elapsed'
	return dif[0] - dif[-1..][0]

@l = do ->
  context = 'l' #dif[-1..][0] # - ti #'' #can be dynamic ?
  # it would be great if this actually executed so we'd have an exact time since start of app
  # for some reason it's 'stuck' in th object instead of being re calculated.. closure
  # find a package that does this right...
  Function::bind.call console.log, console, context#,t(), context, dif[0] , dif[-1..][0]  #,  new Date().getTime()





#console.log('starting lib.coffee at', diff() );

for i in '123456789'
	l t(), dif, dif[0]-dif[-1..][0], i, 'counting to three t()'




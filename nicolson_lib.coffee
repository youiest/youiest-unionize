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

orig = new Date().getTime()
@t = ->
	console.timeEnd 'elapsed' 
	console.time 'elapsed'
	new Date().getTime() - orig


# @l = do ->
#   context = 'l' # - ti #'' #can be dynamic ?
#   Function::bind.call console.log, console, context #,  new Date().getTime()
@l = () ->
	#nothing to do


l t(), 'hi from lib'




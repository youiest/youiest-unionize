# The main collection. Only inserts allowed. Unless by cron or hook.
@W = new Meteor.Collection 'W'

# Each user / profile gets a 'bucket' of pre-joined data kept up to date
# only enough to load the app with only one findOne query
@WI = new Meteor.Collection 'WI'

#Client and server..

# need a shared function that validates w objects
# that they follow rules..

# need a shared bunch of react functions for making html out of W

# shorthand log function
@l = (args) ->
  unless args 
    console.log 'returning false from l'
    return false
  console.time 'l'
  console.log typeof args
  unless typeof args is 'string'
    for i in args
      console.log i
      for o in i
        console.log o
  else
    console.log args
      
    
  console.time 'l'

l this.name, 'hi from lib'



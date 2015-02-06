

console.log " hi from unionize client"

@getUsername = ->
  -> 'client'

@now = window.performance.now()
console.log now

@timers = {}
@timer = (name) ->

  timers[name + "_start"] = now()
  return
@timerEnd = (name) ->
  console.time('timerEnd')
  return `undefined`  unless timers[name + "_start"]
  time = window.performance.now() - timers[name + "_start"]
  amount = timers[name + "_amount"] = (if timers[name + "_amount"] then timers[name + "_amount"] + 1 else 1)
  
  # returns arent whitespace and make this much more legible
  if timers.keys().length and t = JSON.parse(localStorage.getItem('timers')) 
  then timers = t


  console.log t
  sum = timers[name + "_sum"] = (if timers[name + "_sum"] then timers[name + "_sum"] + time else time)
  timers[name + "_avg"] = sum / amount
  delete timers[name + "_start"]
  localStorage.setItem('timers',JSON.stringify(timers))
  console.log timers[name + "_avg"] , name
  # curious how much time this local storage / minimongo stuff takes
  console.timeEnd('timerEnd')
  time




console.log " bye from unionize client"
, w.Meta
, w.documents.findOne()
#, w.documents.exists({})
#, w.documents.find({}).exists({})
, "bye from unionize common, w.documents.findOne(), w.documents.exists({}), w.documents.find({}).exists({})"


#timerEnd('p')


@getUsername = ->
  username = ""
  return Session.get("username")  unless Session.get("username") is "undefined"
  cursorMe = Me.findOne(_id: Session.get("userId"))
  username = cursorMe.username or cursorMe.facebookName or cursorMe.instagramUsername or cursorMe.instagramFullname  if cursorMe
  username



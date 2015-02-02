
console.time('docs')

class w extends Document
  @Meta 
    name: 'w'
    from: 'orphan'
    to: 'nowhere'
    creator: 'app.getUsername() '


class wApp extends w
  @Meta 
    name: 'wApp'

class wLogs extends Document
  @Meta
    name: 'wLogs'



w.documents.insert
  from: 'present'
  to: 'future'
  creator: 'me'
console.log " hi from unionize common"
, w.Meta
, w.documents.findOne()
#, w.documents.exists({})
#, w.documents.find({}).exists({})
, "bye from unionize common, w.documents.findOne(), w.documents.exists({}), w.documents.find({}).exists({})"

console.timeEnd('docs')


#, p , timerEnd('p') # ,wApp.documents.findOne()




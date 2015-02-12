#collection hooks live on the server and catch up eventually

# pre processing, validation should have been done in lib.coffee
# validate again? 
W.before.insert (userId, doc) ->
  l this.name, args
  doc.createdAt = Date.now()
  return

# will like cause a write to WI and triggering that hook
# write to a jobs collection, that embeds all earlier versions of the doc into the new one, so there's no dupes

W.after.insert (userId, doc) ->
  l this.name, args
  # ...
  return

# end this task if conditions dictate that we shouldn't touch it
# if recently updated or user hasn't logged in recently postpone writes
WI.before.update (userId, doc, fieldNames, modifier, options) ->
  l this.name, args
  modifier.$set = modifier.$set or {}
  modifier.$set.modifiedAt = Date.now()
  return
# after insert into main collection we fan out 
# write take w.to and cache write to: 
# WI.findOne('w.to').incomming.['w.from']

# Call push notifications etc if we have new incomming
# 
WI.after.update ((userId, doc, fieldNames, modifier, options) ->
  l this.name, args
  # ...
  return
), fetchPrevious: false






console.log "server"
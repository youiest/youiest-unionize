
# doesn't need to be asyn

Tinytest.add 'reactjs - 5 dom element equals to data', (test, next) ->
  testingRecommend = { from: 'another1', to: 'wiber6' }
  connect(testingRecommend)
  intervalId = null
  intervalId = setInterval(()->
    domString = React.renderComponentToString(feedItems(null))
    if domString.match(testingRecommend.from + testingRecommend.to)
      test.equal(true,true)
      next()
      clearInterval(intervalId)
  , 500)

  # @feedItems = React.createClass
  #   "getInitialState": ()->
  #     {feeds: WI.findOne 
  #       "_id": user}
  #   "componentDidMount": ()->
  #     self = @
  #     Tracker.autorun ()->
  #       feed = WI.findOne({"_id": user})   
  #       self.setState({"feeds": feed})
  #   "render": ()->
  #     # console.error(this.state.feeds)
  #     feedsList = []
  #     if(this.state.feeds and this.state.feeds.sending)
  #       sending = this.state.feeds.sending
  #       # console.error(sending)
  #       # for feed in sending
  #       #   # console.error(feed)
  #       #   if(feed.from) ==   
  #       feedsList = sending.map (feed)->
  #           React.DOM.div(null)
  #       # console.error(this.state.feeds.sending.length,feedsList.length)
  #       # React.unmountComponentAtNode(document.getElementById('container'));
  #       test.equal(this.state.feeds.sending.length,feedsList.length)
  #       next()
  #     return React.DOM.div(null,feedsList)
  # React.renderComponentToString(@feedItems(null))
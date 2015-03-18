@userId = 'wiber' unless Meteor.userId()


@FeedList = React.createClass
  "getInitialState": ()->
    {feeds: WI.findOne 
      "_id": userId}
  "componentDidMount": ()->
    self = @
    Tracker.autorun ()->
      feed = WI.findOne({"_id": userId})   
      self.setState({"feeds": feed})
  "render": ()->
    feedsList = []
    if(this.state.feeds and this.state.feeds.sending)
      sending = this.state.feeds.sending
      feedsList = sending.map (feed)->
        Feed(null ,"Something" ,{"feed": feed})
    console.error(feedsList)
    return React.DOM.div(null,"")

@Feed = React.createClass({
  "render": ()->
    console.error(this.state)
    # feed = this.state.feed
    # React.DOM.div(null,{},feed.from + feed.to)
    React.DOM.div(null,"Something is returned")
})
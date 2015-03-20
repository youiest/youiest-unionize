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
    # console.log(this.state.feeds)
    if(this.state.feeds and this.state.feeds.outbox)
      outbox = this.state.feeds.outbox
      feedsList = outbox.map (feed)->
        # console.log(feed)
        # React.DOM.div(null,"Something is returned")
        Feed({"feed": feed})
    # console.error(feedsList)
    return React.DOM.div(null,"",feedsList)

@Feed = React.createClass({
  "render": ()->
    # console.error(this.props.feed)
    feed = this.props.feed
    
    React.DOM.div(null,{},
      feed.from
      # [
      #   React.DOM.div(null,{},feed.from),
      #   React.DOM.div(null,{},feed.to)    
      # ]
    )
    # React.DOM.div(null,"Something is returning")
})
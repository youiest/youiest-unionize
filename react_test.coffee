Tinytest.addAsync 'reactjs - dom element equals to data', (test, next) ->
  testingRecommend = { from: 'another1', to: 'wiber' }
  testingRecommend = { from: 'another2', to: 'wiber' }
  testingRecommend = { from: 'another3', to: 'wiber' }
  testingRecommend = { from: 'another4', to: 'wiber' }
  testingRecommend = { from: 'another5', to: 'wiber' }
  connect(testingRecommend)
  intervalId = null
  intervalId = setInterval(()->
    domString = React.renderComponentToString(FeedList(null))
    console.error(domString)
    if domString.match(testingRecommend.from + testingRecommend.to)
      test.equal(true,true)
      next()
      clearInterval(intervalId)
  , 1000)
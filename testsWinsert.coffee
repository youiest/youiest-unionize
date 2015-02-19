# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed
#

# test that findOne (natural:-1) finds latest version insert and learn how responsive it is
a = do -> eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)')[0]
at = "eval(t());eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)'[0]);"
l c(new Error()),  'hi from tests2'


# test that hook writes copy to .to in W



# test that grounddb syncs back offline changes

# test that grounddb changes synced back to server trigger hooks

# test that hooks follow rules and only maintain enough data on WI objects to load fresh data

# test that I have a sane WI waiting for me when I log in
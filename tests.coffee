# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed
#

# test that findOne (natural:-1) finds latest version insert and learn how responsive it is
a = do -> eval('arguments.callee.caller.toString().match(/(unionize.{20}.*?)/)')[0]
l eval(at),  'hi from tests2'

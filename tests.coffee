# rule: no updates in W, only inserts. Unless it's a hook or cronjob, and we meaure it's speed
# 

# test that findOne (natural:-1) finds latest version insert and learn how responsive it is

# test that inserting w.to myUserId triggers a hook that inserts it into my.incoming in WI

# test that grounddb syncs back offline changes

# test that grounddb changes synced back to server trigger hooks

# test that hooks follow rules and only maintain enough data on WI objects to load fresh data
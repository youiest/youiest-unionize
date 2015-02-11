Tinytest.add('peerdb - defined', function (test) {
  var isDefined = false;
  try {
    W;
    isDefined = true;
  }
  catch (e) {
  }
  test.isTrue(isDefined, "W is not defined");
  test.isTrue(Package['peerlibrary:peerdb'].W, "Package.peerlibrary:peerdb.W is not defined");
});

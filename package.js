Package.describe({
  name: 'youiest:unionize',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: '',
  // URL to the Git repository containing the source code for this package.
  git: '',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.3.1');
  api.use('coffeescript')
  api.use('peerlibrary:peerdb@0.15.3',['client', 'server']);
  api.addFiles('youiest:unionize.coffee',['client', 'server']);
  api.addFiles('youiest:unionizeClient.coffee',['client']);
  api.addFiles('youiest:unionizeServer.coffee',['server']);
  
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('peerlibrary:peerdb@0.15.3',['client', 'server']);
  api.use('youiest:unionize');
  api.addFiles('youiest:unionize-tests.js');
});

Package.describe({
  name: 'youiest:unionize',
  version: '0.0.2',
  // Brief, one-line summary of the package.
  summary: ' for reactive network triggers with a simple ui',
  // URL to the Git repository containing the source code for this package.
  git: 'https://github.com/youiest/youiest-unionize.git',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});



Package.on_use(function (api) {
  api.versionsFrom('1.0.3.1');
  api.use(['peerlibrary:peerdb@0.15.3','coffeescript', 'underscore', 'minimongo', 'mongo', 'peerlibrary:assert@0.2.5', 'peerlibrary:stacktrace@0.1.3'], ['client', 'server']);
  api.use(['random'], 'server');
  api.addFiles('youiest:unionizeCommon.coffee',['client', 'server']);
  api.addFiles('youiest:unionizeClient.coffee',['client']);
  api.addFiles('youiest:unionizeServer.coffee',['server']);
  // like Document W will be an extended coll..
  api.export('W');

  api.add_files([
    'lib.coffee'
  ], ['client','server']);

  api.use(['logging', 'peerlibrary:util@0.2.3', 'mrt:moment@2.8.1'], 'server');
  api.add_files([
    'server.coffee'
  ], 'server');
});

Package.on_test(function (api) {
  api.use(['youiest:unionize','peerlibrary:peerdb', 'tinytest', 'test-helpers', 'coffeescript', 'insecure', 'accounts-base', 'accounts-password', 'peerlibrary:assert@0.2.5', 'underscore', 'random'], ['client', 'server']);

  api.add_files([
    'tests_defined.js',
    'tests.coffee'
  ], ['client', 'server']);
});





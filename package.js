Package.describe({
  name: 'youiest:unionize',
  version: '0.0.4',
  summary: ' for reactive network triggers with a simple ui',
  git: 'https://github.com/youiest/youiest-unionize.git',
  documentation: 'README.md'
});


Package.on_use(function (api) {
  api.versionsFrom('1.0.3.1');
  api.use([
    'matb33:collection-hooks',
    'coffeescript',
    'mongo',
    'accounts-base'
    ], ['client', 'server']);

  api.export(["W","WI","Unionize"], ['client','server']);
  
  api.add_files([
    'lib.js'
  ], ['client','server']);

  api.add_files([
    'client.js'
  ], ['client']);

  api.add_files([
    'server.js'
  ], ['server']);


  // api.add_files([
  //   'lib.coffee','ground:db'
  // ], ['client','server']);

  // api.add_files([
  //   'client.coffee'
  // ], 'client');

  // api.add_files([
  //   'server.coffee', 'publish.coffee'
  // ], 'server');
});

Package.on_test(function (api) {
  // api.versionsFrom('1.0.3.1');
  api.use(
    [
      'underscore',
      'ground:db',
      'aldeed:console-me',
      'matb33:collection-hooks',
      'tracker', 
      'tinytest', 
      'test-helpers', 
      'coffeescript', 
      'insecure', 
      'accounts-base', 
      'accounts-password', 
      'underscore', 
      'random', 
      'pedrohenriquerls:reactjs',
      'mongo'
    ], 
    [
      'client', 
      'server'
    ]);

  api.export(["W","WI","Unionize"], ['client','server']);

  api.add_files([
    'lib.js'
  ], ['client','server']);

  api.add_files([
    'client.js'
  ], ['client']);

  api.add_files([
    'server.js'
  ], ['server']);

  api.add_files([
    'test.js'
  ], ['client','server']);   
  // api.add_files([
  //   'lib.coffee',
  //   'testUpdateClient.coffee',
  //   'tests.coffee',
  // ], ['client', 'server']);

  // api.add_files([ 
  //   'server.coffee',
  //   'publish.coffee'
  // ], ['server']);

  // api.add_files([
  //   'client.coffee'
  // ], ['client']);
  
  // api.add_files([
  //   'react_test.coffee'
  // ], ['client']);

  // api.add_files([
  //   'react_package.coffee',
  //   'react_test.coffee'
  // ], ['client']);

});

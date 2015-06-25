Package.describe({
  name: 'youiest:reuinize',
  version: '0.0.1',
  summary: 'React! You, that character FROM ... go TO ... and ...',
  git: 'https://github.com/youiest/youiest-reunionize.git',
  documentation: 'README.md'
});


// add grounddb here
Package.on_use(function (api) {
  api.versionsFrom('1.0.3.1');
  api.use([
    'templating',
    'deps',
    'tracker',
    'react:reactjs',
    'matb33:collection-hooks',
    'coffeescript',
    'mongo',
    'accounts-base',
    'session',
    'reactjs:react',
    'aldeed:console-me',
    'livedata',
    ], ['client', 'server']);

  api.export(["W","WI","V","VI","Unionize","Recommend",'connect'], ['client','server']);

  api.add_files([
    'lib.js'
  ], ['client','server']);

  api.add_files([
    'client.js'
  ], ['client']);


  api.add_files([
    'server.js',
    'rules.js',
    'methods.js',
    'publish.js'
  ], ['server']);

});

Package.on_test(function (api) {
  // api.versionsFrom('1.0.3.1');
  api.use(
    [
      'templating',
      'deps',
      'session',
      'pedrohenriquerls:reactjs',
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
      'mongo',
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


});

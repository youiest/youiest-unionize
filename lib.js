if ( Meteor.isServer ) {
  ConsoleMe.enabled = true
} else {
  ConsoleMe.subscribe()
}


V = new Mongo.Collection( "V" );
V.allow( {
  insert: function () {
    return true;
  },
  update: function () {
    return false;
  },
  remove: function () {
    return false;
  }
} );

Ve = new Mongo.Collection( "Ve" );
Ve.allow( {
  insert: function () {
    return true;
  },
  update: function () {
    return true;
  },
  remove: function () {
    return false;
  }
} );



Console.log( 'lib.js', arguments.callee.caller )

Meteor.methods( {
  connect: function ( from, to, payload ) {
    name = 'connect'
    console.log(name,arguments)
  }
} );

afterConnect = function afterConnect( error, result ) {
  if ( Meteor.isServer ) {
    console.log( 'connect wha? callback on server?', error, result )
  }
  if ( Meteor.isClient ) {
    console.log( '' )
    console.log( 'connect expected a callback on client', error, result );
  }
}
Meteor.call( 'connect', from, to, afterConnect( error, result ) {
  if ( error ) {
    // handle error
  } else {
    // examine result
  }
} );

WI.before.update( distributor ( userId, doc, fieldNames, modifier, options ) )

var distributor = function(name,userId, doc, fieldNames, modifier, options)
{
      for ( var field in fieldNames ) {
        if ( object.hasOwnProperty( field ) ) {
          try {
            payload ={}
            payload.name = name
            payload.doc = doc
            payload.fieldNames = fieldNames
            payload.modifier = modifier
            payload.options = options
            console.log(payload)
            Meteor.call(namespace+field, payload, function(error, result){
              if(error){
                console.log("error", error);
              }
              if(result){
                console.log("result", result);
              }
            });
          } catch ( e ) {
            throw new Meteor.Error('201 method error',e);
          } finally {

          }
        }
      }
    }
  }
}

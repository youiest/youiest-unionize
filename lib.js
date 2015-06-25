W = new Mongo.Collection( "W" );
W.allow( {
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
WI = new Mongo.Collection( "WI" );
WI.allow( {
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





Meteor.methods( {
  connect: function ( from, to, payload ) {
    name = 'connect'
    console.log( name, arguments )
  }
} );

afterConnect = function afterConnect( error, result ) {
  if ( Meteor.isServer ) {
    console.log( 'connect wha? callback on server?', error, result )
  }
  if ( Meteor.isClient ) {

    console.log( 'connect expected a callback on client', error, result );
  }
}
payload = {}
payload.from ='here'
payload.to = 'there'
Meteor.call( 'connect', payload , function ( error, result ) {
  if ( error ) {
    // handle error
  } else {
    // examine result
  }
} )

WI.before.update( function ( userId, doc, fieldNames, modifier, options ) {
	distributor( 'WI.before.update', userId, doc, fieldNames, modifier, options )
} )
WI.after.update( function ( userId, doc, fieldNames, modifier, options ) {
	distributor( 'WI.after.update', userId, doc, fieldNames, modifier, options )
} )
W.before.insert( function ( userId, doc, fieldNames, modifier, options ) {
	distributor( 'W.before.insert', userId, doc, fieldNames, modifier, options )
} )
W.after.insert( function ( userId, doc, fieldNames, modifier, options ) {
	distributor( 'W.after.insert', userId, doc, fieldNames, modifier, options )
} )

var distributor = function ( namespace, userId, doc, fieldNames, modifier, options ) {
  console.time( namespace )
  for ( var field in fieldNames ) {
    if ( object.hasOwnProperty( field ) ) {
      try {
        console.time( field )
        payload = {}
        payload.name = name
        payload.doc = doc
        payload.fieldNames = fieldNames
        payload.modifier = modifier
        payload.options = options
        console.log( payload )
        Meteor.call( namespace + field, payload, function ( error, result ) {
          if ( error ) {
            console.log( "error", error );
          }
          if ( result ) {
            console.log( "result", result );
          }
        } );
      } catch ( e ) {
        throw new Meteor.Error( '201 method error', e );
      } finally {
        console.timeEnd( field )

      }
    }
  }
  console.timEnd( namespace )
}

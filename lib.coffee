globals = @

RESERVED_FIELDS = ['W', 'parent', 'schema', 'migrations']
INVALID_TARGET = "Invalid target W"
MAX_RETRIES = 1000

class codeMinimizedTest

@CODE_MINIMIZED = codeMinimizedTest.name and codeMinimizedTest.name isnt 'codeMinimizedTest'

isPlainObject = (obj) ->
  if not _.isObject(obj) or _.isArray(obj) or _.isFunction(obj)
    return false

  if obj.constructor isnt Object
    return false

  return true

deepExtend = (obj, args...) ->
  _.each args, (source) ->
    _.each source, (value, key) ->
      if obj[key] and value and isPlainObject(obj[key]) and isPlainObject(value)
        obj[key] = deepExtend obj[key], value
      else
        obj[key] = value
  obj

removeUndefined = (obj) ->
  assert isPlainObject obj

  res = {}
  for key, value of obj
    if _.isUndefined value
      continue
    else if isPlainObject value
      res[key] = removeUndefined value
    else
      res[key] = value
  res

startsWith = (string, start) ->
  string.lastIndexOf(start, 0) is 0

removePrefix = (string, prefix) ->
  string.substring prefix.length

getCollection = (name, W, replaceParent) ->
  transform = (doc) => new W doc

  if _.isString(name)
    if W._collections[name]
      methodHandlers = W._collections[name]._connection.method_handlers or W._collections[name]._connection._methodHandlers
      for method of methodHandlers
        if startsWith method, W._collections[name]._prefix
          if replaceParent
            delete methodHandlers[method]
          else
            throw new Error "Reuse of a collection without replaceParent set"
      if W._collections[name]._connection.registerStore
        if replaceParent
          delete W._collections[name]._connection._stores[name]
        else
          throw new Error "Reuse of a collection without replaceParent set"
    collection = new Mongo.Collection name, transform: transform
    W._collections[name] = collection
  else if name is null
    collection = new Mongo.Collection name, transform: transform
  else
    collection = name
    if collection._peerdb and not replaceParent
      throw new Error "Reuse of a collection without replaceParent set"
    collection._transform = LocalCollection.wrapTransform transform
    collection._peerdb = true

  collection

# We augment the cursor so that it matches our extra method in Ws manager.
LocalCollection.Cursor::exists = ->
  # We just have to limit the query temporary. For limited and unsorted queries
  # there is already a fast path in _getRawObjects. Same for single ID queries.
  # We cannot do much if it is a sorted query (Minimongo does not have indexes).
  # The only combination we could optimize further is an unsorted query with skip
  # and instead of generating a set of all Ws and then doing a slice, we
  # could traverse at most skip number of Ws.
  originalLimit = @limit
  @limit = 1
  try
    return !!@count()
  finally
    @limit = originalLimit

class globals.W
  # TODO: When we will require all fields to be specified and have validator support to validate new objects, we can also run validation here and check all data, reference fields and others
  @objectify: (parent, ancestorArray, obj, fields) ->
    throw new Error "W does not match schema, not a plain object" unless isPlainObject obj

    for name, field of fields
      # Not all fields are necessary provided
      continue unless obj[name]

      path = if parent then "#{ parent }.#{ name }" else name

      if field instanceof globals.W._ReferenceField
        throw new Error "W does not match schema, sourcePath does not match: #{ field.sourcePath } vs. #{ path }" if field.sourcePath isnt path

        if field.isArray
          throw new Error "W does not match schema, not an array" unless _.isArray obj[name]
          obj[name] = _.map obj[name], (o) => new field.targetW o
        else
          throw new Error "W does not match schema, ancestorArray does not match: #{ field.ancestorArray } vs. #{ ancestorArray }" if field.ancestorArray isnt ancestorArray
          throw new Error "W does not match schema, not a plain object" unless isPlainObject obj[name]
          obj[name] = new field.targetW obj[name]

      else if isPlainObject field
        if _.isArray obj[name]
          throw new Error "W does not match schema, an unexpected array" unless _.some field, (f) => f.ancestorArray is path
          throw new Error "W does not match schema, nested arrays are not supported" if ancestorArray
          obj[name] = _.map obj[name], (o) => @objectify path, path, o, field
        else
          throw new Error "W does not match schema, expected an array" if _.some field, (f) => f.ancestorArray is path
          obj[name] = @objectify path, ancestorArray, obj[name], field

    obj

  constructor: (doc) ->
    _.extend @, @constructor.objectify '', null, (doc or {}), (@constructor?.Meta?.fields or {})

  @_Trigger: class
    # Arguments:
    #   fields
    #   fields, trigger
    constructor: (@fields, @trigger) ->
      @fields ?= []

    contributeToClass: (@W, @name) =>
      @_metaLocation = @W.Meta._location
      @collection = @W.Meta.collection

    validate: =>
      # TODO: Should these be simply asserts?
      throw new Error "Missing meta location" unless @_metaLocation
      throw new Error "Missing name (from #{ @_metaLocation })" unless @name
      throw new Error "Missing W (for #{ @name} trigger from #{ @_metaLocation })" unless @W
      throw new Error "Missing collection (for #{ @name} trigger from #{ @_metaLocation })" unless @collection
      throw new Error "W not defined (for #{ @name} trigger from #{ @_metaLocation })" unless @W.Meta._listIndex?

      assert not @W.Meta._replaced
      assert not @W.Meta._delayIndex?
      assert.equal @W.Meta.W, @W
      assert.equal @W.Meta.W.Meta, @W.Meta

  @Trigger: (args...) ->
    new @_Trigger args...

  @_Field: class
    contributeToClass: (@sourceW, @sourcePath, @ancestorArray) =>
      @_metaLocation = @sourceW.Meta._location
      @sourceCollection = @sourceW.Meta.collection

    validate: =>
      # TODO: Should these be simply asserts?
      throw new Error "Missing meta location" unless @_metaLocation
      throw new Error "Missing source path (from #{ @_metaLocation })" unless @sourcePath
      throw new Error "Missing source W (for #{ @sourcePath } from #{ @_metaLocation })" unless @sourceW
      throw new Error "Missing source collection (for #{ @sourcePath } from #{ @_metaLocation })" unless @sourceCollection
      throw new Error "Source W not defined (for #{ @sourcePath } from #{ @_metaLocation })" unless @sourceW.Meta._listIndex?

      assert not @sourceW.Meta._replaced
      assert not @sourceW.Meta._delayIndex?
      assert.equal @sourceW.Meta.W, @sourceW
      assert.equal @sourceW.Meta.W.Meta, @sourceW.Meta

  @_ObservingField: class extends @_Field

  @_TargetedFieldsObservingField: class extends @_ObservingField
    # Arguments:
    #   targetW, fields
    constructor: (targetW, @fields) ->
      super()

      @fields ?= []

      if targetW is 'self'
        @targetW = 'self'
        @targetCollection = null
      else if _.isFunction(targetW) and targetW.prototype instanceof globals.W
        @targetW = targetW
        @targetCollection = targetW.Meta.collection
      else
        throw new Error INVALID_TARGET

    contributeToClass: (sourceW, sourcePath, ancestorArray) =>
      super sourceW, sourcePath, ancestorArray

      if @targetW is 'self'
        @targetW = @sourceW
        @targetCollection = @sourceCollection

      # Helpful values to know where and what the field is
      @inArray = @ancestorArray and startsWith @sourcePath, @ancestorArray
      @isArray = @ancestorArray and @sourcePath is @ancestorArray
      @arraySuffix = removePrefix @sourcePath, @ancestorArray if @inArray

    validate: =>
      super()

      throw new Error "Missing target W (for #{ @sourcePath } from #{ @_metaLocation })" unless @targetW
      throw new Error "Missing target collection (for #{ @sourcePath } from #{ @_metaLocation })" unless @targetCollection
      throw new Error "Target W not defined (for #{ @sourcePath } from #{ @_metaLocation })" unless @targetW.Meta._listIndex?

      assert not @targetW.Meta._replaced
      assert not @targetW.Meta._delayIndex?
      assert.equal @targetW.Meta.W, @targetW
      assert.equal @targetW.Meta.W.Meta, @targetW.Meta

  @_ReferenceField: class extends @_TargetedFieldsObservingField
    # Arguments:
    #   targetW, fields
    #   targetW, fields, required
    #   targetW, fields, required, reverseName
    #   targetW, fields, required, reverseName, reverseFields
    constructor: (targetW, fields, @required, @reverseName, @reverseFields) ->
      super targetW, fields

      @required ?= true
      @reverseName ?= null
      @reverseFields ?= []

    contributeToClass: (sourceW, sourcePath, ancestorArray) =>
      super sourceW, sourcePath, ancestorArray

      throw new Error "Reference field directly in an array cannot be optional (for #{ @sourcePath } from #{ @_metaLocation })" if @ancestorArray and @sourcePath is @ancestorArray and not @required

      return unless @reverseName

      # We return now because contributeToClass will be retried sooner or later with replaced W again
      return if @targetW.Meta._replaced

      for reverse in @targetW.Meta._reverseFields
        return if _.isEqual(reverse.reverseName, @reverseName) and _.isEqual(reverse.reverseFields, @reverseFields) and reverse.sourceW is @sourceW

      @targetW.Meta._reverseFields.push @

      # If target W is already defined, we queue it for a retry.
      # We do not queue children, because or children replace a parent
      # (and reverse fields will be defined there), or reference is
      # pointing to this target W and we want reverse defined
      # only once and only on exact target W and not its
      # children.
      if @targetW.Meta._listIndex?
        globals.W.list.splice @targetW.Meta._listIndex, 1

        delete @targetW.Meta._replaced
        delete @targetW.Meta._listIndex

        # Renumber Ws
        for doc, i in globals.W.list
          doc.Meta._listIndex = i

        globals.W._addDelayed @targetW

  @ReferenceField: (args...) ->
    new @_ReferenceField args...

  @_GeneratedField: class extends @_TargetedFieldsObservingField
    # Arguments:
    #   targetW, fields
    #   targetW, fields, generator
    constructor: (targetW, fields, @generator) ->
      super targetW, fields

  @GeneratedField: (args...) ->
    new @_GeneratedField args...

  @_Manager: class
    constructor: (@meta) ->

    find: (args...) =>
      @meta.collection.find args...

    findOne: (args...) =>
      @meta.collection.findOne args...

    insert: (args...) =>
      @meta.collection.insert args...

    update: (args...) =>
      @meta.collection.update args...

    upsert: (args...) =>
      @meta.collection.upsert args...

    remove: (args...) =>
      @meta.collection.remove args...

    exists: (query, options) =>
      query ?= {}
      options ?= {}

      # We want only a top-level extend here.
      _.extend options,
        fields:
          _id: 1
        transform: null

      !!@meta.collection.findOne query, options

  @_setDelayedCheck: ->
    return unless globals.W._delayed.length

    @_clearDelayedCheck()

    globals.W._delayedCheckTimeout = Meteor.setTimeout ->
      if globals.W._delayed.length
        delayed = [] # Display friendly list of delayed Ws
        for W in globals.W._delayed
          delayed.push "#{ W.Meta._name } from #{ W.Meta._location }"
        Log.error "Not all delayed W definitions were successfully retried:\n#{ delayed.join('\n') }"
    , 1000 # ms

  @_clearDelayedCheck: ->
    Meteor.clearTimeout globals.W._delayedCheckTimeout if globals.W._delayedCheckTimeout

  @_processTriggers: (triggers) ->
    assert triggers
    assert isPlainObject triggers

    for name, trigger of triggers
      throw new Error "Trigger names cannot contain '.' (for #{ name } trigger from #{ @Meta._location })" if name.indexOf('.') isnt -1

      if trigger instanceof globals.W._Trigger
        trigger.contributeToClass @, name
      else
        throw new Error "Invalid value for trigger (for #{ name } trigger from #{ @Meta._location })"

    triggers

  @_processFields: (fields, parent, ancestorArray) ->
    assert fields
    assert isPlainObject fields

    ancestorArray = ancestorArray or null

    res = {}
    for name, field of fields
      throw new Error "Field names cannot contain '.' (for #{ name } from #{ @Meta._location })" if name.indexOf('.') isnt -1

      path = if parent then "#{ parent }.#{ name }" else name
      array = ancestorArray

      if _.isArray field
        throw new Error "Array field has to contain exactly one element, not #{ field.length } (for #{ path } from #{ @Meta._location })" if field.length isnt 1
        field = field[0]

        if array
          # TODO: Support nested arrays
          # See: https://jira.mongodb.org/browse/SERVER-831
          throw new Error "Field cannot be in a nested array (for #{ path } from #{ @Meta._location })"

        array = path

      if field instanceof globals.W._Field
        field.contributeToClass @, path, array
        res[name] = field
      else if _.isObject field
        res[name] = @_processFields field, path, array
      else
        throw new Error "Invalid value for field (for #{ path } from #{ @Meta._location })"

    res

  @_fieldsUseW: (fields, W) ->
    assert fields
    assert isPlainObject fields

    for name, field of fields
      if field instanceof globals.W._TargetedFieldsObservingField
        return true if field.sourceW is W
        return true if field.targetW is W
      else if field instanceof globals.W._Field
        return true if field.sourceW is W
      else
        assert isPlainObject field
        return true if @_fieldsUseW field, W

    false

  @_retryAllUsing: (W) ->
    Ws = globals.W.list
    globals.W.list = []

    for doc in Ws
      if @_fieldsUseW doc.Meta.fields, W
        delete doc.Meta._replaced
        delete doc.Meta._listIndex
        @_addDelayed doc
      else
        globals.W.list.push doc
        doc.Meta._listIndex = globals.W.list.length - 1

  @_retryDelayed: (throwErrors) ->
    @_clearDelayedCheck()

    # We store the delayed list away, so that we can iterate over it
    delayed = globals.W._delayed
    # And set it back to the empty list, we will add to it again as necessary
    globals.W._delayed = []

    for W in delayed
      delete W.Meta._delayIndex

    processedCount = 0

    for W in delayed
      assert not W.Meta._listIndex?

      if W.Meta._replaced
        continue

      try
        triggers = W.Meta._triggers.call W, {}
        if triggers and isPlainObject triggers
          W.Meta.triggers = W._processTriggers triggers
      catch e
        if not throwErrors and (e.message is INVALID_TARGET or e instanceof ReferenceError)
          @_addDelayed W
          continue
        else
          throw new Error "Invalid triggers (from #{ W.Meta._location }): #{ e.stringOf?() or e }\n---#{ if e.stack then "#{ e.stack }\n---" else '' }"

      throw new Error "No triggers returned (from #{ W.Meta._location })" unless triggers
      throw new Error "Returned triggers should be a plain object (from #{ W.Meta._location })" unless isPlainObject triggers

      try
        fields = W.Meta._fields.call W, {}
        if fields and isPlainObject fields
          # We run _processFields first, so that _reverseFields for this W is populated as well
          W._processFields fields

          reverseFields = {}
          for reverse in W.Meta._reverseFields
            reverseFields[reverse.reverseName] = [globals.W.ReferenceField reverse.sourceW, reverse.reverseFields]

          # And now we run _reverseFields for real on all fields
          W.Meta.fields = W._processFields _.extend fields, reverseFields
      catch e
        if not throwErrors and (e.message is INVALID_TARGET or e instanceof ReferenceError)
          @_addDelayed W
          continue
        else
          throw new Error "Invalid fields (from #{ W.Meta._location }): #{ e.stringOf?() or e }\n---#{ if e.stack then "#{ e.stack }\n---" else '' }"

      throw new Error "No fields returned (from #{ W.Meta._location })" unless fields
      throw new Error "Returned fields should be a plain object (from #{ W.Meta._location })" unless isPlainObject fields

      if W.Meta.replaceParent and not W.Meta.parent?._replaced
        throw new Error "Replace parent set, but no parent known (from #{ W.Meta._location })" unless W.Meta.parent

        W.Meta.parent._replaced = true

        if W.Meta.parent._listIndex?
          globals.W.list.splice W.Meta.parent._listIndex, 1
          delete W.Meta.parent._listIndex

          # Renumber Ws
          for doc, i in globals.W.list
            doc.Meta._listIndex = i

        else if W.Meta.parent._delayIndex?
          globals.W._delayed.splice W.Meta.parent._delayIndex, 1
          delete W.Meta.parent._delayIndex

          # Renumber Ws
          for doc, i in globals.W._delayed
            doc.Meta._delayIndex = i

        @_retryAllUsing W.Meta.parent.W

      globals.W.list.push W
      W.Meta._listIndex = globals.W.list.length - 1
      delete W.Meta._delayIndex

      assert not W.Meta._replaced

      processedCount++

    @_setDelayedCheck()

    processedCount

  @_addDelayed: (W) ->
    @_clearDelayedCheck()

    assert not W.Meta._replaced
    assert not W.Meta._listIndex?

    globals.W._delayed.push W
    W.Meta._delayIndex = globals.W._delayed.length - 1

    @_setDelayedCheck()

  @_validateTriggers: (W) ->
    for name, trigger of W.Meta.triggers
      if trigger instanceof globals.W._Trigger
        trigger.validate()
      else
        throw new Error "Invalid trigger (for #{ name } trigger from #{ W.Meta._location })"

  @_validateFields: (obj) ->
    for name, field of obj
      if field instanceof globals.W._Field
        field.validate()
      else
        @_validateFields field

  @Meta: (meta) ->
    for field in RESERVED_FIELDS or startsWith field, '_'
      throw "Reserved meta field name: #{ field }" if field of meta

    if meta.abstract
      throw new Error "name cannot be set in abstract W" if meta.name
      throw new Error "replaceParent cannot be set in abstract W" if meta.replaceParent
      throw new Error "Abstract W with a parent" if @Meta._name
    else
      throw new Error "Missing W name" unless meta.name
      throw new Error "W name does not match class name" if not CODE_MINIMIZED and @name and @name isnt meta.name
      throw new Error "replaceParent set without a parent" if meta.replaceParent and not @Meta._name

    name = meta.name
    currentTriggers = meta.triggers or (ts) -> ts
    currentFields = meta.fields or (fs) -> fs
    meta = _.omit meta, 'name', 'triggers', 'fields'

    parentMeta = @Meta

    if parentMeta._triggers
      triggers = (ts) ->
        newTs = parentMeta._triggers ts
        removeUndefined _.extend ts, newTs, currentTriggers newTs
    else
      triggers = currentTriggers

    meta._triggers = triggers # Triggers function

    if parentMeta._fields
      fields = (fs) ->
        newFs = parentMeta._fields fs
        removeUndefined deepExtend fs, newFs, currentFields newFs
    else
      fields = currentFields

    meta._fields = fields # Fields function

    if not meta.abstract
      meta._name = name # "name" is a reserved property name on functions in some environments (eg. node.js), so we use "_name"
      # For easier debugging and better error messages
      meta._location = if CODE_MINIMIZED then '<code_minimized>' else StackTrace.getCaller()
      meta.W = @

      if meta.collection is null or meta.collection
        meta.collection = getCollection meta.collection, @, meta.replaceParent
      else if parentMeta.collection?._peerdb
        meta.collection = getCollection parentMeta.collection, @, meta.replaceParent
      else
        meta.collection = getCollection "#{ name }s", @, meta.replaceParent

      if @Meta._name
        meta.parent = parentMeta

      if not meta.replaceParent
        # If we are not replacing the parent, we override _reverseFields with an empty set
        # because we want reverse fields only on exact target W and not its children.
        meta._reverseFields = []
      else
        meta._reverseFields = _.clone parentMeta._reverseFields

      if not meta.replaceParent
        # If we are not replacing the parent, we create a new list of migrations
        meta.migrations = []

    clonedParentMeta = -> parentMeta.apply @, arguments
    filteredParentMeta = _.omit parentMeta, '_listIndex', '_delayIndex', '_replaced', 'parent', 'replaceParent', 'abstract'
    @Meta = _.extend clonedParentMeta, filteredParentMeta, meta

    if not meta.abstract
      assert @Meta._reverseFields

      @Ws = new @_Manager @Meta

      @_addDelayed @
      @_retryDelayed()

  @list = []
  @_delayed = []
  @_delayedCheckTimeout = null
  @_collections = {}

  @validateAll: ->
    for W in globals.W.list
      throw new Error "Missing fields (from #{ W.Meta._location })" unless W.Meta.fields
      @_validateTriggers W
      @_validateFields W.Meta.fields

  @defineAll: (dontThrowDelayedErrors) ->
    for i in [0..MAX_RETRIES]
      if i is MAX_RETRIES
        throw new Error "Possible infinite loop" unless dontThrowDelayedErrors
        break

      globals.W._retryDelayed not dontThrowDelayedErrors

      break unless globals.W._delayed.length

    globals.W.validateAll()

    assert dontThrowDelayedErrors or globals.W._delayed.length is 0

W = globals.W

assert globals.W._ReferenceField.prototype instanceof globals.W._TargetedFieldsObservingField
assert globals.W._GeneratedField.prototype instanceof globals.W._TargetedFieldsObservingField

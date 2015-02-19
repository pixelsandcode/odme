ShortID = require 'shortid'
JsonMask = require 'json-mask'
_ = require 'lodash'

module.exports = class Model
  
  # ## Source Adapter
  # 
  # Using this you can tap your models to any storage adapter and all of your models will inherit same adapter
  #
  # @examples
  #   Model::source = CB
  #   
  #   class User extends Model
  #   
  #   console.log User::source
  #   user = new User
  #   console.log user.source
  #   
  #   class Book extends Model
  #     constructor: () ->
  #       console.log @source
  #   
  #   # all above results are CB
  #   
  #   User::source = MySQL
  #   user.source     # it is MySQL
  #   User::source    # it is MySQL
  #   
  #   Model::source   # it is CB
  #   
  source: null
  PREFIX: null
  doc_type: null
  props: []
  _mask: null
  Q: require 'q'

  # ## Default key generator for doc
  # 
  # Base constructor of models. It generates a key if only document is passed, by using PREFIX and model ID generator. doc_key and doc_type will always be added to document properties.
  # It also mask the document and only accepts properties which are allowed based on **props**. Unless you pass true as last argument
  #
  # @method constructor([@key], @doc, [all])
  # @public
  # 
  # @examples
  #   new Model { prop: value }
  #   new Model { prop: value }, true
  #   new Model 'key', { prop: value }
  #   new Model 'key', { prop: value }, true
  #   
  #   user = new User { name: 'Arash' }
  #   user.key # It is like 'user_1'. based on PREFIX and _id method
  #   user.doc # The json document { name: 'Arash' }
  # 
  #   user = new User 'u_1', { name: 'Arash' }
  #   user.key # It is same as what is passed 'u_1'
  #   user.doc # The json document { name: 'Arash' }
  # 
  constructor: (@key, @doc, all) ->
    @PREFIX = @constructor.name.toLowerCase() if ! @PREFIX?
    @doc_type = @constructor.name.toLowerCase() if ! @doc_type?
    @_keys = _.keys _.pick( @props, (i) -> i )
    @setter_mask = @_keys.join ','
    if ! @_mask?
      @_mask = @setter_mask
      @_mask += ',doc_type,doc_key' if  @_mask != ''
    switch arguments.length
      when 0
        @doc = null
        @key = @_key @_id()
      when 1 
        @doc = @key || null
        @key = @_key @_id()
        all = false
      when 2
        if typeof @doc == 'boolean'
          all = @doc
          @doc = @key || null
          @key = @_key @_id()
      when 3
        all ||= false
    @key = "#{@key}" if @key?
    @doc = JsonMask @doc, @setter_mask if @doc? && ! all
    if @doc?
      @doc.doc_type = @doc_type 
      @doc.doc_key = @key

  # ## Default key generator for doc
  # 
  # This is synchronous key generator of model, this key will be used to save the doc. It can add **PREFIX_** to the id automatically. 
  # **PREFIX** is generated automatically from class name or can be defined in class definition.
  #
  # @method _key(id)
  # @private
  #
  _key: (id) ->
    if @PREFIX == false
      "#{id}"
    else
      "#{@PREFIX}_#{id}"

  # ## Default model ID generator
  # 
  # This is synchronous ID generator of model. Default is **shortid** library. It's used in constructor.
  #
  # @method _id()
  # @private
  #
  _id: -> ShortID.generate()

  # ## Mask Output
  # 
  # Filter what properties should be exposed using default **_mask** (which is generated from props list).
  #
  # @method mask([mask])
  # @public
  # 
  # @param {string|array|true}           mask   if it's not provided it will return default mask. If it's string, it will used as masker. If it's array it will append to the end of _mask property. And if it i's true it will return all.
  #
  # @examples
  #   class User extends Base
  #     props: { name: true, age: true, total_logins: false }
  #   
  #   jack = new User { name: 'Jack', age: 31 }
  #   jack.doc.total_logins = 10
  #   
  #   jack.mask()                 # { name: 'Jack', age: 31 }
  #   jack.mask('name')           # { name: 'Jack' }
  #   jack.mask(['total_logins']) # { name: 'Jack', age: 31, total_logins: 10 }
  #   jack.mask(false)            # { name: 'Jack', age: 31, total_logins: 10 }
  #   
  #   class User extends Base
  #     props: { name: true, age: true, total_logins: false }
  #     _mask: 'name,age,total_logins,lastname'
  #   
  #   jack = new User { name: 'Jack', age: 31 }
  #   jack.doc.total_logins = 10
  #   jack.doc.lastname = 'Cooper'
  #   
  #   jack.mask()                 # { name: 'Jack', age: 31, total_logins: 10, lastname: 'Cooper' }
  #   
  mask: (mask) ->
    mask = if mask?
      if typeof mask is 'string'
        mask
      else if mask instanceof Array
        "#{@_mask},#{mask.join(',')}"
      else
        '*'
    else 
      @_mask
    @constructor.mask @doc, mask

  # ## Mask Class Method
  # 
  # Filter what properties should be exposed using mask or **global_mask** (which is generated from props list).
  #
  # @method mask(doc, [mask])
  # @public
  # 
  # @param {string}           mask   if it's not provided it will return default class global_mask. If it's string, it will used as masker. 
  #
  # @examples
  @mask: (doc, mask) ->
    if ! mask?
      mask = @::global_mask || (
        keys = _.keys _.pick( @::props, (i) -> i )
        @::global_mask = keys.join ','
        @::global_mask += ',doc_type,doc_key' if  @::global_mask != ''
        @::global_mask
      )
    JsonMask doc, mask

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
  props: []
  _mask: null


  # ## Default key generator for doc
  # 
  # Base constructor of models. generate keys if only document is passed using PREFIX and model ID generator
  #
  # @method
  # @public
  # 
  # @examples
  #   user = new User { name: 'Arash' }
  #   user.key # It is like 'user_1'. based on PREFIX and _id method
  #   user.doc # The json document { name: 'Arash' }
  # 
  #   user = new User 'u_1', { name: 'Arash' }
  #   user.key # It is same as what is passed 'u_1'
  #   user.doc # The json document { name: 'Arash' }
  # 
  constructor: (@key, @doc) ->
    @PREFIX = @constructor.name.toLowerCase() if ! @PREFIX?
    @_keys = _.keys _.pick( @props, (i) -> i )
    @setter_mask = @_keys.join ','
    @_mask = @setter_mask if ! @_mask?
    if not doc?
      @doc = @key || null
      @key = @_key @_id()
    @key = "#{@key}" if @key?
    @doc = JsonMask @doc, @setter_mask if @doc?

  # ## Default key generator for doc
  # 
  # This is synchronous key generator of model, this key will be used to save the doc. It can add **PREFIX_** to the id automatically. 
  # **PREFIX** is generated automatically from class name or can be defined in class definition.
  #
  # @method
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
  # @method
  # @private
  #
  _id: -> ShortID.generate()

  # ## Mask Output
  # 
  # Filter what properties should be exposed using default **_mask** (which is generated from props list).
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
    if mask?
      if typeof mask is 'string'
        JsonMask @doc, mask
      else if mask instanceof Array
        JsonMask @doc, "#{@_mask},#{mask.join(',')}"
      else
        JsonMask @doc, '*'
    else 
      JsonMask @doc, @_mask

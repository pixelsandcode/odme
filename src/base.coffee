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

  # ## PREFIX
  # 
  # If you do not set this property, document's key prefix will be same as class name. If you want to customize it set `PREFIX` which will be used in `_key` generator. In case you do not want prefix in your keys, set it to **false**.
  # 
  PREFIX: null
  Q: require 'q'
  
  # ## Document type
  # 
  # Each document has a type which you can define by setting the `doc_type` property. This type will be saved in document automatically. If you do not set it, it will be same asclass name.
  # 
  doc_type: null

  # ## Properties
  # 
  # This is a list of accepted properties. If you do not set it, whatever is passed to constructor as document will be set as `doc`. It might be good to list all your properties here for code readability. 
  # If you want to stop mass assignment of some attributes you can list them here and set to false. This will also prevent them to get exposed when calling `mask` (Only if you haven't defined `_mask` list).
  # 
  # @examples
  #   class User extend Model
  #     
  #     props: { name: true, age: true, last_login: false }
  #     
  #   user = new User { name: 'Jack Black', age: 30, last_login: '2015-01-01' }
  #   user.doc # only name and age are set
  #   user.mask() # { name: 'Jack Black', age: 30 }
  # 
  props: []

  # ## Default Mask
  # 
  # Masking is based on `props` and only properties which set to true will be exposed. If you want to change this behavior you should set `_mask`.
  # 
  # @examples
  #   class User extend Model
  #     
  #     props: { name: true, age: true, last_login: false }
  #     _mask: 'name,last_login'
  #     
  #   user = new User { name: 'Jack Black', age: 30, last_login: '2015-01-01' }
  #   user.mask() # { name: 'Jack Black', last_login: '2015-01-01' }
  # 
  _mask: null

  # ## Model Constructor
  # 
  # If you call it with `new Model(key, doc, [all]), it will store doc in obj.doc and key in obj.key and type in obj.doc_type. Both doc_type and doc_key are added to document and will be stored in storage unless you change this behaviour. 
  # If you call it with `new Model(doc, [all]), it will do same as above and generate key using `_key` method and class name as prefix. You can override the `_key` method to change the key generation behaviour.
  #
  # @param {string}    key   this is optional, you can set the key or let class generate one for you.
  # @param {document}  doc   passed document will be stored in `.doc` property. Additionally, it will have doc_type and doc_key as object it getting constructed.
  # @param {boolean}   all   if it is set to true, the whole document will be stored in `.doc` property by ignoring `props`.
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
  #   user.key # It is like 'user_1'. based on PREFIX and _key method
  #   user.doc # The json document { name: 'Arash' }
  # 
  #   user = new User 'u_1', { name: 'Arash' }
  #   user.key # It is same as what is passed 'u_1'
  #   user.doc # The json document { name: 'Arash' }
  # 
  constructor: (@key, @doc, all) ->
    @is_new = true
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
        @key = @_key()
      when 1 
        @doc = @key || null
        @key = @_key()
        all = false
      when 2
        if typeof @doc == 'boolean'
          all = @doc
          @doc = @key || null
          @key = @_key()
      when 3
        all ||= false
    @key = "#{@key}" if @key?
    @doc = JsonMask @doc, @setter_mask if @doc? && ! all
    if @doc?
      @doc.doc_type = @doc_type 
      @doc.doc_key = @key

  # ## Default key generator for doc
  # 
  # This is synchronous key generator of model, this key will be used to save the doc. It adds **PREFIX** with **_** to the id automatically. 
  #
  # @method _key
  # @private
  #
  _key: (id) ->
    id ||= ShortID.generate()
    if @PREFIX == false
      "#{id}"
    else
      "#{@PREFIX}_#{id}"

  # ## Mask Output
  # 
  # Filter what properties should be exposed using `props` or `_mask` or passed argument.
  #
  # @method mask([mask])
  # @public
  # 
  # @param {string|array|true}           mask   if it's not provided it will return default based on `props` or `_mask`. If it's string, it will used as main mask. If it's array it will append to the end of _mask property. And if it is true it will return all.
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
  # @param {string}           mask   it is the masker and if it's not provided it will return default class global_mask.
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

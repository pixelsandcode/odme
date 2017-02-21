ShortID = require 'shortid'
JsonMask = require 'json-mask'
_ = require 'lodash'
Joi = require 'joi'
Promise = require 'bluebird'

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
  # PREFIX is used in key generation method (all ODME objects have a key). If you do not set this property, the key's prefix will be same as class name. If you want to customize it set `PREFIX` to what you like. In case you do not want prefix in your keys, set it to **false**.
  #
  PREFIX: null

  # ## Document type
  #
  # Each document has a type which you can define by setting the `docType` property. This type will be saved in document automatically. If you do not set it, it will be same as class name.
  #
  docType: null

  # ## Properties
  #
  # This is a list of accepted properties on mass-assignments and their joi schema. Your ODME object normally accept only a limited list of properties on mass-assignments and the rest should be added one by one by calling `model.doc.prop = value`.
  #
  # If you do not set props, whatever is passed to constructor as document will be set as `.doc`. Even if you want all properties to be passed to `.doc`, it is good to list all properties in props and setting them to true for code readability.
  #
  # To stop mass assignment of some attributes you should set them to false. This will also affect your mask method and prevent those properties from getting exposed when calling `.mask()` (This can be changed by defining `_mask` list).
  #
  # @examples
  #   class User extend Model
  #
  #     props: {
  #         name:
  #             schema: Joi.string()
  #             include: true,
  #         age:
  #             schema: Joi.number().min(18).max(60)
  #             include: true
  #         last_login:
  #             schema: Joi.date()
  #             include: false
  #     }
  #
  #   user = new User { name: 'Jack Black', age: 30, last_login: '2015-01-01' }
  #   user.doc # only name and age are set
  #   user.doc.gender = 'male'           # Extend your document with more properties
  #   user.doc.email =  'jack@gmail.com' # Extend your document with more properties
  #   user.mask() # { name: 'Jack Black', age: 30 }
  #
  props: []

  # ## Properties schema
  #
  # this is a Joi schema used to validate the props
  propsSchema:
    Joi.object().pattern(/.*/, Joi.object().min(1).keys(
      {
        schema: Joi.object().min(1).required()
        whiteList: Joi.boolean().default(false)
      }
    )).min(1)

  # ## Default Mask
  #
  # Masking is based on `props` by default and only properties which set to true will be exposed. If you want to change this behavior you should set `_mask`.
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
  # This will create a new document object of your model and behave as below:
  # ```
  #   new Model { prop: value }
  #   new Model { prop: value }, 'key'
  # ```
  #
  # ODME object stores document in `.doc` and generates and assgins key in `.key` properties. When the ODME object is new, it sets the `.is_new` to true. This `.is_new` property can be used to determine if the document is already stored in Data Storage (If you are implementing your own adapter, read CB adapter first.).
  #
  # ### Blank document object with new key
  #
  # Create a new document object by calling `new Model`. This will generate a new key for your ODME document. An ODME document always has 2 properties by default *docType* and *doc_key*.
  # ```
  #   model = new Model
  #   model.doc # { docType: 'cb', doc_key: 'cb_VknHXYjH' }
  #   model.key # 'cb_VknHXYjH'
  # ```
  # ### Document object with new key
  #
  # Create a new document object using your own properties and a new key by calling `new Model doc`. The ODME document includes your properties plus *docType* and *doc_key*.
  # ```
  #   model = new Model { name: 'Jack' }
  #   model.doc # { name: 'Jack', docType: 'cb', doc_key: 'cb_Vy2qXtiH' }
  #   model.key # 'cb_Vy2qXtiH'
  # ```
  # ### Blank document object with a key
  #
  # Create a new document object using your own key by calling `new Model doc, key`. This will use your key for your ODME document which has *docType* and *doc_key* in its properties.
  # ```
  #   model = new Model 123, { name: 'Jack' }
  #   model.doc # { name: 'Jack', docType: 'cb', doc_key: '123' }
  #   model.key # '123'
  # ```
  # You can change how key is getting generated by overriding `_key` method.
  # ### Property Filtering
  #
  # ODME filters the properties on mass-assignments using `props`.
  #
  # @param {string}    key   this is optional, you can set the key or let your ODME class generate one for you.
  # @param {document}  doc   passed document will be stored in `.doc` property. Additionally, it will have docType and doc_key as it's getting constructed.
  #
  # @method constructor([@key], @doc)
  # @public
  #
  constructor: (@doc, @key) ->
    @is_new = true
    throw "key should be a string" if typeof @key isnt 'string' and @key
    throw "prefix must be a string" if typeof @PREFIX isnt 'string' and @PREFIX
    @PREFIX = @constructor.name.toLowerCase() if ! @PREFIX?
    @docType = @constructor.name.toLowerCase() if ! @docType?
    @validateProps()
    @_keys = _.keys(_.pickBy(@props, (prop) -> return prop.whiteList))
    @setterMask = @_keys.join ','
    if ! @_mask?
      @_mask = @setterMask
      @_mask += ",docType,docKey"
    @doc ?= {}
    @key ?= @_key()
    @key = _.toString @key
    @doc = JsonMask(@doc, @setterMask) || {} if @doc?
    if @doc?
      @doc.docType = @docType
      @doc.docKey = @key
    @validateDoc()

  validateProps: () ->
    Joi.validate @props, @propsSchema, (err) ->
      throw {msg: 'the props field isnt valid', err} if err
      return yes

  validateDoc: () ->
    _.extend @props, {
      docType:
        schema: Joi.string().required()
        whiteList: false
      docKey:
        schema: Joi.string().required()
        whiteList: false
    }
    props = {}
    _.each @props, (value, key) ->
      props[key] = value.schema
    Joi.validate @doc, props, (err) ->
      throw {msg: 'doc is not valid', err} if err

  # ## Default key generator for doc
  #
  # This is synchronous key generator of model, this key will be used to save the `.doc` and a copy of it is included in the `.doc`. It adds **PREFIX** with **_** to the id automatically only if it is not set to `false`. You can override this behaviour in your model classes.
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
  # @param {string|array|true}           mask   if it's not provided it will return `.doc` properties based on `props` attribute or `_mask` if its defined. If it's a string, it will be used as mask and ignore `_mask` and `props`. If it's an array it will append the listed properties to the end of `_mask` property. And if it is true it will return all properties in `.doc`.
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
  #   jack.mask(true)             # { name: 'Jack', age: 31, total_logins: 10 }
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
  @mask: (doc, mask) ->
    if ! mask?
      mask = @::globalMask || (
        keys = _.keys _.pickBy( @::props, (i) -> i )
        @::globalMask = keys.join ','
        @::globalMask
      )
    JsonMask doc, mask

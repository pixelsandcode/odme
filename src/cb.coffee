Base = require './base'
Boom = require 'boom'

# ## Model Layer Using [puffer library](https://www.npmjs.com/package/puffer)
# 
# This Model class is using puffer for CRUDing. It's recommended to read [puffer's documentation](https://www.npmjs.com/package/puffer) first.
# 
module.exports = class CB extends Base
  
  # ## Get
  # 
  # Get the existing doc by key. It can return raw document (only value part) or instantiate from the javascript class
  # 
  # @method get(key[, raw])
  # @public
  # 
  # @param {string}  key(s)  document key(s) which should be retrieved
  # @param {boolean} raw  if it should return raw document 
  # 
  # @example
  #   recipe.get('recipe_uX87dkF3Bj').then (d) -> console.log d
  # 
  @get: (key, raw)->
    _this = @
    @::source.get(key, true).then (d)->
      return d if d.isBoom || raw
      if d not instanceof Array
        instance = new _this key, d 
        instance.doc = d
        return instance
      list = []
      for i in d
        instance = new _this i.doc_key, i
        instance.doc = i
        list.push instance
      list
 
  # ## Find
  # 
  # Find the existing docs by keys. It can return raw document (only value part) or the masked version of document. It uses **_mask** if it is defined in the class level as default filter.
  # 
  # @method find(key[, raw[, as_object]])
  # @public
  # 
  # @param {string}  key(s)     document key(s) which should be retrieved
  # @param {boolean|string} raw        if it's true it returns raw document, if it is string it will be considered as a mask
  # @param {boolean} as_object  if it's set to true it will return the masked result as object.
  # 
  # @example
  #   recipe.find('recipe_uX87dkF3Bj').then (d) -> console.log d
  # 
  @find: (key, raw, as_object)->
    _this = @
    @::source.get(key, true).then (d)->
      return d if d.isBoom || (raw? && raw == true)
      mask = (_this::_mask||null)
      mask = raw if typeof raw == 'string'
      if d not instanceof Array
        if as_object? and as_object
          (o = {})[d.doc_key] = _this.mask d, mask
          return o
        else
          return _this.mask d, mask
      else
        if as_object? and as_object
          list = {}
          for i in d
            list[i.doc_key] = _this.mask i, mask
        else
          list = []
          for i in d
            list.push _this.mask i, mask 
        list

  # ## Mask or Data
  # 
  # Check the CB callback's result and if it is alright and masked version is requested, it will return the masked result. 
  # 
  # @method _mask_or_data(data[, mask])
  # @private
  # 
  # @param {string|array|true}           mask  this works exactly same way mask(mask) method works
  # 
  _mask_or_data: (data, mask)->
    if data.isBoom || ! mask?
      data
    else
      @mask mask

  # ## Save
  # 
  # Save the doc in assigned key. It can return masked doc after saving.
  # 
  # @method save([mask])
  # @public
  # 
  # @param {string|array|true}           mask  this works exactly same way mask(mask) method works
  # 
  # @example
  #   recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
  #   recipe.doc.popularity = 100
  #   recipe.save(true).then (d) -> console.log d
  # 
  save: (mask)->
    _this = @
    @Q.invoke( @, 'before_create' ).then(
      (passed) ->
        if passed
          _this.source.create(_this.key, _this.doc).then( 
            (d) -> _this._mask_or_data(d, mask)
          ).then( ((d) -> 
              _this.after_save(d)
            ).bind(_this) 
          ).then( ((d) -> 
              _this.after_create(d)
            ).bind(_this) 
          ) 
        else
          Boom.notAcceptable "Validation failed"
    )


  # ## Update
  # 
  # Update the existing doc in assigned key. It can return masked doc after saving.
  # 
  # @method update([mask])
  # @public
  # 
  # @param {string|array|true}           mask  this works exactly same way mask(mask) method works
  # 
  # @example
  #   recipe = new Recipe "recipe_xhygd12gH3", { name: 'Anti Pasta' }
  #   recipe.update(true).then (d) -> console.log d
  # 
  update: (mask)->
    _this = @
    @source.update(@key, @doc).then( 
      (data) -> 
        return data if data.isBoom || ! mask?
        _this.source.get(_this.key, true).then (d) ->
          _this.doc = d
          _this._mask_or_data(d, mask)
    ).then( ((d) -> 
      _this.after_save(d)
      ).bind(_this)
    )

  # ## Delete
  # 
  # Delete the existing doc by key. It return true or the error
  # 
  # @method remove(key)
  # @public
  # 
  # @param {string}  key  document key which should be removed
  # 
  # @example
  #   Recipe.remove('recipe_UYd3f1Ty65').then (d) -> console.log d
  # 
  @remove: (key)->
    @::source.remove(key).then (d)->
      return d if d.isBoom
      return true
  
  # ## After Save Callback
  # 
  # You can after save callback in your models. If you want the data being passed in promises chain after calling **after_save** make sure you are returning it
  # 
  after_save: (data) -> return data
  
  # ## Before create Callback
  # 
  # Before Create hook to assign values or be used as validation. It should return true or false to determine if doc will get saved.
  # 
  before_create: -> return true
  
  # ## After Create Callback
  # 
  # After create hook to do extra processing on the result. If you want the data being passed in promises chain after calling **after_create** make sure you are returning it
  # 
  after_create: (data) -> return data

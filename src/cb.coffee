Base = require('./base')

# ## Model Layer Using [puffer library](https://www.npmjs.com/package/puffer)
# 
# This Model class is using puffer for CRUDing. It's recommended to read [puffer's documentation](https://www.npmjs.com/package/puffer) first.
# 
module.exports = class CB extends Base
  
  # ## Get
  # 
  # Get the existing doc by key. It can return raw document (only value part) or instantiate from the javascript class
  # 
  # @method get(key, [raw])
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
      return new _this key, d if d not instanceof Array
      list = []
      for i in d
        list.push new _this i.doc_key, i
      list
 
  # ## Find
  # 
  # Find the existing docs by keys. It can return raw document (only value part) or the masked version of document. It uses **_mask** if it is defined in the class level as default filter.
  # 
  # @method find(key, [raw])
  # @public
  # 
  # @param {string}  key(s)  document key(s) which should be retrieved
  # @param {boolean} raw  if it should return raw document 
  # 
  # @example
  #   recipe.find('recipe_uX87dkF3Bj').then (d) -> console.log d
  # 
  @find: (key, raw)->
    _this = @
    @::source.get(key, true).then (d)->
      return d if d.isBoom || raw
      mask = (_this::_mask||null)
      return _this.mask d, mask if d not instanceof Array
      list = []
      for i in d
        list.push _this.mask i, mask 
      list

  # ## Mask or Data
  # 
  # Check the CB callback's result and if it is alright and masked version is requested, it will return the masked result. 
  # 
  # @method _mask_or_data(data, [mask])
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
    @source.create(@key, @doc).then (d) -> _this._mask_or_data(d, mask)

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
  #   recipe.save(true).then (d) -> console.log d
  # 
  update: (mask)->
    _this = @
    @source.update(@key, @doc).then (data) -> 
      return data if data.isBoom || ! mask?
      _this.source.get(_this.key, true).then (d) ->
        _this.doc = d
        _this._mask_or_data(d, mask)

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

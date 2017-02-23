ShortID = require 'shortid'
Boom = require 'boom'
Base = require('../build/main').CB({})
Joi = require('joi')

db = new require('puffer') { host: 'localhost', name: 'test' }, true

module.exports = class Recipe extends Base

  POSTFIX: ':recipe'

  _mask: 'name,origin,popularity,docKey,docType'
  props: {
    name:
      schema: Joi.string()
      whiteList: true
    origin:
      schema: Joi.string()
      whiteList: true
    ingredients:
      schema: Joi.string()
      whiteList: true
    popularity:
      schema: Joi.number().min(0)
      whiteList: true
    time:
      schema: Joi.date()
      whiteList: true
    maximum_likes:
      schema: Joi.number()
      whiteList: false
  }

  constructor: (key, doc, all)->
    super
    @doc.maximum_likes = 100

  beforeSave: ->
    if !@can_save? || @can_save
      true
    else
      Boom.notAcceptable "Custom Boom"


  beforeUpdate: ->
    !@doc.is_locked

  beforeCreate: ->
    !(@doc.views? && @doc.views>1000)

  afterSave: (data) ->
    @doc.hits = 1
    data

  afterCreate: (data) ->
    @doc.total_hits = 10
    data.inc_hit = 2
    data

  afterUpdate: (data) ->
    @doc.hits += 10
    data

  _key: (id) ->
    id ||= ShortID.generate()
    if id.indexOf(Recipe::POSTFIX) > -1
      id
    else
      "#{id}#{Recipe::POSTFIX}"

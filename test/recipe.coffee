ShortID = require 'shortid'
Boom = require 'boom'
Base = require('../build/main').CB({})
Joi = require('joi')

db = new require('puffer') { host: 'localhost', name: 'test' }, true

module.exports = class Recipe extends Base

  source: db
  POSTFIX: ':recipe'

  _mask: 'name,origin,popularity,doc_key'
  props: {
    name: Joi.string(),
    origin: Joi.string(),
    ingredients: Joi.string(),
    popularity: Joi.number().min(0),
    time: Joi.date()
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

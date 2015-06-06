ShortID = require 'shortid'
Boom = require 'boom'
Base = require('../build/main').CB

db = new require('puffer') { host: 'localhost', name: 'test' }, true

module.exports = class Recipe extends Base
  
  source: db
  POSTFIX: ':recipe'

  _mask: 'name,origin,popularity,doc_key'
  props: {
    name: true,
    origin: true,
    ingredients: true,
    popularity: false,
    time: true
  }

  constructor: (key, doc, all)->
    super
    @doc.maximum_likes = 100
  
  before_save: ->
    if !@can_save? || @can_save
      true
    else
      Boom.notAcceptable "Custom Boom"
      

  before_update: ->
    !@doc.is_locked

  before_create: ->
    !(@doc.views? && @doc.views>1000)

  after_save: (data) ->
    @doc.hits = 1
    data

  after_create: (data) ->
    @doc.total_hits = 10
    data.inc_hit = 2
    data

  after_update: (data) ->
    @doc.hits += 10
    data

  _key: (id) ->
    id ||= ShortID.generate()
    if id.indexOf(Recipe::POSTFIX) > -1 
      id
    else
      "#{id}#{Recipe::POSTFIX}"

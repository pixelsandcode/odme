Base = require('../build/main').CB

db = new require('puffer') { host: 'localhost', name: 'test' }, true

module.exports = class Recipe extends Base
  
  source: db

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

  before_create: ->
    !(@doc.views? && @doc.views>1000)

  after_save: (data) ->
    @doc.hits = 1
    data

  after_create: (data) ->
    @doc.total_hits = 10
    data.inc_hit = 2
    data

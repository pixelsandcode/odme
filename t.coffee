Base = require './build/cb'

db = new require('puffer') { host: 'localhost', name: 'test' }, true

class Recipe extends Base
  source: db
  props: {
    name: true
    ingredients: true
  }   

recipe = new Recipe { name: 'Pasta', ingredients: ['pasta', 'basil', 'olive oil'] }

recipe.save().then ->
  Recipe.get(recipe.key).then (o) ->
    console.log '#####'
    console.log o # return Recipe object
    console.log '#####'

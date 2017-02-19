Base = require('../build/main').Base
Joi  = require 'joi'

class Model extends Base

  _key: ->
    id = 'fixedID'
    if @PREFIX == false
      "#{id}"
    else
      "#{@PREFIX}_#{id}"

module.exports = class User extends Model

  PREFIX: 'u'
  props: {
    name: Joi.string()
    age: Joi.number().min(0).max(120)
    city: Joi.string()
    country: Joi.string()
    popularity: Joi.number()
    total_logins: Joi.number()
  }

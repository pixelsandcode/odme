Base = require('../build/main').Base
Joi  = require 'joi'

class Model extends Base

  _key: ->
    id = 'fixedID'
    if @PREFIX() == false
      "#{id}"
    else
      "#{@PREFIX()}_#{id}"

module.exports = class User extends Model

  PREFIX: -> 'u'
  props: -> {
    name:
      schema: Joi.string()
      whiteList: true
    age:
      schema: Joi.number().min(0).max(120)
      whiteList: true
    city:
      schema: Joi.string()
      whiteList: true
    country:
      schema: Joi.string()
      whiteList: true
    popularity:
      schema: Joi.number()
      whiteList: true
    total_logins:
      schema: Joi.number()
      whiteList: true
  }

Base = require('../build/main').Base
Joi  = require 'joi'

module.exports = class Book extends Base

  props: {
    name:
      schema: Joi.string()
      whiteList: true
    pages:
      schema: Joi.number().min(1)
      whiteList: true
  }

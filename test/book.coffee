Base = require('../build/main').Base
Joi  = require 'joi'

module.exports = class Book extends Base

  props: {
    name: Joi.string()
    pages: Joi.number().min(1)
  }

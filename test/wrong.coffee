Base = require('../build/main').Base
Joi  = require 'joi'

module.exports = class Wrong extends Base

  PREFIX: [[]]
  props: {
    name: 'bluh'
    age: 2
    city: {}
    country: []
    popularity: Joi.number()
    total_logins: Joi.number()
  }

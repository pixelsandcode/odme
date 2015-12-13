Base = require('../build/main').Base

class Model extends Base
  
  _key: ->
    id = 'fixedID'
    if @PREFIX == false
      "#{id}"
    else
      "#{@PREFIX}_#{id}"

module.exports = class User extends Model
  
  PREFIX: 'u'
  props:
    name: false,
    age: false,
    city: false,
    country: false,
    popularity: false,
    total_logins: false

Base = require('../main')

class Model extends Base
  
  _id: -> 'fixedID'

module.exports = class User extends Model
  
  PREFIX: 'u'
  props: {
    name: true,
    age: true,
    total_logins: false
  }

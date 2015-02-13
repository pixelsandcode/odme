should  = require('chai').should()
Base   = require('../main')
User    = require('./user')

describe 'Base', ->
  
  it 'should create a class even if passed from a method', ->
    BaseFactory = (()->
                return Base
            )()
    class Book extends BaseFactory

    Base::source = 'CB'

    BaseFactory::source.should.equal 'CB'
    User::source.should.equal 'CB'

  it "should set source for all children and their instances", ->
    Base::source = 'CB'

    Base::source.should.equal 'CB'
    User::source.should.equal 'CB'
    user = new User
    user.source.should.equal 'CB'

    class Book extends Base
      constructor: () ->
        @source.should.equal 'CB'
    
    Book::source.should.equal 'CB'
    
  it "should let children set their own source", ->
    Base::source = 'CB'
    user = new User
    User::source = 'MySQL'

    user.source.should.equal 'MySQL'
    User::source.should.equal 'MySQL'
    Base::source.should.equal 'CB'

  it "should let instances change their own source without affecting others", ->
    User::source = 'MySQL'
    user = new User
    user.source = 'Redis'
    user.source.should.equal 'Redis'
    User::source.should.equal 'MySQL'
    user2 = new User
    user2.source.should.equal 'MySQL'
    
  it "should have null @doc and default @key on creation", ->
    user = new User
    user.should.have.property('key')
    user.should.have.property('doc')
    arash = new User { name: 'Arash' }
    arash.should.have.property('key').that.not.equal null
    arash.should.have.property('doc').that.have.property('name').that.equal 'Arash'
    jack = new User 'u_XYZ', { name: 'Jack' }
    jack.should.have.property('key').that.equal 'u_XYZ'
    jack.should.have.property('doc').that.have.property('name').that.equal 'Jack'

  it "should get a prefix as class name automatically", ->
    class Book extends Base
    book = new Book {}
    book.should.have.property('PREFIX').that.equal 'book'
    book.key.should.string "book"
  
  it "should have no prefix if set to false", ->
    class Book extends Base
      PREFIX: false

    book = new Book 100, {}
    book.should.have.property('PREFIX').that.equal false
    book.key.should.equal "100"

  it "should have prefix set before hand", ->
    user = new User {}
    user.should.have.property('PREFIX').that.equal 'u'
    user.key.should.equal "u_fixedID"

  it "should let inherited classes to have their own ID generator", ->
    user = new User { name: 'Arash' }
    user.key.should.equal "u_fixedID"
    base = new Base { name: 'Arash' }
    base.key.should.not.equal "u_fixedID"

  it "should alow bulk assignment for allowed attributes", ->
    user = new User { name: 'Arash', age: 31, total_logins: 10, last_login: 'today' }
    user.doc.should.eql { name: 'Arash', age: 31 }

  it "should have two independent masks as setter and getter", ->
    class Book extends Base
      props: {
        name: true
      }
      _mask: 'name,pages'

    book = new Book { name: 'NodeJS ODM', pages: 100 }
    book.doc.should.eql { name: 'NodeJS ODM' }
    book.doc.pages = 150
    book.doc.price = '$50'
    book.mask().should.eql { name: 'NodeJS ODM', pages: 150 }

  it "should rewrite getters mask", ->
    jack = new User { name: 'Jack', age: 31 }
    jack.doc.lastname = 'Cooper'
    jack.mask().should.eql { name: 'Jack', age: 31 }
    jack.mask('name').should.eql { name: 'Jack' }
    jack.mask(['lastname']).should.eql { name: 'Jack', age: 31, lastname: "Cooper" }
    jack.mask(false).should.eql { name: 'Jack', age: 31, lastname: "Cooper" }

###
  it "should create a doc", ->
    user = new User { name: 'Arash', age: 31 }
    user.key.should.equal 'u_XYZ'

  it "should update a doc", ->
    user = new User 'u_XYZ', { name: 'Arash', age: 31 }
    user.key.should.equal 'u_XYZ'

  it "should delete a doc", ->
    user = User.delete 'u_XYZ'
    user.key.should.equal 'u_XYZ'

  it "should get a doc", ->
    user = User.find 'u_XYZ'
    user.expose 
    user.expose 'x,y,z'
###




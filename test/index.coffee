should  = require('chai').should()
Base   = require('../build/main').Base
User    = require('./user')
Recipe    = require('./recipe')

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

  it 'should have @doc_type same as class name and set @doc.doc_type only if @doc is not null', ->
    user = new User {}
    user.should.have.property('doc_type').that.equal 'user'
    user.should.have.property('doc').that.be.a 'null'
    user = new User { name: 'Arash' }
    user.should.have.property('doc_type').that.equal 'user'

    class Book extends Base
      doc_type: 'notebook'

    book = new Book
    book.should.have.property('doc_type').that.equal 'notebook'

  it "should let inherited classes to have their own ID generator", ->
    user = new User { name: 'Arash' }
    user.key.should.equal "u_fixedID"
    base = new Base { name: 'Arash' }
    base.key.should.not.equal "u_fixedID"

  it "should alow bulk assignment for allowed attributes", ->
    user = new User { name: 'Arash', age: 31, total_logins: 10, last_login: 'today' }
    user.doc.should.eql { name: 'Arash', age: 31, doc_type: 'user', doc_key: user.key }
    user2 = new User { name: 'Arash', age: 31, total_logins: 10, last_login: 'today' }, true
    user2.doc.should.eql { name: 'Arash', age: 31, total_logins: 10, last_login: 'today', doc_type: 'user', doc_key: user2.key }

  it "should have two independent masks as setter and getter", ->
    class Book extends Base
      props: {
        name: true
      }
      _mask: 'name,pages'

    book = new Book { name: 'NodeJS ODM', pages: 100 }
    book.doc.should.eql { name: 'NodeJS ODM', doc_type: 'book', doc_key: book.key }
    book.doc.pages = 150
    book.doc.price = '$50'
    book.mask().should.eql { name: 'NodeJS ODM', pages: 150 }

  it "should rewrite getters mask", ->
    jack = new User { name: 'Jack', age: 31 }
    jack.doc.lastname = 'Cooper'
    jack.mask().should.eql { name: 'Jack', age: 31, doc_type: 'user', doc_key: jack.key }
    jack.mask('name').should.eql { name: 'Jack' }
    jack.mask(['lastname']).should.eql { name: 'Jack', age: 31, lastname: "Cooper", doc_type: 'user', doc_key: jack.key }
    jack.mask(false).should.eql { name: 'Jack', age: 31, lastname: "Cooper", doc_type: 'user', doc_key: jack.key }

  it "should have static getters mask", ->
    User.mask({ name: 'Jack', age: 31, lastname: 'Cooper', doc_type: 'user', doc_key: '123' }).should.eql { name: 'Jack', age: 31, doc_type: 'user', doc_key: '123' }
    User::global_mask.should.be.equal 'name,age,city,country,doc_type,doc_key'
    User.mask({ name: 'Jack', age: 31, lastname: 'Cooper', logins: 20, doc_key: '123' }).should.eql { name: 'Jack', age: 31, doc_key: '123' }

describe 'Puffer', ->

  it "should create a doc & return masked doc or db's result", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }

    recipe.source.should.have.property 'bucket'
    recipe.should.have.property('key').not.be.a('null')
    recipe.should.have.property('key').not.be.a('null')

    recipe.doc.popularity = 100
    recipe.save().then(
      (d) ->
        d.should.have.property('cas')
    ).done()

    recipe2 = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe2.doc.popularity = 100
    recipe2.save(true).then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe2.key, doc_type: 'recipe', popularity: 100 }
    ).done()

    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100
    recipe.save('name').then(
      (d) ->
        d.should.eql { name: 'Pasta' }
    ).done()

  it "should update a doc & return masked doc or db's result", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100

    recipe.save([]).then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key }
        updater = new Recipe recipe.key, { name: 'Anti Pasta' }
        updater.update([]).then(
          (u) ->
            u.should.eql { name: 'Anti Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key }
        )
        updater = new Recipe recipe.key, { name: 'Pasta Bolognese' }
        updater.update(true).then(
          (u) ->
            u.should.eql { name: 'Pasta Bolognese', origin: 'Italy', popularity: 100, doc_key: recipe.key, doc_type: 'recipe' }
        )
    ).done()

  it "should remove a doc & return true or false", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100

    recipe.save([]).then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key }
        Recipe.remove(recipe.key).then (d) -> d.should.equal true
    )

  it "should get the doc & return JS instance", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100

    recipe.save([]).then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key }
        Recipe.get(recipe.key).then( (d) -> 
          d.should.be.an.instanceof Recipe
          d.mask().should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key }
        ).done()
        Recipe.get(recipe.key, true).then(
          (d) -> d.should.be.eql { name: 'Pasta', origin: 'Italy', doc_type: 'recipe', doc_key: recipe.key, popularity: 100 } 
        ).done()
    )

  it "should get the docs & return JS instance", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100
    recipe.save()

    recipe2 = new Recipe { name: 'Pizza', origin: 'Italy' }
    recipe2.doc.popularity = 110

    recipe2.save([]).then(
      (d) ->
        Recipe.get([recipe.key, recipe2.key]).then( (d) -> 
          d.should.be.an.instanceof Array
          d[0].should.be.an.instanceof Recipe
          d[0].mask().should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key }
        ).done()
        Recipe.get([recipe.key, recipe2.key], true).then( (d) -> 
          d.should.be.an.instanceof Array
          Recipe.mask(d[0]).should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key, doc_type: 'recipe' }
        ).done()
    )

  it "should find the docs & return JS instance", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100
    recipe.save()

    recipe2 = new Recipe { name: 'Pizza', origin: 'Italy' }
    recipe2.doc.popularity = 110

    recipe2.save([]).then(
      (d) ->
        Recipe.find([recipe.key, recipe2.key]).then( (d) -> 
          d.should.be.an.instanceof Array
          d[0].should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key, popularity: 100 }
        ).done()
        Recipe.find([recipe.key, recipe2.key], true).then( (d) -> 
          d.should.be.an.instanceof Array
          Recipe.mask(d[0]).should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key, doc_type: 'recipe' }
        ).done()
    )

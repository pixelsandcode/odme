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
    
  it "should have {} @doc and default @key on creation", ->
    user = new User
    user.should.have.property('key').that.not.equal null
    user.should.have.property('doc').that.not.equal null
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

  it 'should have @doc_type same as class name and set @doc.doc_type even if @doc was empty', ->
    user = new User {}
    user.should.have.property('doc_type').that.equal 'user'
    user.should.have.property('doc').that.be.not.a 'null'
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

  it "should override key generation method", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.key.should.match /recipe$/
    recipe.key.should.be.eql recipe.doc.doc_key

describe 'CB', ->

  it "should create a doc & return masked doc or db's result", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }

    recipe.source.should.have.property 'bucket'
    recipe.should.have.property('key').not.be.a('null')
    recipe.should.have.property('key').not.be.a('null')

    recipe.doc.popularity = 100
    recipe.create()
      .then (d) ->
        d.should.have.property('cas')
    
        recipe2 = new Recipe { name: 'Pasta', origin: 'Italy' }
        recipe2.doc.popularity = 100
        recipe2.create(true)
          .then (d) ->
            d.should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe2.key, doc_type: 'recipe', popularity: 100, maximum_likes: 100, inc_hit: 2 }

            recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
            recipe.doc.popularity = 100
            recipe.create('name').then (d) ->
              d.should.eql { name: 'Pasta', inc_hit: 2 }

  it "should update a doc & return masked doc or db's result", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100

    recipe.create([]).then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key, inc_hit: 2 }
        recipe.mask(['hits']).should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key, hits: 1 }
        recipe.mask(true).should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key, hits: 1, doc_type: 'recipe', maximum_likes: 100, total_hits: 10 }
        updater = new Recipe recipe.key, { name: 'Anti Pasta' }
        updater.update([]).then(
          (u) ->
            u.should.eql { name: 'Anti Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key }
            updater.mask(['hits']).should.eql { name: 'Anti Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key, hits: 11 }
        )
    )

  it "should update a doc & return masked doc or db's result", ->
    recipe2 = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe2.doc.popularity = 100

    recipe2.create([]).then(
      (d) ->
        updater = new Recipe recipe2.key, { name: 'Pasta Bolognese' }
        updater.update(true).then(
          (u) ->
            u.should.eql { name: 'Pasta Bolognese', origin: 'Italy', popularity: 100, doc_key: recipe2.key, doc_type: 'recipe', maximum_likes: 100 }
        )
    )
  
  it "should get and update a doc", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.create([]).then(
      (d) ->
        updater = Recipe.get(recipe.key).then (obj) ->
          obj.doc.name = 'Anti Pasta'
          obj.update([]).then(
            (doc) -> 
              doc.should.eql { name: 'Anti Pasta', origin: 'Italy', doc_key: recipe.key }
          )
    )
    
  it "should excute after save and after update", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.create([]).then(
      (d) ->
        updater = new Recipe recipe.key, {}
        updater.update([]).then(
          (doc) ->
            updater.doc.hits.should.eql 11
        )
    )

  it "should fail on double updates", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.create([]).then(
      (d) ->
        Recipe.get(recipe.key).then (updater1) ->
          Recipe.get(recipe.key).then (updater2) ->
            updater1.origin = 'China'
            updater1.update([]).then (d) ->
              d.should.not.be.an.instanceof Error
              updater2.origin = 'Spain'
              updater2.update().then (d) ->
                d.should.be.an.instanceof Error
  )

  it "should remove a doc & return true or false", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100

    recipe.create([]).then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key, inc_hit: 2 }
        Recipe.remove(recipe.key).then (d) -> d.should.equal true
    )

  it "should get the doc & return JS instance", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100

    recipe.create([]).then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, doc_key: recipe.key, inc_hit: 2 }
        Recipe.get(recipe.key).then( (d) -> 
          d.should.be.an.instanceof Recipe
          d.mask().should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key,  popularity: 100 }
          Recipe.get(recipe.key, true).then(
            (d) -> d.value.should.be.eql { name: 'Pasta', origin: 'Italy', doc_type: 'recipe', doc_key: recipe.key, popularity: 100, maximum_likes: 100 } 
          )
        )
    )

  it "should get the docs & return JS instance", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100
    recipe.create()

    recipe2 = new Recipe { name: 'Pizza', origin: 'Italy' }
    recipe2.doc.popularity = 110

    recipe2.create([]).then(
      (d) ->
        Recipe.get([recipe.key, recipe2.key]).then( (d) -> 
          d.should.be.an.instanceof Array
          d[0].should.be.an.instanceof Recipe
          d[0].mask().should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key, popularity: 100 }
          Recipe.get([recipe.key, recipe2.key], true).then( (d) -> 
            d.should.be.an.instanceof Object
            d[recipe.key].should.have.property 'cas'
            Recipe.mask(d[recipe.key].value).should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key, doc_type: 'recipe' }
          )
        )
    )

  it "should find the docs & return JS instance", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100
    recipe.create()

    recipe2 = new Recipe { name: 'Pizza', origin: 'Italy' }
    recipe2.doc.popularity = 110

    recipe2.create([]).then(
      (d) ->
        Recipe.find([recipe.key, recipe2.key])
          .then (d) -> 
            d.should.be.an.instanceof Array
            d[0].should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key, popularity: 100 }
            Recipe.find([recipe.key, recipe2.key], true)
              .then (d) -> 
                d.should.be.an.instanceof Array
                Recipe.mask(d[0]).should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key, doc_type: 'recipe' }
                Recipe.find([recipe.key, recipe2.key], false, true)
                  .then (d) -> 
                    d.should.be.an.instanceof Object
                    d[recipe.key].should.eql { name: 'Pasta', origin: 'Italy', doc_key: recipe.key, popularity: 100 }
                    Recipe.find([recipe.key, recipe2.key], 'name,popularity', true)
                      .then (d) -> 
                        d.should.be.an.instanceof Object
                        d[recipe.key].should.eql { name: 'Pasta', popularity: 100 }
    )

  it "should return empty array on find or get for empty array",  ->
    Recipe.find([]).then (d) ->
      d.should.be.eql []
      Recipe.get([]).then (d) ->
        d.should.be.eql []

  it "should return empty null on find or get for null",  ->
    Recipe.find(null).then (d) ->
      should.equal d, null
      Recipe.get(null).then (d) ->
        should.equal d, null

  it "should return empty null on find or get for undefined",  ->
    Recipe.find(undefined).then (d) ->
      should.equal d, null
      Recipe.get(undefined).then (d) ->
        should.equal d, null

  it "should return empty null on find or get for false",  ->
    Recipe.find(false).then (d) ->
      should.equal d, null
      Recipe.get(false).then (d) ->
        should.equal d, null

  it "should fail on before_create returning false", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.views = 10000
    recipe.create().then (d) ->
      d.should.be.an.instanceof Error

  it "should fail on before_save returning false", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.can_save = false
    recipe.create().then (d) ->
      d.should.be.an.instanceof Error
      d.message.should.be.eql 'Custom Boom'

  it "should fail on before_update returning false", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.create().then (d) ->
      updater = new Recipe recipe.key, { name: 'Pasta Bolognese' }
      updater.doc.is_locked = true
      updater.update(true).then(
        (u) ->
          u.should.be.an.instanceof Error
          u.message.should.be.eql 'Validation failed'
      )

  it "should set is_new only if the object is not loaded from storage", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.is_new.should.be.equal true
    recipe.create().then (d) ->
      Recipe.get(recipe.key).then (obj) ->
        obj.is_new.should.be.equal false

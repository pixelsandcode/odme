should  = require('chai').should()
chai = require('chai')
Base   = require('../build/main').Base
CB = require('../build/cb')({host: 'localhost', port: 9200, index: 'test'})
User    = require('./user')
Recipe    = require('./recipe')
Wrong = require('./wrong')
BaseBook = require('./book')
esTestData = require('./es_test_data.json')
request = require('request')
Promise = require 'bluebird'

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

  it "should return an error for invalid prop", ->
    chai.expect(() -> new Wrong).to.throw()

  it "should return an error for invalid doc", ->
    chai.expect(() -> new User {name: 1, age: "hello"}).to.throw()

  it "should have {} @doc and default @key on creation", ->
    user = new User
    user.should.have.property('key').that.not.equal null
    user.should.have.property('doc').that.not.equal null
    arash = new User { name: 'Arash' }
    arash.should.have.property('key').that.not.equal null
    arash.should.have.property('doc').that.have.property('name').that.equal 'Arash'
    jack = new User { name: 'Jack' }, 'u_XYZ'
    jack.should.have.property('key').that.equal 'u_XYZ'
    jack.should.have.property('doc').that.have.property('name').that.equal 'Jack'

  it "should get a prefix as class name automatically", ->
    book = new BaseBook {}
    book.should.have.property('PREFIX').that.equal 'book'
    book.key.should.string "book"

  it "should have prefix set before hand", ->
    user = new User {}
    user.should.have.property('PREFIX').that.equal 'u'
    user.key.should.equal "u_fixedID"

  it 'should have @docType same as class name and set @doc.docType even if @doc was empty', ->
    user = new User {}
    user.should.have.property('docType').that.equal 'user'
    user.should.have.property('doc').that.be.not.a 'null'
    user = new User { name: 'Arash' }
    user.should.have.property('docType').that.equal 'user'

    class Book extends BaseBook
      docType: 'notebook'

    book = new Book
    book.should.have.property('docType').that.equal 'notebook'

  it "should let inherited classes to have their own ID generator", ->
    user = new User { name: 'Arash' }
    user.key.should.equal "u_fixedID"
    base = new BaseBook { name: 'Arash' }
    base.key.should.not.equal "u_fixedID"

  it "should throw error key is not a string", ->
    chai.expect(() -> new User { name: 'Arash', age: 31}, yes).to.throw()

  it "should have two independent masks as setter and getter", ->
    class Book extends BaseBook
      _mask: 'name,pages'

    book = new Book { name: 'NodeJS ODM', pages: 100 }
    book.doc.should.eql { name: 'NodeJS ODM', docType: 'book', docKey: book.key, pages: 100 }
    book.doc.pages = 150
    book.doc.price = '$50'
    book.mask().should.eql { name: 'NodeJS ODM', pages: 150 }

  it "should rewrite getters mask", ->
    jack = new User { name: 'Jack', age: 31 }
    jack.doc.lastname = 'Cooper'
    jack.mask().should.eql { name: 'Jack', age: 31, docType: 'user', docKey: jack.key }
    jack.mask('name').should.eql { name: 'Jack' }
    jack.mask(['lastname']).should.eql { name: 'Jack', age: 31, lastname: "Cooper", docType: 'user', docKey: jack.key }
    jack.mask(false).should.eql { name: 'Jack', age: 31, lastname: "Cooper", docType: 'user', docKey: jack.key }

  it "should have static getters mask", ->
    User.mask({ name: 'Jack', age: 31, lastname: 'Cooper', docType: 'user', docKey: '123' }).should.eql { name: 'Jack', age: 31}
    User::globalMask.should.be.equal 'name,age,city,country,popularity,total_logins'
    User.mask({ name: 'Jack', age: 31, lastname: 'Cooper', logins: 20, docKey: '123' }).should.eql { name: 'Jack', age: 31}

  it "should override key generation method", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.key.should.match /recipe$/
    recipe.key.should.be.eql recipe.doc.docKey

describe 'CB', ->

  it "should create a doc & return masked doc or db's result", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }

    recipe.source.should.have.property 'bucket'
    recipe.should.have.property('key').not.be.a('null')
    recipe.should.have.property('key').not.be.a('null')

    recipe.doc.popularity = 100
    recipe.create()
      .then (d) ->
        recipe2 = new Recipe { name: 'Pasta', origin: 'Italy' }
        recipe2.doc.popularity = 100
        recipe2.create(true)
          .then (d) ->
            d.should.eql { name: 'Pasta', origin: 'Italy', docKey: recipe2.key, docType: 'recipe', popularity: 100, maximum_likes: 100, inc_hit: 2 }

            recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
            recipe.doc.popularity = 100
            recipe.create('name').then (d) ->
              d.should.eql { name: 'Pasta', inc_hit: 2 }

  it "should update a doc & return masked doc or db's result", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100

    recipe.create().then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, docKey: recipe.key, inc_hit: 2, docType: 'recipe' }
        recipe.mask(['hits']).should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, docKey: recipe.key, hits: 1, docType: 'recipe' }
        recipe.mask(true).should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, docKey: recipe.key, hits: 1, docType: 'recipe', maximum_likes: 100, total_hits: 10 }
        updater = new Recipe { name: 'Anti Pasta' }, recipe.key
        updater.update().then(
          (u) ->
            u.should.eql { name: 'Anti Pasta', origin: 'Italy', popularity: 100, docKey: recipe.key, docType: 'recipe' }
            updater.mask(['hits']).should.eql { name: 'Anti Pasta', origin: 'Italy', popularity: 100, docKey: recipe.key, hits: 11, docType: 'recipe' }
        )
    )

  it "should update a doc & return masked doc or db's result", ->
    recipe2 = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe2.doc.popularity = 100

    recipe2.create([]).then(
      (d) ->
        updater = new Recipe { name: 'Pasta Bolognese' }, recipe2.key
        updater.update(true).then(
          (u) ->
            u.should.eql { name: 'Pasta Bolognese', origin: 'Italy', popularity: 100, docKey: recipe2.key, docType: 'recipe', maximum_likes: 100 }
        )
    )

  it "should get and update a doc", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.create().then(
      () ->
        updated = Recipe.get(recipe.key).then (obj) ->
          obj.doc.name = 'Anti Pasta'
          obj.update().then(
            (doc) ->
              doc.should.eql { name: 'Anti Pasta', origin: 'Italy', docKey: recipe.key, docType: 'recipe'}
          )
    )

  it "should excute after save and after update", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.create([]).then(
      (d) ->
        updater = new Recipe {}, recipe.key
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

    recipe.create().then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, docKey: recipe.key, inc_hit: 2, docType: 'recipe' }
        Recipe.remove(recipe.key).then (d) -> d.should.equal true
    )

  it "should get the doc & return JS instance", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100

    recipe.create().then(
      (d) ->
        d.should.eql { name: 'Pasta', origin: 'Italy', popularity: 100, docKey: recipe.key, inc_hit: 2, docType: 'recipe' }
        Recipe.get(recipe.key).then( (d) ->
          d.should.be.an.instanceof Recipe
          d.mask().should.eql { name: 'Pasta', origin: 'Italy', docKey: recipe.key,  popularity: 100, docType: 'recipe' }
          Recipe.get(recipe.key, true).then(
            (d) -> d.value.should.be.eql { name: 'Pasta', origin: 'Italy', docType: 'recipe', docKey: recipe.key, popularity: 100, maximum_likes: 100 }
          )
        )
    )

  it "should get the docs & return JS instance", ->
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.doc.popularity = 100
    recipe.create()

    recipe2 = new Recipe { name: 'Pizza', origin: 'Italy' }
    recipe2.doc.popularity = 110

    recipe2.create().then(
      (d) ->
        Recipe.get([recipe.key, recipe2.key]).then( (d) ->
          d.should.be.an.instanceof Array
          d[0].should.be.an.instanceof Recipe
          d[0].mask().should.eql { name: 'Pasta', origin: 'Italy', docKey: recipe.key, popularity: 100, docType: 'recipe' }
          Recipe.get([recipe.key, recipe2.key], true).then( (d) ->
            d.should.be.an.instanceof Object
            d[recipe.key].should.have.property 'cas'
            Recipe.mask(d[recipe.key].value).should.eql { name: 'Pasta', origin: 'Italy', popularity: 100 }
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
            d[0].should.eql { name: 'Pasta', origin: 'Italy', docKey: recipe.key, popularity: 100, docType: 'recipe' }
            Recipe.find([recipe.key, recipe2.key], true)
              .then (d) ->
                d.should.be.an.instanceof Array
                Recipe.mask(d[0]).should.eql { name: 'Pasta', origin: 'Italy', popularity: 100 }
                Recipe.find([recipe.key, recipe2.key], false, true)
                  .then (d) ->
                    d.should.be.an.instanceof Object
                    d[recipe.key].should.eql { name: 'Pasta', origin: 'Italy', docKey: recipe.key, popularity: 100, docType: 'recipe' }
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
      updater = new Recipe { name: 'Pasta Bolognese' }, recipe.key
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

describe 'ES', ->
  it "should query ES and return data", (done) ->
    dataString = '{
      "doc": {
        "name" : "Pasta",
        "origin" : "italy"
      }
    }'
    options = {
      url: 'http://localhost:9200/test/recipe/1',
      method: 'POST',
      body: dataString
    }
    request options, (error, response, body) ->
      throw error if error
      response.statusCode.should.eq 201
      query =
        body:
          query:
            match_all: {}
      Recipe.search('recipe', query)
        .then (data) ->
          data.length.should.eq 1
          data[0].name.should.eq 'Pasta'
          done()

  it "should get the results from ES directly", ->
    CB.handleElasticData(esTestData)
    .then (result) ->
      result.length.should.eq 2
      result[0].brand_name.should.eq 'test'

  it "should get the results from ES directly and format", ->
    CB.handleElasticData(esTestData, {format: true})
    .then (result) ->
      result.total.should.eq 2
      result.list.length.should.eq 2
      result.list[0].brand_name.should.eq 'test'

  it "should get the keys from ES directly", ->
    CB.handleElasticData(esTestData, {keysOnly: true})
    .then (result) ->
      result.length.should.eq 2
      result[0].should.eq 'lvn_s_B1A74dfFe'

  it "should get the keys from ES directly and format", ->
    CB.handleElasticData(esTestData, {keysOnly: true, format: true})
      .then (result) ->
        result.total.should.eq 2
        result.list.length.should.eq 2
        result.list[0].should.eq 'lvn_s_B1A74dfFe'

  it "should get the keys from couchbase", ->
    recipe2 = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe2.create()
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.create()
      .then () ->
        esTestData.hits.hits[0]._id = recipe.key
        esTestData.hits.hits[1]._id = recipe2.key
        Recipe.handleElasticData(esTestData, {couchbaseDocuments: true})
          .then (result) ->
            result.length.should.eq 2
            result[0].docKey.should.eq recipe.key

  it "should get the keys from couchbase and format", ->
    recipe2 = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe2.create()
    recipe = new Recipe { name: 'Pasta', origin: 'Italy' }
    recipe.create()
      .then () ->
        esTestData.hits.hits[0]._id = recipe.key
        esTestData.hits.hits[1]._id = recipe2.key
        Recipe.handleElasticData(esTestData, {couchbaseDocuments: true, format: true})
          .then (result) ->
            result.total.should.eq 2
            result.list.length.should.eq 2
            result.list[0].docKey.should.eq recipe.key


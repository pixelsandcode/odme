odme
======

[![Build Status](https://travis-ci.org/tectual/odme.svg)](https://travis-ci.org/tectual/odme)
[![npm version](https://badge.fury.io/js/odme.svg)](http://badge.fury.io/js/odme)
[![Coverage Status](https://coveralls.io/repos/github/tectual/odme/badge.svg?branch=master)](https://coveralls.io/github/tectual/odme?branch=master)

[ODME](https://www.npmjs.com/package/odme) is not an ODM library. It helps you create a class to keep model logic and has some default logic such as setter, getter, masking and creating id with prefixes. All these behaviours can be changed easily at defining your modle classes. It has an extension to support Couchbase and you can add your own extension to support other storages.

* Full documation can be found [here](http://tectual.github.io/odme/base.html).
* Source code is available at [here](https://github.com/tectual/odme).

## How to use

You can create your model classes extending Base class of odme.

```coffeescript
Base = require('odme').Base

class User extends Base
  
  props: {
    name: true
    age: true
    total_logins: false
  }

  user = new User { name: 'Arash', age: 32, city: 'Sydney', total_logins:10 }
  console.log user.key     #user_mJLGt-e6
  console.log user.doc     
    # { 
    #   name: 'Arash',
    #   age: 32,
    #   doc_type: 'user',
    #   doc_key: 'user_mJLGt-e6' 
    # }
  console.log user.mask()
    # { 
    #   name: 'Arash',
    #   age: 32,
    #   doc_type: 'user',
    #   doc_key: 'user_mJLGt-e6' 
    # }

  user.doc.city = 'Tehran'
  console.log user.doc
    # { 
    #   name: 'Arash',
    #   age: 32,
    #   city: 'Tehran',
    #   doc_type: 'user',
    #   doc_key: 'user_mJLGt-e6' 
    # }
  console.log user.mask()
    # { 
    #   name: 'Arash',
    #   age: 32,
    #   doc_type: 'user',
    #   doc_key: 'user_mJLGt-e6' 
    # }
  console.log user.mask('name,city')
    # { 
    #   name: 'Arash',
    #   city: 'Tehran'
    # }
```

You can extend Base class based on your adapters and set a library as `source` to store your doc property in key of your model object. Check odme and Couchbase integration [here](http://tectual.github.io/odme/cb.html).

```coffeescript
  Base = require('../build/main').CB
  
  db = new require('puffer') { host: 'localhost', name: 'test' }, true
  
  class Recipe extends Base
    source: db
    props: {
      name: true,
      ingredients: true
    }
  
  recipe = new Recipe { name: 'Pasta', ingredients: ['pasta', 'basil', 'olive oil'] }

  console.log recipe.key # recipe_yHr0blT
  recipe.save().then ->
    
    #after save you can get it like this
    Recipe.get(recipe.key).then (o) ->
      console.log o # return Recipe object

```

## How to read this doc?

Base class is holding all the logic related to how to get a document and store it in the model class and how it will masked on outputs. Extensions such as CB are doing CRUD operations on models.

### Need more?

* Find the full list of available methods [here](http://tectual.github.io/odme/base.html).
* This documentation is generated by `groc`, you can make a copy of in your local version.
* You can run tests locally by `npm test`. Make sure you have development dependencies installed.


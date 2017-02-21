(function() {
  var Joi, JsonMask, Model, Promise, ShortID, _, es;

  ShortID = require('shortid');

  JsonMask = require('json-mask');

  _ = require('lodash');

  Joi = require('joi');

  Promise = require('bluebird');

  es = require('elasticsearch');

  module.exports = Model = (function() {
    Model.prototype.source = null;

    Model.prototype.PREFIX = null;

    Model.prototype.doc_type = null;

    Model.prototype.props = [];

    Model.prototype.props_schema = Joi.object().pattern(/.*/, Joi.object().min(1)).min(1);

    Model.prototype._mask = null;

    function Model(doc1, key) {
      this.doc = doc1;
      this.key = key;
      this.is_new = true;
      if (typeof this.key !== 'string' && this.key) {
        throw "key should be a string";
      }
      if (typeof this.PREFIX !== 'string' && this.PREFIX) {
        throw "prefix must be a string";
      }
      if (this.PREFIX == null) {
        this.PREFIX = this.constructor.name.toLowerCase();
      }
      if (this.doc_type == null) {
        this.doc_type = this.constructor.name.toLowerCase();
      }
      this.validate_props();
      this._keys = _.keys(this.props);
      this.setter_mask = this._keys.join(',');
      if (this._mask == null) {
        this._mask = this.setter_mask;
      }
      switch (arguments.length) {
        case 0:
          this.doc = {};
          this.key = this._key();
          break;
        case 1:
          this.key = this._key();
      }
      if (this.key != null) {
        this.key = "" + this.key;
      }
      if (this.doc != null) {
        this.doc = JsonMask(this.doc, this.setter_mask) || {};
      }
      if (this.doc != null) {
        this.doc.doc_type = this.doc_type;
        this.doc.doc_key = this.key;
      }
      this.validate_doc();
    }

    Model.prototype.validate_props = function() {
      return Joi.validate(this.props, this.props_schema, function(err, value) {
        if (err) {
          throw {
            msg: 'the props field isnt valid',
            err: err
          };
        }
        return true;
      });
    };

    Model.prototype.validate_doc = function() {
      _.extend(this.props, {
        doc_type: Joi.string().required(),
        doc_key: Joi.string().required()
      });
      return Joi.validate(this.doc, this.props, function(err, value) {
        if (err) {
          throw {
            msg: 'doc is not valid',
            err: err
          };
        }
      });
    };

    Model.prototype._key = function(id) {
      id || (id = ShortID.generate());
      if (this.PREFIX === false) {
        return "" + id;
      } else {
        return this.PREFIX + "_" + id;
      }
    };

    Model.prototype.mask = function(mask) {
      mask = mask != null ? typeof mask === 'string' ? mask : mask instanceof Array ? this._mask + "," + (mask.join(',')) : '*' : this._mask;
      return this.constructor.mask(this.doc, mask);
    };

    Model.mask = function(doc, mask) {
      var keys;
      if (mask == null) {
        mask = this.prototype.global_mask || (keys = _.keys(_.pickBy(this.prototype.props, function(i) {
          return i;
        })), this.prototype.global_mask = keys.join(','), this.prototype.global_mask);
      }
      return JsonMask(doc, mask);
    };

    Model.search = function(type, query, options) {
      var client;
      client = new es.Client({
        host: config.searchengine.host + ":" + config.searchengine.port,
        log: config.searchengine.log
      });
      query.index = config.searchengine.name;
      query.type = type;
      if ((options != null ? options.search_type : void 0) != null) {
        query.search_type = options.search_type;
      }
      return client.search(query);
    };

    return Model;

  })();

}).call(this);

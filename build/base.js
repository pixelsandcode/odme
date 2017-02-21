(function() {
  var Joi, JsonMask, Model, Promise, ShortID, _;

  ShortID = require('shortid');

  JsonMask = require('json-mask');

  _ = require('lodash');

  Joi = require('joi');

  Promise = require('bluebird');

  module.exports = Model = (function() {
    Model.prototype.source = null;

    Model.prototype.PREFIX = null;

    Model.prototype.docType = null;

    Model.prototype.props = [];

    Model.prototype.propsSchema = Joi.object().pattern(/.*/, Joi.object().min(1)).min(1);

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
      if (this.docType == null) {
        this.docType = this.constructor.name.toLowerCase();
      }
      this.validate_props();
      this._keys = _.keys(this.props);
      this.setterMask = this._keys.join(',');
      if (this._mask == null) {
        this._mask = this.setterMask;
      }
      if (this.doc == null) {
        this.doc = {};
      }
      if (this.key == null) {
        this.key = this._key();
      }
      this.key = _.toString(this.key);
      if (this.doc != null) {
        this.doc = JsonMask(this.doc, this.setterMask) || {};
      }
      if (this.doc != null) {
        this.doc.docType = this.docType;
        this.doc.docKey = this.key;
      }
      this.validate_doc();
    }

    Model.prototype.validate_props = function() {
      return Joi.validate(this.props, this.propsSchema, function(err) {
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
        docType: Joi.string().required(),
        docKey: Joi.string().required()
      });
      return Joi.validate(this.doc, this.props, function(err) {
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
        mask = this.prototype.globalMask || (keys = _.keys(_.pickBy(this.prototype.props, function(i) {
          return i;
        })), this.prototype.globalMask = keys.join(','), this.prototype.globalMask);
      }
      return JsonMask(doc, mask);
    };

    return Model;

  })();

}).call(this);

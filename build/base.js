(function() {
  var Joi, JsonMask, Model, Promise, ShortID, _;

  ShortID = require('shortid');

  JsonMask = require('json-mask');

  _ = require('lodash');

  Joi = require('joi');

  Promise = require('bluebird');

  module.exports = Model = (function() {
    Model.prototype.source = null;

    Model.prototype.PREFIX = function() {
      return null;
    };

    Model.prototype.docType = null;

    Model.prototype.props = function() {
      return [];
    };

    Model.prototype.propsSchema = Joi.object().pattern(/.*/, Joi.object().min(1).keys({
      schema: Joi.object().min(1).required(),
      whiteList: Joi.boolean()["default"](false)
    })).min(1);

    Model.prototype._mask = function() {
      return null;
    };

    function Model(doc1, key1) {
      this.doc = doc1;
      this.key = key1;
      this.is_new = true;
      if (typeof this.key !== 'string' && this.key) {
        throw "key should be a string";
      }
      if (typeof this.PREFIX() !== 'string' && this.PREFIX()) {
        throw "prefix must be a string";
      }
      if (this.PREFIX() == null) {
        this.PREFIX = function() {
          return this.constructor.name.toLowerCase();
        };
      }
      if (this.docType == null) {
        this.docType = this.constructor.name.toLowerCase();
      }
      this.validateProps();
      this._keys = _.keys(_.pickBy(this.props(), function(prop) {
        return prop.whiteList;
      }));
      this.setterMask = this._keys.join(',');
      if (this._mask() == null) {
        this._mask = function() {
          return this.setterMask + ",docType,docKey";
        };
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
    }

    Model.prototype.validateProps = function() {
      return Joi.validate(this.props(), this.propsSchema, function(err) {
        if (err) {
          throw {
            msg: 'the props field isnt valid',
            err: err
          };
        }
        return true;
      });
    };

    Model.prototype.validateDoc = function() {
      var extended_props, props;
      extended_props = _.extend(this.props(), {
        docType: {
          schema: Joi.string().required(),
          whiteList: false
        },
        docKey: {
          schema: Joi.string().required(),
          whiteList: false
        }
      });
      props = {};
      _.each(extended_props, function(value, key) {
        return props[key] = value.schema;
      });
      return Joi.validate(this.doc, props, function(err) {
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
      if (this.PREFIX() === false) {
        return "" + id;
      } else {
        return (this.PREFIX()) + "_" + id;
      }
    };

    Model.prototype.mask = function(mask) {
      mask = mask != null ? typeof mask === 'string' ? mask : mask instanceof Array && mask.length > 0 ? (this._mask()) + "," + (mask.join(',')) : '*' : this._mask();
      return this.constructor.mask(this.doc, mask);
    };

    Model.mask = function(doc, mask) {
      var keys;
      if (mask == null) {
        mask = this.prototype.globalMask || (keys = _.keys(_.pickBy(this.prototype.props(), function(prop) {
          return prop.whiteList;
        })), this.prototype.globalMask = keys.join(','), this.prototype.globalMask);
      }
      return JsonMask(doc, mask);
    };

    return Model;

  })();

}).call(this);

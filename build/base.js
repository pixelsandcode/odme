(function() {
  var JsonMask, Model, ShortID, _;

  ShortID = require('shortid');

  JsonMask = require('json-mask');

  _ = require('lodash');

  module.exports = Model = (function() {
    Model.prototype.source = null;

    Model.prototype.PREFIX = null;

    Model.prototype.Q = require('q');

    Model.prototype.doc_type = null;

    Model.prototype.props = [];

    Model.prototype._mask = null;

    function Model(key, doc1, all) {
      this.key = key;
      this.doc = doc1;
      this.is_new = true;
      if (this.PREFIX == null) {
        this.PREFIX = this.constructor.name.toLowerCase();
      }
      if (this.doc_type == null) {
        this.doc_type = this.constructor.name.toLowerCase();
      }
      this._keys = _.keys(_.pick(this.props, function(i) {
        return i;
      }));
      this.setter_mask = this._keys.join(',');
      if (this._mask == null) {
        this._mask = this.setter_mask;
        if (this._mask !== '') {
          this._mask += ',doc_type,doc_key';
        }
      }
      switch (arguments.length) {
        case 0:
          this.doc = {};
          this.key = this._key();
          break;
        case 1:
          this.doc = this.key || {};
          this.key = this._key();
          all = false;
          break;
        case 2:
          if (typeof this.doc === 'boolean') {
            all = this.doc;
            this.doc = this.key || {};
            this.key = this._key();
          }
          break;
        case 3:
          all || (all = false);
      }
      if (this.key != null) {
        this.key = "" + this.key;
      }
      if ((this.doc != null) && !all) {
        this.doc = JsonMask(this.doc, this.setter_mask) || {};
      }
      if (this.doc != null) {
        this.doc.doc_type = this.doc_type;
        this.doc.doc_key = this.key;
      }
    }

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
        mask = this.prototype.global_mask || (keys = _.keys(_.pick(this.prototype.props, function(i) {
          return i;
        })), this.prototype.global_mask = keys.join(','), this.prototype.global_mask !== '' ? this.prototype.global_mask += ',doc_type,doc_key' : void 0, this.prototype.global_mask);
      }
      return JsonMask(doc, mask);
    };

    return Model;

  })();

}).call(this);

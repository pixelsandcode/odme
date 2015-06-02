(function() {
  var Base, Boom, CB,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Base = require('./base');

  Boom = require('boom');

  module.exports = CB = (function(superClass) {
    extend(CB, superClass);

    function CB() {
      return CB.__super__.constructor.apply(this, arguments);
    }

    CB.get = function(key, raw) {
      var _this, make;
      _this = this;
      raw || (raw = false);
      make = function(k, d) {
        var instance;
        instance = new _this(k, d);
        instance.doc = d;
        instance.key = k;
        instance.is_new = false;
        return instance;
      };
      return this.prototype.source.get(key, !raw).then(function(d) {
        var i, j, len, list;
        if (d.isBoom || raw) {
          return d;
        }
        if (!(d instanceof Array)) {
          return make(key, d);
        }
        list = [];
        for (j = 0, len = d.length; j < len; j++) {
          i = d[j];
          list.push(make(i.doc_key, i));
        }
        return list;
      });
    };

    CB.find = function(key, raw, as_object) {
      var _this;
      _this = this;
      return this.prototype.source.get(key, true).then(function(d) {
        var i, j, l, len, len1, list, mask, o;
        if (d.isBoom || ((raw != null) && raw === true)) {
          return d;
        }
        mask = _this.prototype._mask || null;
        if (typeof raw === 'string') {
          mask = raw;
        }
        if (!(d instanceof Array)) {
          if ((as_object != null) && as_object) {
            (o = {})[d.doc_key] = _this.mask(d, mask);
            return o;
          } else {
            return _this.mask(d, mask);
          }
        } else {
          if ((as_object != null) && as_object) {
            list = {};
            for (j = 0, len = d.length; j < len; j++) {
              i = d[j];
              list[i.doc_key] = _this.mask(i, mask);
            }
          } else {
            list = [];
            for (l = 0, len1 = d.length; l < len1; l++) {
              i = d[l];
              list.push(_this.mask(i, mask));
            }
          }
          return list;
        }
      });
    };

    CB.prototype._mask_or_data = function(data, mask) {
      if (data.isBoom || (mask == null)) {
        return data;
      } else {
        return this.mask(mask);
      }
    };

    CB.prototype.create = function(mask) {
      var _this;
      _this = this;
      return this.Q.invoke(this, 'before_create').then(function(passed) {
        if (passed) {
          return _this.source.insert(_this.key, _this.doc).then(function(d) {
            return _this._mask_or_data(d, mask);
          }).then((function(d) {
            return _this.after_save(d);
          }).bind(_this)).then((function(d) {
            return _this.after_create(d);
          }).bind(_this));
        } else {
          return Boom.notAcceptable("Validation failed");
        }
      });
    };

    CB.prototype.update = function(mask) {
      var _this;
      _this = this;
      return this.source.update(this.key, this.doc).then(function(data) {
        if (data.isBoom || (mask == null)) {
          return data;
        }
        return _this.source.get(_this.key, true).then(function(d) {
          _this.doc = d;
          return _this._mask_or_data(d, mask);
        });
      }).then((function(d) {
        return _this.after_save(d);
      }).bind(_this));
    };

    CB.remove = function(key) {
      return this.prototype.source.remove(key).then(function(d) {
        if (d.isBoom) {
          return d;
        }
        return true;
      });
    };

    CB.prototype.after_save = function(data) {
      return data;
    };

    CB.prototype.before_create = function() {
      return true;
    };

    CB.prototype.after_create = function(data) {
      return data;
    };

    return CB;

  })(Base);

}).call(this);

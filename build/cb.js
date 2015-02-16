(function() {
  var Base, CB,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __hasProp = {}.hasOwnProperty;

  Base = require('./base');

  module.exports = CB = (function(_super) {
    __extends(CB, _super);

    function CB() {
      return CB.__super__.constructor.apply(this, arguments);
    }

    CB.get = function(key, raw) {
      var _this;
      _this = this;
      return this.prototype.source.get(key, true).then(function(d) {
        var i, list, _i, _len;
        if (d.isBoom || raw) {
          return d;
        }
        if (!(d instanceof Array)) {
          return new _this(key, d);
        }
        list = [];
        for (_i = 0, _len = d.length; _i < _len; _i++) {
          i = d[_i];
          list.push(new _this(i.doc_key, i));
        }
        return list;
      });
    };

    CB.find = function(key, raw) {
      var _this;
      _this = this;
      return this.prototype.source.get(key, true).then(function(d) {
        var i, list, mask, _i, _len;
        if (d.isBoom || raw) {
          return d;
        }
        mask = _this.prototype._mask || null;
        if (!(d instanceof Array)) {
          return _this.mask(d, mask);
        }
        list = [];
        for (_i = 0, _len = d.length; _i < _len; _i++) {
          i = d[_i];
          list.push(_this.mask(i, mask));
        }
        return list;
      });
    };

    CB.prototype._mask_or_data = function(data, mask) {
      if (data.isBoom || (mask == null)) {
        return data;
      } else {
        return this.mask(mask);
      }
    };

    CB.prototype.save = function(mask) {
      var _this;
      _this = this;
      return this.source.create(this.key, this.doc).then(function(d) {
        return _this._mask_or_data(d, mask);
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
      });
    };

    CB.remove = function(key) {
      return this.prototype.source.remove(key).then(function(d) {
        if (d.isBoom) {
          return d;
        }
        return true;
      });
    };

    return CB;

  })(Base);

}).call(this);

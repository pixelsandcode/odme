(function() {
  var Base, Boom, CB, Promise, _,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Base = require('./base');

  Boom = require('boom');

  _ = require('lodash');

  Promise = require('bluebird');

  module.exports = CB = (function(superClass) {
    extend(CB, superClass);

    function CB() {
      return CB.__super__.constructor.apply(this, arguments);
    }

    CB.get = function(key, raw) {
      var make;
      if (_.isEmpty(key || _.isNaN(key))) {
        return Promise.resolve(_.isArray(key) ? [] : null);
      }
      raw || (raw = false);
      make = (function(_this) {
        return function(key, document) {
          var instance;
          instance = new _this(document, key);
          instance.doc = document.value;
          instance.cas = document.cas;
          instance.key = key;
          instance.is_new = false;
          return instance;
        };
      })(this);
      return this.prototype.source.get(key).then(function(document) {
        var i, j, len, list;
        if (document.isBoom || raw) {
          return document;
        }
        if (!(key instanceof Array)) {
          return make(key, document);
        }
        list = [];
        for (j = 0, len = key.length; j < len; j++) {
          i = key[j];
          list.push(make(i, document[i]));
        }
        return list;
      });
    };

    CB.find = function(key, raw, as_object) {
      if (_.isEmpty(key || _.isNaN(key))) {
        return Promise.resolve(_.isArray(key) ? [] : null);
      }
      return this.prototype.source.get(key, true).then((function(_this) {
        return function(d) {
          var i, j, k, len, len1, list, mask, o;
          if (d.isBoom || ((raw != null) && raw === true)) {
            return d;
          }
          mask = _this.prototype._mask || null;
          if (typeof raw === 'string') {
            mask = raw;
          }
          if (!(key instanceof Array)) {
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
              for (k = 0, len1 = d.length; k < len1; k++) {
                i = d[k];
                list.push(_this.mask(i, mask));
              }
            }
            return list;
          }
        };
      })(this));
    };

    CB.prototype.maskOrData = function(data, mask) {
      if (data.isBoom || (mask == null)) {
        return data;
      } else {
        return this.mask(mask);
      }
    };

    CB.prototype.create = function(mask) {
      return this.lifeCycle(mask, "Create", (function(_this) {
        return function() {
          return _this.source.insert(_this.key, _this.doc);
        };
      })(this));
    };

    CB.prototype.lifeCycle = function(mask, type, fn) {
      var after, afterSave, before, beforeSave;
      before = Promise.method(this["before" + type].bind(this));
      beforeSave = Promise.method(this.beforeSave.bind(this));
      afterSave = Promise.method(this.afterSave.bind(this));
      after = Promise.method(this["after" + type].bind(this));
      return before().then((function(_this) {
        return function(passed) {
          if (passed) {
            return beforeSave();
          } else {
            return passed;
          }
        };
      })(this)).then((function(_this) {
        return function(passed) {
          if (passed !== true) {
            throw passed;
          }
          return fn(mask);
        };
      })(this)).then((function(_this) {
        return function(data) {
          return _this.maskOrData(data, mask);
        };
      })(this)).then((function(_this) {
        return function(data) {
          return afterSave(data);
        };
      })(this)).then((function(_this) {
        return function(data) {
          return after(data);
        };
      })(this))["catch"](function(err) {
        if (err instanceof Error) {
          return err;
        } else {
          return Boom.notAcceptable("Validation failed");
        }
      });
    };

    CB.prototype.update = function(mask) {
      return this.lifeCycle(mask, "Update", (function(_this) {
        return function(mask) {
          var update;
          update = _this.is_new ? _this.source.update(_this.key, _this.doc) : _this.source.replace(_this.key, _this.doc, {
            cas: _this.cas
          });
          return update.then(function(data) {
            if (data.isBoom || (mask == null)) {
              return data;
            }
            return _this.source.get(_this.key, true).then(function(result) {
              _this.doc = result;
              return result;
            });
          });
        };
      })(this));
    };

    CB.remove = function(key) {
      return this.prototype.source.remove(key).then(function(data) {
        if (data.isBoom) {
          return data;
        }
        return true;
      });
    };

    CB.prototype.beforeUpdate = function() {
      return true;
    };

    CB.prototype.beforeCreate = function() {
      return true;
    };

    CB.prototype.beforeSave = function() {
      return true;
    };

    CB.prototype.afterCreate = function(data) {
      return data;
    };

    CB.prototype.afterUpdate = function(data) {
      return data;
    };

    CB.prototype.afterSave = function(data) {
      return data;
    };

    return CB;

  })(Base);

}).call(this);

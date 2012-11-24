// Generated by CoffeeScript 1.4.0
(function() {
  var Signal, batch, getClass, getClasses, invoke, should;

  should = chai.should();

  mocha.setup('bdd');

  invoke = invoker.invoke, batch = invoker.batch, Signal = invoker.Signal, getClass = invoker.getClass, getClasses = invoker.getClasses;

  describe('getClass', function() {
    describe('single invocation', function() {
      it('should be able to call static method without creating a new instance', function(done) {
        var Utils, invocation;
        Utils = getClass({
          name: 'Utils',
          staticMethods: ['add']
        });
        invocation = Utils.add(1, 2)(function(result) {
          result.should.equal(3);
          return done();
        });
        return invocation.__calls.should.deep.equal([['Utils', 'add', [1, 2], void 0]]);
      });
      it('should be able to send more complicated arguments', function(done) {
        var Utils, invocation;
        Utils = getClass({
          name: 'Utils',
          staticMethods: ['addList']
        });
        invocation = Utils.addList([1, 2, 3], [-1, 0, 1])(function(result) {
          result.should.deep.equal([0, 2, 4]);
          return done();
        });
        return invocation.__calls.should.deep.equal([['Utils', 'addList', [[1, 2, 3], [-1, 0, 1]], void 0]]);
      });
      it('should be able to use object as argument', function(done) {
        var Utils, dict;
        Utils = getClass({
          name: 'Utils',
          staticMethods: ['sortByValue']
        });
        dict = {
          a: 3,
          b: 2,
          c: 1
        };
        return Utils.sortByValue(dict, 'desc')(function(result) {
          result.should.deep.equal([['a', 3], ['b', 2], ['c', 1]]);
          return done();
        });
      });
      it('should be able to crate instance of class', function(done) {
        var User;
        User = getClass({
          name: 'User',
          methods: ['save'],
          staticMethods: ['listUsers']
        });
        return batch(function(onBatchDone) {
          var user;
          User.listUsers()(function(users) {
            return users.length.should.equal(0);
          });
          user = new User('foo');
          user.save();
          User.listUsers()(function(users) {
            return users.length.should.equal(1);
          });
          return onBatchDone(done);
        });
      });
      return it('should handle errors', function(done) {
        var Path;
        Path = getClass({
          name: 'Path',
          staticMethods: ['pwd', 'scanDir']
        });
        return invoker.batch(function(onBatchDone, onBatchError) {
          Path.pwd()(function(pwd) {
            throw {
              name: 'should not reach'
            };
          });
          Path.scanDir()(function(dir) {
            throw {
              name: 'should not reach'
            };
          });
          onBatchDone(function() {
            throw {
              name: 'should not reach'
            };
          });
          return onBatchError(function(reponse, code) {
            code.should.gt(200);
            return done();
          });
        });
      });
    });
    describe('batch', function() {
      var Path, Utils, _ref;
      _ref = getClasses([['Path', ['pwd']], ['Utils', ['add']]]), Path = _ref[0], Utils = _ref[1];
      it('should send request in one request', function(done) {
        return batch(function(onBatchDone) {
          Path.pwd()(function(result) {
            return result.should.equal('/test');
          });
          Utils.add(-1, 1)(function(result) {
            return result.should.equal(0);
          });
          return onBatchDone(done);
        });
      });
      it('should be able to make single request again', function(done) {
        return Utils.add(99, 1)(function(sum) {
          sum.should.equal(100);
          return done();
        });
      });
      return it('should be able to make batch request again', function(done) {
        return batch(function(onBatchDone) {
          Utils.add(1.5, -0.5)(function(sum) {
            return sum.should.equal(1);
          });
          return onBatchDone(done);
        });
      });
    });
    describe('invoke', function() {
      return it('should send request immediately', function(done) {
        return invoke(['Utils', 'add', [1, 2]], function(result) {
          result.should.equal(3);
          return done();
        });
      });
    });
    return describe('serverside object chache', function() {
      return it('should remember previous object', function(done) {
        var User, user;
        User = getClass({
          name: 'User',
          methods: ['create', 'getPosts', 'addPost']
        });
        user = new User('foo');
        return batch(function(onBatchDone) {
          user.create()(function() {});
          user.getPosts()(function(posts) {
            return posts.length.should.equal(0);
          });
          user.addPost({
            id: 1
          })(function() {});
          user.getPosts()(function(posts) {
            return posts.length.should.equal(1);
          });
          return onBatchDone(done);
        });
      });
    });
  });

  describe('Signal', function() {
    describe('add', function() {
      var i, registration, signal, _i;
      signal = new Signal;
      for (i = _i = 1; _i <= 100; i = ++_i) {
        registration = signal.add(function(data) {});
        signal.remove(registration);
      }
      it('should use space efficiently', function() {
        return signal.__listeners.length.should.equal(1);
      });
      return it('should notify every listener', function() {
        var data_collection, _j;
        data_collection = [];
        for (i = _j = 1; _j <= 100; i = ++_j) {
          signal.add(function(data) {
            return data_collection.push(data);
          });
        }
        signal.dispatch(1);
        data_collection.should.deep.equal((function() {
          var _k, _results;
          _results = [];
          for (i = _k = 1; _k <= 100; i = ++_k) {
            _results.push(1);
          }
          return _results;
        })());
        data_collection.length = 0;
        signal.dispatch(' ');
        return data_collection.should.deep.equal((function() {
          var _k, _results;
          _results = [];
          for (i = _k = 1; _k <= 100; i = ++_k) {
            _results.push(' ');
          }
          return _results;
        })());
      });
    });
    return describe('once', function() {
      var data_collection, i, signal, _i;
      signal = new Signal;
      data_collection = [];
      for (i = _i = 1; _i <= 100; i = ++_i) {
        signal.once(function(data) {
          return data_collection.push(data);
        });
        signal.dispatch(i);
      }
      it('should use space efficiently', function() {
        return signal.__listeners.should.deep.equal([void 0]);
      });
      return it('should listen only once', function() {
        var _j, _results;
        return data_collection.should.deep.equal((function() {
          _results = [];
          for (_j = 1; _j <= 100; _j++){ _results.push(_j); }
          return _results;
        }).apply(this));
      });
    });
  });

  describe('Invocation', function() {
    return describe('abort', function() {
      return it('should abort', function() {
        var Utils, invocation;
        Utils = getClass({
          name: 'Utils',
          staticMethods: ['add']
        });
        invocation = Utils.add(1, 2)(function(result) {
          result.should.equal(3);
          return console.log('no way to test it programmatically?');
        });
        return invocation.abort();
      });
    });
  });

}).call(this);

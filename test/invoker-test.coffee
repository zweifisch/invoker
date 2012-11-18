should = chai.should()
mocha.setup 'bdd'

describe 'Invoker', ->

	describe 'single invocation', ->
		it 'should get right response', (done)->
			utils = new Invoker 'Utils',['add']
			invocation = utils.add(1,2) (result)->
				result.should.equal 3
				done()
			invocation.__calls.should.deep.equal [['Utils','add',[1,2],undefined]]

		it 'should send a bit more complicated arguments', (done)->
			utils = new Invoker 'Utils',['addList']
			invocation = utils.addList([1,2,3],[-1,0,1]) (result)->
				result.should.deep.equal [0,2,4]
				done()
			invocation.__calls.should.deep.equal [['Utils','addList',[[1,2,3],[-1,0,1]],undefined]]

		it 'object as argument', (done)->
			utils = new Invoker 'Utils',['sortByValue']
			dict = a:3,b:2,c:1
			utils.sortByValue(dict,'desc') (result)->
				result.should.deep.equal [['a',3],['b',2],['c',1]]
				done()

	describe 'multiple invocations',->
		it 'multiple invocations', (done)->
			utils = new Invoker 'Utils',['addList','sortByValue']
			dict = a:1,b:3,c:2 

			invocation = Invoker.batch (invocation_done)->
				utils.sortByValue(dict,'asc') (result)->
					result.should.deep.equal [['a',1],['c',2],['b',3]]
				utils.addList([1,2],[2,4]) (result)->
					result.should.deep.equal [3,6]
				invocation_done -> done()

			invocation.__calls.should.deep.equal [
				['Utils','sortByValue',[dict,'asc'],undefined]
				['Utils','addList',[[1,2],[2,4]],undefined]
			]

	describe 'multiple invokers',->
		path = new Invoker 'Path',['pwd']
		utils = new Invoker 'Utils',['add']
		it 'should allow more than one instance', (done)->
			Invoker.batch (invocation_done)->
				path.pwd() (result)->
					result.should.equal '/test'
				utils.add(-1,1) (result)->
					result.should.equal 0
				invocation_done -> done()

		it 'should be able to make single request again', (done)->
			utils.add(99,1) (sum)->
				sum.should.equal 100
				done()

		it 'should be able to make batch request again', (done)->
			Invoker.batch (invocation_done)->
				utils.add(1.5, - 0.5) (sum)->
					sum.should.equal 1
				invocation_done -> done()

	describe 'access controll',->
		it 'should not allow access to certain methods', (done)->
			path = new Invoker 'Path',['scanDir']
			path.scanDir()
				success:(result)->
					throw
						name: 'Error'
						message: 'Error'
					done()
				error:(result,code)->
					code.should.equal 403
					done()

	describe 'invoke', ->
		it 'should send request immediately', (done)->
			Invoker.invoke ['Utils','add',[1,2]], (result)->
				result.should.equal 3
				done()

	describe 'serverside object chache', ->
		it 'should remember previous object', (done)->
			user = new Invoker 'User', ['create','getPosts','addPost'], ['foo']
			Invoker.batch (invocation_done)->
				user.create() ->
				user.getPosts() (posts)->
					posts.length.should.equal 0
				user.addPost(id:1) ->
				user.getPosts() (posts)->
					posts.length.should.equal 1
				invocation_done -> done()

		it 'should remember previous object again', (done)->
			user = new Invoker 'User', ['create','getPosts','addPost'], ['foo']
			Invoker.batch (invocation_done)->
				user.create() ->
				user.getPosts() (posts)->
					posts.length.should.equal 0
				user.addPost(id:1) ->
				user.getPosts() (posts)->
				user.addPost(id:2) ->
				user.getPosts() (posts)->
					posts.length.should.equal 2
				invocation_done -> done()

describe 'Signal', ->

	describe 'add', ->
		signal = new Signal
		for i in [1..100]
			registration = signal.add (data)->
			signal.remove registration

		it 'should use space efficiently', ->
			signal.__listeners.length.should.equal 1

		it 'should notify every listener', ->
			data_collection = []
			for i in [1..100]
				signal.add (data)->
					data_collection.push data
			signal.dispatch 1
			data_collection.should.deep.equal (1 for i in [1..100])
			data_collection.length = 0
			signal.dispatch ' '
			data_collection.should.deep.equal (' ' for i in [1..100])

	describe 'once', ->
		signal = new Signal
		data_collection = []
		for i in [1..100]
			signal.once (data)->
				data_collection.push data
			signal.dispatch i

		it 'should use space efficiently', ->
			signal.__listeners.should.deep.equal [undefined]

		it 'should listen only once', ->
			data_collection.should.deep.equal [1..100]
			
describe 'Invocation', ->
	describe 'abort', ->
		it 'should abort', ->
			utils = new Invoker 'Utils',['add']
			invocation = utils.add(1,2) (result)->
				result.should.equal 3
				console.log 'no way to test it programmatically?'
			invocation.abort()

describe 'getClass',->
	describe 'static method',->
		it 'should be able to call static method without creating a new instance', (done)->
			Utils = getClass 'Utils', ['add','addList']
			Utils.add(1,2) (result)->
				result.should.equal 3
				done()

		it 'should be able to crate instance of class', (done)->
			User = getClass 'User', ['save','listUsers']
			batchInvocations (invocation_done)->
				User.listUsers() (users)->
					users.length.should.equal 2
				user = new User 'foo'
				user.save() (result)->
					result.should.equal true
				User.listUsers() (users)->
					users.length.shoud.equal 3
				invocation_done -> done()

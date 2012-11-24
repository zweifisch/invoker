should = chai.should()
mocha.setup 'bdd'

{invoke,batch,Signal,getClass,getClasses} = invoker

describe 'getClass', ->

	describe 'single invocation', ->
		it 'should be able to call static method without creating a new instance', (done)->
			Utils = getClass
				name: 'Utils'
				staticMethods: ['add']
			invocation = Utils.add(1,2) (result)->
				result.should.equal 3
				done()
			invocation.__calls.should.deep.equal [['Utils','add',[1,2],undefined]]

		it 'should be able to send more complicated arguments', (done)->
			Utils = getClass
				name:	'Utils'
				staticMethods: ['addList']
			invocation = Utils.addList([1,2,3],[-1,0,1]) (result)->
				result.should.deep.equal [0,2,4]
				done()
			invocation.__calls.should.deep.equal [['Utils','addList',[[1,2,3],[-1,0,1]],undefined]]

		it 'should be able to use object as argument', (done)->
			Utils = getClass
				name: 'Utils'
				staticMethods: ['sortByValue']
			dict = a:3,b:2,c:1
			Utils.sortByValue(dict,'desc') (result)->
				result.should.deep.equal [['a',3],['b',2],['c',1]]
				done()

		it 'should be able to crate instance of class', (done)->
			User = getClass
				name: 'User'
				methods: ['save']
				staticMethods: ['listUsers']
			batch (onBatchDone)->
				User.listUsers() (users)->
					users.length.should.equal 0
				user = new User 'foo'
				user.save()
				User.listUsers() (users)->
					users.length.should.equal 1
				onBatchDone done

		it 'should handle errors', (done)->
			Path = getClass
				name: 'Path'
				staticMethods: ['pwd','scanDir']
			invoker.batch (onBatchDone,onBatchError)->
				Path.pwd() (pwd)->
					throw name: 'should not reach'
				Path.scanDir() (dir)->
					throw name: 'should not reach'
				onBatchDone ->
					throw name: 'should not reach'
				onBatchError (reponse,code)->
					code.should.gt 200
					done()
					

	describe 'batch',->
		[Path,Utils] = getClasses [
			['Path',['pwd']]
			['Utils',['add']]
		]
		it 'should send request in one request', (done)->
			batch (onBatchDone)->
				Path.pwd() (result)->
					result.should.equal '/test'
				Utils.add(-1,1) (result)->
					result.should.equal 0
				onBatchDone done

		it 'should be able to make single request again', (done)->
			Utils.add(99,1) (sum)->
				sum.should.equal 100
				done()

		it 'should be able to make batch request again', (done)->
			batch (onBatchDone)->
				Utils.add(1.5, - 0.5) (sum)->
					sum.should.equal 1
				onBatchDone done

	describe 'invoke', ->
		it 'should send request immediately', (done)->
			invoke ['Utils','add',[1,2]], (result)->
				result.should.equal 3
				done()

	describe 'serverside object chache', ->
		it 'should remember previous object', (done)->
			User = getClass
				name: 'User'
				methods: ['create','getPosts','addPost']
			user = new User 'foo'
			batch (onBatchDone)->
				user.create() ->
				user.getPosts() (posts)->
					posts.length.should.equal 0
				user.addPost(id:1) ->
				user.getPosts() (posts)->
					posts.length.should.equal 1
				onBatchDone done

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
			Utils = getClass
				name: 'Utils'
				staticMethods: ['add']
			invocation = Utils.add(1,2) (result)->
				result.should.equal 3
				console.log 'no way to test it programmatically?'
			invocation.abort()


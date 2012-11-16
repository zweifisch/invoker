class Signal
	constructor:->
		@__listeners = []
	dispatch: (data)->
		results = (listener? data for listener in @__listeners when listener?)
		# console.log "listeners: #{results.length}"
		handled_listeners = (result for result in results when result is yes).length
		handled_listeners is results.length and results.length > 0
	add: (listener,preserve_order=no)->
		if not preserve_order
			for l,idx in @__listeners
				if not l?
					@__listeners[idx] = listener
					return idx
		@__listeners.push listener
		@__listeners.length - 1
	once: (listener)->
		registration = @add (data)=>
			listener data
			@remove registration
	remove: (registrations...)->
		for registration in registrations
			@__listeners[registration] = undefined

class Ajax
	__xhrs = {}

	constructor: ({@type,@url,@callback,@headers})->
		if window.XMLHttpRequest
			@xhr = new XMLHttpRequest
		else
			try
				@xhr = new ActiveXObject "Msxml2.XMLHTTP"
			catch e
				@xhr = new ActiveXObject "Microsoft.XMLHTTP"
		__xhrs[@xhr] = on

	send: (@payload,callback)->
		@callback = @callback ? callback
		@xhr.open @type, @url

		if @headers
			@xhr.setRequestHeader k,v for own k,v of @headers

		if @callback
			@xhr.onreadystatechange = =>
				if @xhr.readyState is 4
					@callback @xhr.status,@xhr.responseText,@xhr
					delete __xhrs[@xhr]

		@xhr.send @payload

	abort: ->
		@xhr.abort()
		delete __xhrs[@xhr]

	@abortAll: ->
		# console.log __xhrs
		for xhr,_ of __xhrs
			xhr.abort?()
		__xhrs = {}

class Invoker
	@adding_invocation = new Signal
	@adding_callback = new Signal
	@url = 'gateway'

	constructor:(@classname,methods,@__construct_args)->
		for method in methods
			@__register method
		@__counter = 0

	__register:(method)->
		@[method] = @__call method

	__call:(method)->
		(args...)->
			call = [@classname,method,args,@__construct_args]
			id = @__counter
			@__counter += 1
			handled = @constructor.adding_invocation.dispatch [call,id,this]
			if handled
				do (id)=>
					(cb)=>
						@constructor.adding_callback.dispatch [cb,id,this]
			else
				# console.log "#{@classname}:#{@__counter} not handled"
				(cb)=>
					invocation = new Invocation @constructor.url, [call], [cb]
					invocation.send()

	@invoke:([classname,method,args,construt_args],cb)->
		invocation = new Invocation @url, [[classname,method,args,construt_args]], [cb]
		invocation.send()

	@batch:(setup)->
		done_callback = map_callback = null
		done = (cb)-> done_callback = cb
		map = (cb)-> map_callback = cb
		calls = []
		registration = @adding_invocation.add ([call,id,invoker])->
			calls.push [call,id,invoker]
			true
		registration2 = @adding_callback.add ([callback,id,invoker])->
			for [call,call_id,call_invoker],idx in calls
				if call_id is id and call_invoker is invoker
					calls[idx].push callback
					break
		setup done, map
		@adding_invocation.remove registration, registration2
		callbacks = (callback for [_,_,_,callback] in calls)
		calls = (call for [call,_,_,_] in calls)
		invocation = new Invocation @url,calls,callbacks
		invocation.send done_callback, map_callback

	@abort:->

class Invocation
	constructor:(@url,@__calls,@__callbacks)->
		@__calls = @__calls ? []
		@__callbacks= @__callbacks ? []

	send: (@__done,@__map)->
		opts =
			type:'POST'
			url: @url
			headers:
				'Content-type': 'application/json; charset=utf-8'
			callback:(code,text)=>
				responses = JSON.parse if text is '' then '{}' else text
				if @__map?
					responses = (@__map r for r in responses)
				if code is 200
					cb?.success? responses?[idx] for cb,idx in @__callbacks
				else
					cb?.error? responses?[idx], code for cb,idx in @__callbacks
				cb? responses?[idx], code for cb,idx in @__callbacks
				@__done?()
		@__ajax = new Ajax opts
		@__ajax.send JSON.stringify @__calls
		this

	abort: ->
		@__ajax.abort?()
	

exports = exports ? this
exports.Invoker = Invoker
exports.Signal = Signal

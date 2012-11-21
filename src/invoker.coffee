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

class Invocation
	constructor:(@__calls,@__callbacks)->
		@__calls = @__calls ? []
		@__callbacks= @__callbacks ? []

	send: (@__done,@__map)->
		opts =
			type:'POST'
			url: '/'
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

class Uid
	@id = 0
	@getUid = ->
		@id += 1

addingInvocation = new Signal
addingCallback = new Signal

addInvocation = (cls,method,args,construct_args)->
	id = Uid.getUid()
	call = [cls,method,args,construct_args]
	handled = addingInvocation.dispatch [call,id]
	if handled
		(cb)=>
			addingCallback.dispatch [cb,id]
	else
		(cb)=>
			invocation = new Invocation [call], [cb]
			invocation.send()

getClass = ({name,methods,staticMethods})->
	cls = class
		constructor:(@__construct_args...)->
	cls.__name = name
	if methods?
		for method in methods
			do(method)->
				cls::[method] = (args...)->
					addInvocation @constructor.__name,method,args,@__construct_args
	if staticMethods?
		for method in staticMethods
			do(method)->
				cls[method] = (args...)->
					addInvocation @__name,method,args
	cls

getClasses = (classSchemas)->
	(getClass {name:name,staticMethods:staticMethods,methods:methods} for [name,staticMethods,methods] in classSchemas)

batch = (setup)->
	done_callback = map_callback = null
	done = (cb)-> done_callback = cb
	map = (cb)-> map_callback = cb
	calls = []
	registration = addingInvocation.add ([call,id,invoker])->
		calls.push [call,id,invoker]
		true
	registration2 = addingCallback.add ([callback,id,invoker])->
		for [call,call_id,call_invoker],idx in calls
			if call_id is id and call_invoker is invoker
				calls[idx].push callback
				break
	setup done, map
	addingInvocation.remove registration
	addingCallback.remove registration2
	callbacks = (callback for [_,_,_,callback] in calls)
	calls = (call for [call,_,_,_] in calls)
	invocation = new Invocation calls,callbacks
	invocation.send done_callback, map_callback

invoke = ([classname,method,args,construt_args],cb)->
	invocation = new Invocation [[classname,method,args,construt_args]], [cb]
	invocation.send()

exports = exports ? this

exports.invoker =
	Signal: Signal
	getClass: getClass
	getClasses: getClasses
	batch: batch
	invoke: invoke

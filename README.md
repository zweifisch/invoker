# Invoker

A CoffeeScript library for Client/Server interaction, inspired by [fetch](https://github.com/ibdknox/fetch)

## Usage

### client side

```html
<script type="text/javascript" src="scripts"></script>
```

```coffeescript
{batch} = invoker
{Utils,User} = invoker.classes

Utils.add(1,2) (result)-> # result.should.equal 3
batch (done)->
	User.listUsers() (users)->
		# users.should.have.length 0
	user = new User 'foo'
	user.save()
	User.listUsers() (users)->
		# users.should.have.length 1
```

javascript version:
```javascript
var batch = invoker.batch;
	Utils = invoker.classes.Utils,
	User = invoker.classes.User,
Utils.add(1,2)(function(result){
	// result.should.equla(3)
});
batch(function(done){
	User.listUser()(function(users){
		// user.should.have.length(0)
	});
	user = new User('foo');
	user.save();
	User.listUsers()(function(users){
		// user.should.have.length(1)
	});
});
```

### server side

more details see [test/index.php](https://github.com/zweifisch/invoker/blob/master/test/index.php) and [the php backend](https://github.com/zweifisch/Invoker-php)

```php
require 'vendor/autoload.php';

allowedMethods = array(
	'Utils'=>'*',
	'User'=>'*',
	'Path'=>array('pwd'),
);
# Utils,User,Path must be available

$server = new Invoker\Server(allowedMethods);
$server->listen();
```

## more on client side

one line version

```coffeescript
invoker.invoke ['Utils','add',[1,2]], (result)-> console.log result is 3
```

call multiple methods in one ajax request

```coffeescript
invoker.batch (done)->
	utils.add(1,2) (sum)->
		console.log sum is 3
	utils.add(2,3) (sum)->
		console.log sum is 5
	path.pwd() (pwd)->
		console.log pwd
	done ->
		console.log 'done'
```

abort an invocation

```coffeescript
invocation = batch ->
	utils.add (1,2) (sum)->
invocation.abort()
```

handle errors

```coffeescript
Utils.add(1,2)
	success:(result)->
	error:(result,code)->
```
		
	
### intergration with other framework

TBD

## test

```sh
cd test
composer install
php -S localhost:1212 index.php
```

visit [http://localhost:1212](http://localhost:1212)


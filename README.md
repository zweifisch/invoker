# Invoker

A CoffeeScript library for Client/Server interaction, inspired by [fetch](https://github.com/ibdknox/fetch)

## Usage

### client side

```coffeescript
utils = new Invoker 'Utils', ['add']

utils.add(1,2) (result)-> # result.should.equal 3
```

### server side

more details see [test/index.php](https://github.com/zweifisch/invoker/blob/master/test/index.php) and [the php backend](https://github.com/zweifisch/Invoker-php)

```php
require 'vendor/autoload.php';

server = new Invoker\Server();
server->listen();
```

## more on client side

one line version

```coffeescript
Invoker.invoke ['Utils','add',[1,2]], (result)-> console.log result is 3
```

call multiple methods in one ajax request

```coffeescript
utils = new Invoker 'Utils', ['add']
path = new Invoker 'Path', ['pwd']
Invoker.batch (done)->
	utils.add(1,2) (sum)->
		console.log sum is 3
	utils.add(2,3) (sum)->
		console.log sum is 5
	path.pwd() (pwd)->
		console.log pwd
	done ->
		console.log 'done'
```

```coffeescript
invocation = Invoker.batch ->
	utils.add (1,2) (sum)->
invocation.abort()
```

handle errors

```coffeescript
utils.add(1,2)
	success:(result)->
	error:(result,code)->
```
		
## more on server side

### chage default uri, specify allowed methods

```php
allowedMethods = array(
	'Util'=>'*',
	'Path'=>array('pwd'),
);

$server = new Invoker\Server(allowedMethods);
$server->listen('/path');
```
	
### intergration with other framework

codeigniter

```php
class Gateway extends Controller
{
	function index()
	{
		$this->load->config('allowed_methods');
		$server = new Invoker\Server($this->config->item('allowed_methods'));
		$server->process();
	}
}
```
	
## test

```sh
cd test
composer install
php -S localhost:1212 index.php
```



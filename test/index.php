<?php

if (preg_match('/\.(?:js|css)$/', $_SERVER["REQUEST_URI"])) return false;

$loader = require 'vendor/autoload.php';
$loader->add('',__DIR__ . '/php');

$allowedMethods = [
	'Path' => ['pwd'],
	'Utils' => '*',
	'User' => '*',
];

$server = new Invoker\Server($allowedMethods);

$server->get('/',function(){
	return file_get_contents(__DIR__ . '/index.html');
});

$server->listen();

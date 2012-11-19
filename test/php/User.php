<?php

class User
{
	static $posts = [];
	static $users = [];
	function __construct($username)
	{
		$this->username = $username;
	}

	function save()
	{
		self::$users[] = $this->username;
		return true;
	}

	static function listUsers()
	{
		return self::$users;
	}

	function create()
	{
		self::$posts[$this->username] = [];
	}

	function getPosts()
	{
		return isset(self::$posts[$this->username])? self::$posts[$this->username] : [];
	}

	function addPost($post)
	{
		array_push(self::$posts[$this->username],$post);
	}
}

<?php

class User
{
	static $posts = [];
	function __construct($username)
	{
		$this->username = $username;
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

<?php

class Utils
{
	static function add($n,$n2)
	{
		return $n + $n2;
	}

	static function addList($l,$l2)
	{
		return array_map('array_sum', array_map(null,$l,$l2));
	}

	static function sortByValue($dict,$method='asc')
	{
		if('asc' == $method)
		{
			asort($dict);
		}else if ('desc' == $method)
		{
			arsort($dict);
		}
		return array_map(null,array_keys($dict),array_values($dict));
	}
}




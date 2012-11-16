
COLORS = {
	:reset   => "\e[0m",
	:cyan    => "\e[36m",
	:magenta => "\e[35m",
	:red     => "\e[31m",
	:yellow  => "\e[33m"
}

def colorize(string, color_code)
	"#{COLORS[color_code] || color_code}#{string}#{COLORS[:reset]}"
end

watch('src/.*\.coffee') { |f|
	puts colorize `date`, :red
	puts `coffee -c -o ./ #{f}`
}

watch('test/.*\.coffee') { |f|
	puts colorize `date`, :red
	puts `coffee -c -o test #{f}`
}

if { $argc != 1 } {
	puts "script requires an argument."
	} else {
		file mkdir build
		project open $argv 1
		project clean
		process run {Generate Programming File}
	}
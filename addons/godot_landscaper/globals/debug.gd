@tool
extends Resource
class_name GLDebug

static var level:int = Level.STATES
enum Level {ONLY_ERRORS, STATES, INTERNAL, SPAM}

static func debugging_warnings() -> bool:
	return level >= Level.ONLY_ERRORS

static func debugging_states() -> bool:
	return level >= Level.STATES

static func debugging_internal() -> bool:
	return level >= Level.INTERNAL

static func debugging_spam() -> bool:
	return level >= Level.SPAM



static func error(msg:Variant):
	print_rich("[color=#d66960][b]ERROR [GLandscaper][/b] %s[/color]" %msg)

static func warning(msg:Variant):
	if debugging_warnings():
		print_rich("[color=#ffde66][b]WARN  [GLandscaper][/b] %s[/color]" %msg)

static func state(msg:Variant):
	if debugging_states():
		print_rich("[color=#db7093][b]STATE [GLandscaper] [/b]%s[/color]" %msg)

static func internal(msg:Variant):
	if debugging_internal():
		print_rich("[color=#bbbbbb][b]INTER [GLandscaper] [/b]%s[/color]" %msg)

static func spam(msg:Variant):
	if debugging_spam():
		print_rich("[color=#e0e0e088][b]SPAM  [GLandscaper] [/b]%s[/color]" %msg)

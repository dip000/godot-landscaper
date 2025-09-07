@tool
extends Object
class_name GLDebug
## Global class for dobugging.


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
	push_error("Landscaper Error: %s" %msg)

static func warning(msg:Variant):
	if debugging_warnings():
		push_warning("Landscaper Warning: %s" %msg)

static func state(msg:Variant):
	if debugging_states():
		print_rich("[color=#00FFBBAA][b]Landscaper: [/b]%s[/color]" %msg)

static func internal(msg:Variant):
	if debugging_internal():
		print_rich("[color=#AAFFBB88][b]Landscaper: [/b]%s[/color]" %msg)

static func spam(msg:Variant):
	if debugging_spam():
		print_rich("[color=#e0e0e088][b]Landscaper: [/b]%s[/color]" %msg)

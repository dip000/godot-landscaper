@tool
extends Object
class_name GLDebug
## Global class for dobugging.


static var debug_level:int = Level.ONLY_ERRORS
enum Level {ONLY_ERRORS, STATES, INTERNAL, SPAM}


static func error(msg:Variant):
	push_error("Landscaper Error: %s" %msg)

static func warning(msg:Variant):
	if debug_level >= Level.ONLY_ERRORS:
		push_warning("Landscaper Error: %s" %msg)

static func state(msg:Variant):
	if debug_level >= Level.STATES:
		print_rich("[color=#00FFBBAA][b]Landscaper: [/b]%s[/color]" %msg)

static func internal(msg:Variant):
	if debug_level >= Level.INTERNAL:
		print_rich("[color=#AAFFBB88][b]Landscaper: [/b]%s[/color]" %msg)

static func spam(msg:Variant):
	if debug_level >= Level.SPAM:
		print_rich("[color=#FFFFBB44][b]Landscaper: [/b]%s[/color]" %msg)

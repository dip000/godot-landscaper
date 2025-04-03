@tool
extends Node
class_name Debug
## Global class for dobugging.
## Uses the debug level from Dock > Landscaper > Settings > Debug Level
## Has to be actually be instantiated somewhere to be able to store data


enum {NONE, STATE, OTHER, SPAM}
static var debug_level:CustomRange


static func state(msg:Variant):
	if ceili(debug_level.value) >= STATE:
		print_rich("[color=#00FFBBAA][b]Landscaper: [/b]%s[/color]" %msg)

static func other(msg:Variant):
	if ceili(debug_level.value) >= OTHER:
		print_rich("[color=#AAFFBB88][b]Landscaper: [/b]%s[/color]" %msg)

static func spam(msg:Variant):
	if ceili(debug_level.value) >= SPAM:
		print_rich("[color=#FFFFBB44][b]Landscaper: [/b]%s[/color]" %msg)

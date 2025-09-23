## Interface members and utilities for every brush (spawning grass, painting terrain, etc..)
## Every LandscaperTool has at least one Brush.
## Validating and injecting references must be handled outside by the SceneElement

@tool
extends Resource
class_name Brush


## Called once per stroke
## Validate a correct start up. Start other subprocesses like cacheing
## When calling, assume all references were setted up beforehand
func start(hit_info:Dictionary):
	pass

## Called every ui frame after start()
## Only preview changes if possible, to avoid lag on large sets of data
func primary(hit_info:Dictionary):
	pass

## Called every ui frame after start()
## Only preview changes if possible, to avoid lag on large sets of data
func secondary(hit_info:Dictionary):
	pass

## Called once at the end of the stroke
## Apply previewed changes if possible. End subprocesses like cache resets here
func end():
	pass

## Call on end() to apply changes. Other classes might need to call this as well.
## When calling, assume all references were setted up beforehand
func rebuild():
	pass

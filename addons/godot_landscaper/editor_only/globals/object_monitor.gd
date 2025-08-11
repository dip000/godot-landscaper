extends Resource
class_name ObjectMonitor
## Notifies a change of any object triggering the corresponding enter/exit signals
## Usefull for detecting new raycaster targets or selected resources

signal object_entered(obj)
signal object_exited(obj)

var previous:Object
var current:Object


func update(obj:Object):
	current = obj
	var has_changed := (previous != current)
	
	if has_changed and current:
		if previous:
			object_exited.emit(previous)
		object_entered.emit(current)
	
	elif has_changed and not current:
		object_exited.emit(previous)
	
	previous = current

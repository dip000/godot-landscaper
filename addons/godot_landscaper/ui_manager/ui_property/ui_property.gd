extends Control
class_name UIProperty
## Interface for custom dock properties.
## Managing each 'UIManager' property would not have scaled well otherwise

@export var property_name:String = ""
signal on_change(value)
static var disable_events:bool = false


func change():
	if not disable_events:
		on_change.emit()

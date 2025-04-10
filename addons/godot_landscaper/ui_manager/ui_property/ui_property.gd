@tool
extends Control
class_name UIProperty
## Interface for custom dock properties.
## Managing each 'UIManager' property would not have scaled well otherwise

@export var property_name:String = ""
signal on_change(value)


func change():
	on_change.emit()

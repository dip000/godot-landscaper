extends Resource
class_name InspectorTab

@export var title:String
@export_multiline var info:String
@export var brush:GLBrush
@export var icon:AtlasIcon.Icon
@export var properties:PackedStringArray


func _init(title:String, info:String, properties:PackedStringArray, icon:AtlasIcon.Icon, brush:GLBrush):
	self.title = title
	self.info = info
	self.properties = properties
	self.icon = icon
	self.brush = brush
	self.brush.resource_name = title.to_snake_case()

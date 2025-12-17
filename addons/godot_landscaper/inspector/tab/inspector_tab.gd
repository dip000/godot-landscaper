extends Resource
class_name InspectorTab

@export var title:String
@export_multiline var info:String
@export var brush:GLBrush
@export var icon:AtlasIcon.Icon
@export var hide_properties:PackedStringArray


func _init(title:String, info:String, hide_properties:PackedStringArray, icon:AtlasIcon.Icon, brush:GLBrush):
	self.title = title
	self.info = info
	self.hide_properties = hide_properties
	self.icon = icon
	self.brush = brush
	self.brush.resource_name = title.to_snake_case()

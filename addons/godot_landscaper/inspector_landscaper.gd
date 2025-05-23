extends EditorInspectorPlugin
class_name InspectorLandscaper


func _can_handle(object):
	return object is EcoInstancer

func _parse_category(object:Object, category:String):
	if category == "Select Action:":
		var inspector:UIManager = AssetsManager.UI_MANAGER.instantiate()
		add_custom_control( inspector )

func _parse_property(object:Object, type, name:String, hint_type, hint_string:String, usage_flags:int, wide:bool):
	if UIManager.spawn:
		if name in ["primary_color", "secondary_color", "ground_gradient"]:
			return true
	if UIManager.color:
		if name in ["add_ratio", "remove_ratio"]:
			return true
	return false

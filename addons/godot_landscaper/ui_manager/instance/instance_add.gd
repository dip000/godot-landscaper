@tool
extends UIProperty
class_name UIInstanceAdd
## Loads a scene and a range property.
## Only for Instancer brush.

@onready var instance_name:UITextInput = %Name
@onready var packed_scene:UIFileInput = %PackedScene
@onready var mesh:UIFileInput = %Mesh
@onready var texture_panel:UIFileInput = %TexturePanel
@onready var base_size:UIVector2Input = %BaseSize
@onready var randomize_size:UIVector2Input = %RandomizeSize
@onready var base_rotation:UIVector2Input = %BaseRotation
@onready var randomize_rotation:UIVector2Input = %RandomizeRotation

@onready var _popup_panel:PopupPanel = %PopupPanel
@onready var _save:Button = %Save
@onready var _accept_dialog:AcceptDialog = %AcceptDialog
@onready var _instances:UITabs = %Instances


func _ready():
	_save.pressed.connect( _on_save_pressed )
	self.pressed.connect( _on_edit_pressed )


func _on_edit_pressed():
	unpack( InstanceData.new() )
	_popup_panel.popup_centered()


func _on_save_pressed():
	var name_exists:bool = _instances.tabs.any(func(tab): return tab is UIInstance and tab.data.name == instance_name.text)
	if instance_name.text and not name_exists:
		var ui_instance:UIInstance = AssetsManager.INSTANCE_PREVIEW.instantiate()
		ui_instance.data = InstanceData.new()
		pack( ui_instance.data )
		ui_instance.name = ui_instance.data.name
		ui_instance.icon = ui_instance.data.texture
		_popup_panel.hide()
		_instances.add_tab( ui_instance, -2 )
	else:
		_accept_dialog.popup_centered()


func unpack(data:InstanceData):
	instance_name.text = data.name
	packed_scene.path = data.packed_scene.get_path() if data.packed_scene else ""
	mesh.path = data.multimesh_mesh.get_path() if data.multimesh_mesh else ""
	texture_panel.path = data.texture.get_path() if data.texture else ""
	base_size.value = data.size_base
	randomize_size.value = data.size_randomize
	base_rotation.value = data.rotation_base
	randomize_rotation.value = data.rotation_randomize

func pack(data:InstanceData):
	data.name = instance_name.text
	data.packed_scene = load(packed_scene.path) if packed_scene.path else null
	data.multimesh_mesh = load(mesh.path) if mesh.path else null
	data.texture = load(texture_panel.path) if texture_panel.path else null
	data.size_base = base_size.value
	data.size_randomize = randomize_size.value
	data.rotation_base = base_rotation.value
	data.rotation_randomize = randomize_rotation.value

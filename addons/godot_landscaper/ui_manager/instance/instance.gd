@tool
extends Button
class_name UIInstance

@onready var _instance_name:UITextInput = %Name
@onready var _packed_scene:UIFileInput = %PackedScene
@onready var _mesh:UIFileInput = %Mesh
@onready var _texture_panel:UIFileInput = %TexturePanel
@onready var _base_size:UIVector2Input = %BaseSize
@onready var _randomize_size:UIVector2Input = %RandomizeSize
@onready var _base_rotation:UIVector2Input = %BaseRotation
@onready var _randomize_rotation:UIVector2Input = %RandomizeRotation

@onready var _popup_panel:PopupPanel = %PopupPanel
@onready var _save:Button = %Save
@onready var _delete:Button = %Delete
@onready var _accept_dialog:AcceptDialog = %AcceptDialog
@onready var _edit:Button = $Edit

@export var data:InstanceData


func _ready():
	_save.pressed.connect( _on_save_pressed )
	_delete.pressed.connect( _on_delete_pressed )
	mouse_entered.connect( _edit.show )
	mouse_exited.connect( _edit.hide )
	_edit.pressed.connect( _on_edit_pressed )
	icon = data.texture if data else null
	name = data.name if data else "InstancePreview"


func _on_edit_pressed():
	_popup_panel.popup_centered()
	unpack()


func _on_save_pressed():
	if _instance_name.text:
		pack()
		name = data.name
		icon = data.texture
		_popup_panel.hide()
	else:
		_accept_dialog.popup_centered()


func _on_delete_pressed():
	owner.instances.remove_tab( _instance_name.text )


func unpack():
	_instance_name.text = data.name
	_packed_scene.path = data.packed_scene.get_path() if data.packed_scene else ""
	_mesh.path = data.multimesh_mesh.get_path() if data.multimesh_mesh else ""
	_texture_panel.path = data.texture.get_path() if data.texture else ""
	_base_size.value = data.size_base
	_randomize_size.value = data.size_randomize
	_base_rotation.value = data.rotation_base
	_randomize_rotation.value = data.rotation_randomize

func pack():
	data.name = _instance_name.text
	data.packed_scene = load(_packed_scene.path) if _packed_scene.path else null
	data.multimesh_mesh = load(_mesh.path) if _mesh.path else null
	data.texture = load(_texture_panel.path) if _texture_panel.path else null
	data.size_base = _base_size.value
	data.size_randomize = _randomize_size.value
	data.rotation_base = _base_rotation.value
	data.rotation_randomize = _randomize_rotation.value

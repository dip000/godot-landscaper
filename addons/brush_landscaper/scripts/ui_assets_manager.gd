@tool
extends VBoxContainer
class_name AssetsManager

@onready var _toggle_content:CustomToggleContent = $ToggleContent
@onready var _project:CustomFileInput = $FileInput

var _scene:SceneLandscaper
var _brushes:Array[Brush]
var _ui:UILandscaper


func _ready():
	_project.on_change.connect( _on_save_or_load )

func _on_save_or_load(save:bool, path:String):
	save_all() if save else load_all()


func unpack(ui:UILandscaper, scene:SceneLandscaper, brushes:Array[Brush]):
	if is_instance_valid( _scene ):
		save_all()
	
	_scene = scene
	_brushes = brushes
	_ui = ui
	load_all()

func pack():
	if _scene:
		save_all()
	

func save_all():
	for brush in _brushes:
		brush.pack( _scene.raw )
	
	_scene.raw.terrain_mesh = _scene.terrain_mesh
	_scene.raw.terrain_material = _scene.terrain.material_override
	_scene.raw.grass_mesh = _scene.grass_mesh
	_scene.raw.grass_material = _scene.grass_mesh.material
	_scene.raw.grass_shader = _scene.grass_mesh.material.shader
	_scene.raw.saved = true
	print("Saved: ", _scene)


func load_all():
	if _scene.raw.saved:
		_scene.grass_mesh.material.shader = _scene.grass_mesh.material.shader
		_scene.grass_mesh.material = _scene.raw.grass_material
		_scene.grass_mesh = _scene.raw.grass_mesh
		_scene.terrain.material_override = _scene.raw.terrain_material
		_scene.terrain_mesh = _scene.raw.terrain_mesh
	
	for brush in _brushes:
		brush.unpack( _ui, _scene, _scene.raw )
		
		if not _scene.raw.initialized:
			brush.template( Vector2i(10, 10) )
	_scene.raw.initialized = true
	print("Loaded: ", _scene)
	

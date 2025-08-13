@tool
extends EditorPlugin
class_name                         Landscaper
##           ↑─────────────────────────┼─────────↓────────────────┐
##    ↑ SceneManager ↑                 │   InspectorTools    AssetsManager  
##  SceneBrush  SceneRaycaster         │         │
##                                     ↓         ↓
##           ┌── LandscaperTool ───────┼─────────┼────────────┐
##           │  (Executes Action classes)   (Sets Actions)    │
##           │  ┌ SaveData ────────────────────────────────┐  │
##           │  │ (External Resources)                     │  │
##           │  │ ┌ ConfigsInstance ┐  ┌ ConfigsInstance ┐ │  │
##           │  │ │ Action (Spawn)  │  │ Action (Spawn)  │ │  │
##           │  │ │ Action (Color)  │  │ Action (Color)  │ │  │        
##           │  │ │ (Rebuild Data)  │  │ (Rebuild Data)  │ │  │        
##           │  │ └─────────────────┘  └─────────────────┘ │  │          
##           │  └──────────────────────────────────────────┘  │                                   
##           └────────────────────────────────────────────────┘


static var scene:SceneManager
static var tool:LandscaperTool
static var assets:AssetsManager
static var inspector:InspectorTools
static var undo_redo:EditorUndoRedoManager
static var is_enabled:bool


func _enter_tree():
	assets = AssetsManager.ASSETS_MANAGER.instantiate()
	scene = AssetsManager.SCENE_MANAGER.instantiate()
	inspector = InspectorTools.new()
	add_inspector_plugin( inspector )
	undo_redo = get_undo_redo()
	is_enabled = true
	var icon:Texture2D = preload("res://addons/godot_landscaper/icon.svg")
	add_custom_type("BakedQuadGrass", "Node", BakedQuadGrass, icon )
	
	await get_tree().process_frame
	var viewport:SubViewport = EditorInterface.get_editor_viewport_3d()
	viewport.add_child( assets )
	viewport.add_child( scene )
	

func _exit_tree():
	remove_inspector_plugin( inspector )
	assets.queue_free()
	scene.queue_free()
	is_enabled = false
	undo_redo.clear_history()
	remove_custom_type("BakedQuadGrass")


# Raycasts terrain colliders to track mouse pointer and sends input to an active 'SceneLandscaper' node
func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	if not tool:
		return
	
	# Accepted inputs
	var is_motion:bool = (event is InputEventMouseMotion)
	var is_button:bool = (event is InputEventMouseButton)
	
	if not (is_motion or is_button):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	# Raycast
	var hit_info:Dictionary = scene.raycaster.feed( cam, event.get_position() ).cam_to_cursor()
	if not hit_info:
		scene.not_over_surface()
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	scene.over_surface( hit_info.position )
	
	# Paint
	var mbl:bool = is_button and event.button_index == MOUSE_BUTTON_LEFT
	var mbr:bool = is_button and event.button_index == MOUSE_BUTTON_RIGHT
	var pressed:bool = is_button and event.is_pressed()
	
	if Input.is_mouse_button_pressed( MOUSE_BUTTON_LEFT ):
		if pressed:
			tool.action_start( hit_info )
		tool.action_primary( hit_info )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	elif Input.is_mouse_button_pressed( MOUSE_BUTTON_RIGHT ):
		if pressed:
			tool.action_start( hit_info )
		tool.action_secondary( hit_info )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	elif (mbl or mbr) and not pressed:
		tool.action_end()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	# Scale with any special key + Mouse Wheel
	if event.ctrl_pressed or event.shift_pressed or event.alt_pressed:
		if Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_UP ):
			tool.scale_by( 0.1 ) #[TODO] add to global settings
			scene.scale_by( 0.1 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_DOWN ):
			tool.scale_by( -0.1 )
			scene.scale_by( -0.1 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif not event is InputEventMouseMotion: # Pass Panning and Zoom with special keys
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _edit(object:Object):
	tool = object
	

func _handles(object:Object):
	return object is LandscaperTool

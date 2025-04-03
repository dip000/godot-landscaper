@tool
extends EditorPlugin
class_name                Landscaper
##          ┌─────────────────┼──────────────────┐         
##     ┌UIManager┐      AssetsManager      ┌SceneManager┐   
##  UIBrush  UIProperty               SceneBrush   SceneLandscaper
##                                                ProjectLandscaper

static var ui:UIManager
static var assets:AssetsManager
static var scene:SceneManager


func _enter_tree():
	ui = load(AssetsManager.UI_MANAGER).instantiate()
	assets = load(AssetsManager.ASSETS_MANAGER).instantiate()
	scene = load(AssetsManager.SCENE_MANAGER).instantiate()
	add_control_to_dock.call_deferred( EditorPlugin.DOCK_SLOT_RIGHT_UL, ui )
	set_input_event_forwarding_always_enabled()
	await get_tree().process_frame
	var viewport:SubViewport = get_editor_interface().get_editor_viewport_3d()
	viewport.add_child( assets )
	viewport.add_child( scene )

func _exit_tree():
	remove_control_from_docks( ui )
	ui.queue_free()
	assets.queue_free()
	scene.queue_free()


# Raycasts terrain colliders to track mouse pointer and sends input to an active 'SceneLandscaper' node
func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	if not ui.active.is_pressed():
		return
	
	# Accepted inputs
	var is_motion:bool = (event is InputEventMouseMotion)
	var is_button:bool = (event is InputEventMouseButton)
	
	if not (is_motion or is_button):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	# Raycast
	var result:Dictionary = scene.raycaster.feed( cam, event.get_position() ).cam_to_cursor()
	if not result:
		ui.not_over_surface()
		scene.not_over_surface()
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	ui.over_surface( result )
	scene.over_surface( result )
	
	# Paint
	var mbl:bool = is_button and event.button_index == MOUSE_BUTTON_LEFT
	var mbr:bool = is_button and event.button_index == MOUSE_BUTTON_RIGHT
	var pressed:bool = is_button and event.is_pressed()
	
	if Input.is_mouse_button_pressed( MOUSE_BUTTON_LEFT ):
		if pressed:
			ui.paint_start( result )
			scene.paint_start( result )
		ui.paint_primary( result )
		scene.paint_primary( result )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	elif Input.is_mouse_button_pressed( MOUSE_BUTTON_RIGHT ):
		if pressed:
			ui.paint_start( result )
			scene.paint_start( result )
		ui.paint_secondary( result )
		scene.paint_secondary( result )
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	elif (mbl or mbr) and not pressed:
		ui.paint_end()
		scene.paint_end()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	# Scale with any special key + Mouse Wheel
	if event.ctrl_pressed or event.shift_pressed or event.alt_pressed:
		if Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_UP ):
			ui.scale_by( 0.1 ) #[TODO] add to global settings
			scene.scale_by( 0.1 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif Input.is_mouse_button_pressed( MOUSE_BUTTON_WHEEL_DOWN ):
			ui.scale_by( -0.1 )
			scene.scale_by( -0.1 )
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif not event is InputEventMouseMotion: # Pass Panning and Zoom with special keys
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS


# Quick-saves UI properties with "Ctrl+S"
func _save_external_data():
	assets.save_ui()

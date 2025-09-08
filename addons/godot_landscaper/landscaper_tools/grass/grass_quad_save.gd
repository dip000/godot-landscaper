@tool
extends SaveData
class_name GrassSaveQuad

@export_storage var configs:Array[GrassQuadConfigs]


func set_shader_parameter(param:String, value:Variant, indexed:bool):
	for config in configs:
		if config and config.enable:
			config.set_shader_parameter( param, value, indexed )

func get_shader_parameter(param:String, default:Variant, indexed:bool) -> Variant:
	if configs and configs[0]:
		return configs[0].get_shader_parameter( param, default, indexed )
	return default


func fix_dependencies():
	for config in configs:
		if config:
			config.fix_dependencies()

func load_template():
	for config in configs:
		if config:
			config.load_template()

func load_project_data(tool:LandscaperTool):
	for config in configs:
		if config:
			config.load_project_data(tool, self)


func run_executable(executable:Executable, tool:LandscaperTool):
	_create_undo_redo("run_executable")
	for config in configs:
		if config:
			_add_undo(config)
			await config.run_executable(executable, tool, self)
			_add_redo(config)
	_commit_undo_redo()

func reset_executable(executable:Executable, tool:LandscaperTool):
	for config in configs:
		if config:
			config.reset_executable(executable, tool, self)


func select_brush(brush:Brush, tool:LandscaperTool):
	for config in configs:
		if config:
			config.select_brush(brush, tool, self)

func select_chunk_action():
	for config in configs:
		if config:
			config.select_color_action()

func action_start(hit_info:Dictionary):
	_create_undo_redo("brush_action")
	if not configs or configs and configs[0]==null:
		GLDebug.warning("Add grass configs under 'Add And Enable Grass Instances' Category")
	for config in configs:
		if config and config.enable:
			_add_undo(config)
			config.action_start(hit_info)

func action_primary(hit_info:Dictionary):
	for config in configs:
		if config and config.enable:
			config.action_primary(hit_info)

func action_secondary(hit_info:Dictionary):
	for config in configs:
		if config and config.enable:
			config.action_secondary(hit_info)

func action_end():
	for config in configs:
		if config and config.enable:
			config.action_end()
			_add_redo(config)
	_commit_undo_redo()

func action_clear():
	for config in configs:
		if config:
			config.action_clear()


func _create_undo_redo(action:String) -> void:
	Landscaper.undo_redo.commit_action(false) # closes previous commits in case of errors
	Landscaper.undo_redo.create_action("godot_landscaper/%s" %action.to_snake_case())

func _commit_undo_redo() -> void:
	Landscaper.undo_redo.commit_action(false)

func clear_undo_redo() -> void:
	Landscaper.undo_redo.commit_action(false)
	Landscaper.undo_redo.clear_history( EditorUndoRedoManager.GLOBAL_HISTORY )

func _add_redo(config:InstanceConfigs) -> void:
	var undo_redo:EditorUndoRedoManager = Landscaper.undo_redo
	undo_redo.add_do_property( config, "top_colors", config.top_colors.duplicate() )
	undo_redo.add_do_property( config, "bottom_colors", config.bottom_colors.duplicate() )
	undo_redo.add_do_property( config, "transforms", config.transforms.duplicate() )
	undo_redo.add_do_method( config.current_brush, "rebuild" )

func _add_undo(config:InstanceConfigs) -> void:
	var undo_redo:EditorUndoRedoManager = Landscaper.undo_redo
	undo_redo.add_undo_property( config, "top_colors", config.top_colors.duplicate() )
	undo_redo.add_undo_property( config, "bottom_colors", config.bottom_colors.duplicate() )
	undo_redo.add_undo_property( config, "transforms", config.transforms.duplicate() )
	undo_redo.add_undo_method( config.current_brush, "rebuild" )

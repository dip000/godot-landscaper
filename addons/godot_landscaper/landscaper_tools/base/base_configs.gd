## Per-instance configuration file for Brush classes
## Managed by LandscaperTool classes
@tool
extends Resource
class_name InstanceConfigs

## Landscaping tools will only apply enabled configs
@export var instance_index:int
@export var enable:bool = true

@export_group("Resources")
## Use your custom shader per config or use the same reference on each config for performance
@export var shader:Shader
## Use your custom material per config or use the same reference on each config for performance
@export var material:ShaderMaterial
## Use your custom mesh per config or use the same reference on each config for performance
@export var mesh:Mesh


@export_group("Size", "size_")
## Original size of the instance to spawn
@export var size_base:Vector3 = Vector3.ONE
## How much will the base size be modified randomly
@export var size_randomize:Vector3 = Vector3.ZERO

#[TODO] apply inmmediate on setters
@export_group("Rotation", "rotation_")
## Original rotation of the instance to spawn
@export var rotation_base:Vector3 = Vector3.ZERO
## How much will the base rotation be modified randomly
@export var rotation_randomize:Vector3 = Vector3.ZERO

# Rebuild data. Shared between config actions.
# Tools might override scene instances for these in case there's a missmatch
@export_storage var top_colors:Array[Color]
@export_storage var bottom_colors:Array[Color]
@export_storage var transforms:Array[Transform3D]

# Strokes are where the actual landscaping happens.
var current_brush:Brush
var current_executable:Executable

func set_instance_index(index:int):
	instance_index = index

func get_shader_parameter(param:String, default:Variant, indexed:bool) -> Variant:
	if shader and material:
		var value:Variant = material.get_shader_parameter(param)
		if value == null:
			GLDebug.error("Shader of '%s' failed setting %s=%s" % [resource_path, param, value])
		else:
			return value[instance_index] if indexed else value
	return default

func set_shader_parameter(param:String, value:Variant, indexed:bool):
	if shader and material:
		var shparam:String = "shader_parameter/"+param
		if not (shparam in material):
			GLDebug.error("Shader of '%s' failed setting %s=%s" % [self, param, value])
		elif indexed:
			material[shparam][instance_index] = value
			GLDebug.spam("Shader Set %s[%s]=%s" % [param, instance_index, value])
		else:
			material[shparam] = value
			GLDebug.spam("Shader Set %s=%s" % [param, value])


func load_project_data(tool:LandscaperTool, project:SaveData):
	current_brush.unpack(tool, project, self)
	current_brush.rebuild()

## Generic run executable
func run_executable(executable:Executable, tool:LandscaperTool, project:SaveData):
	executable.run(tool, project, self)

func reset_executable(executable:Executable, tool:LandscaperTool, project:SaveData):
	executable.reset(tool, project, self)

## Generic brush select
func select_brush(brush:Brush, tool:LandscaperTool, project:SaveData):
	current_brush = brush.duplicate()
	current_brush.unpack(tool, project, self)


## Virtual. Define what to do with missing resources
func fix_dependencies():
	pass

## Virtual. Define what to load as a template, host files in AssetsManager
func load_template():
	pass

## Brush defines what to clean up in the scene tree or otherwise
func action_clear():
	current_brush.clear()

## Start landscaping according to the current brush
func action_start(hit_info:Dictionary):
	fix_dependencies()
	current_brush.start(hit_info)

func action_primary(hit_info:Dictionary):
	current_brush.primary(hit_info)

func action_secondary(hit_info:Dictionary):
	current_brush.secondary(hit_info)

func action_end():
	current_brush.end()

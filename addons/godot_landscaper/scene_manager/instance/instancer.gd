@tool
extends Resource
class_name Instancer
## Persistent storage for any amount of instance spawning.

## Select preconfigured acion behavior
enum ActionPreset {
	MULTI_MESH_INSTANCE_3D, ## Instantiates user-custom 3D meshes in one MultiMeshInstance3D
	MULTI_MESH_INSTANCE_QUAD, ## Instantiates QuadMesh meshes in one MultiMeshInstance3D offering more customization options
	PACKED_SCENE, ## Instantiates PackedScene Nodes under a parent Node3D
}

## Brushing over the terrain will apply every enabled instancer
@export var enable:bool = true

@export_group("Type-Specific Properties") 
var mesh:Mesh
var scene:PackedScene

var texture:Texture2D:
	set(v):
		mesh.material["shader_parameter/variants"][instance_index] = v
	get:
		return mesh.material["shader_parameter/variants"][instance_index]

var quality:int:
	set(v):
		mesh.subdivide_depth = v
	get:
		return mesh.subdivide_depth

var ground_gradient:float:
	set(v):
		mesh.surface_get_material(0)["shader_parameter/ground_gradient"] = v
		#mesh.material["shader_parameter/ground_gradient"] = v
	get:
		return mesh.surface_get_material(0)["shader_parameter/ground_gradient"]


@export_group("Details", "details_")
var details_enable:bool:
	set(v):
		notify_property_list_changed()
		mesh.material["shader_parameter/details_enable"] = v
	get:
		return mesh.material["shader_parameter/details_enable"]

var detail_color:Color:
	set(v):
		mesh.material["shader_parameter/detail_color"] = v
	get:
		return mesh.material["shader_parameter/detail_color"]


@export_group("Size", "size_")
@export var size_base:Vector3 = Vector3.ONE
@export var size_randomize:Vector3 = Vector3.ZERO

@export_group("Rotation", "rotation_")
@export var rotation_base:Vector3 = Vector3.ZERO
@export var rotation_randomize:Vector3 = Vector3.ZERO

@export_storage var spawn:Action
@export_storage var color:Action

@export var preset:ActionPreset:
	set(v):
		preset = v
		match v:
			ActionPreset.MULTI_MESH_INSTANCE_3D:
				spawn = ActionMMISpawn.new()
				color = ActionMMIColor.new()
			
			ActionPreset.MULTI_MESH_INSTANCE_QUAD:
				spawn = ActionMMIQuadSpawn.new()
				color = ActionMMIColor.new()
			
			ActionPreset.PACKED_SCENE:
				spawn = ActionSceneSpawn.new()
				color = Action.new() # NOT IMPLEMENTED
		notify_property_list_changed()

#region DynamicExports
const MESH:Dictionary = {
	"name": "mesh",
	"type": TYPE_OBJECT,
	"hint": PROPERTY_HINT_RESOURCE_TYPE,
	"hint_string": "Mesh",
}

const TEXTURE:Dictionary = {
	"name": "texture",
	"type": TYPE_OBJECT,
	"hint": PROPERTY_HINT_RESOURCE_TYPE,
	"hint_string": "Texture2D",
}

const SCENE:Dictionary = {
	"name": "scene",
	"type": TYPE_OBJECT,
	"hint": PROPERTY_HINT_RESOURCE_TYPE,
	"hint_string": "PackedScene",
}
const QUALITY:Dictionary = {
	"name": "quality",
	"type": TYPE_FLOAT,
	"hint": PROPERTY_HINT_RANGE,
	"hint_string": "0,5,1,or_greater",
}
const DETAIL:Dictionary = {
	"name": "details_enable",
	"type": TYPE_BOOL,
}
const DETAIL_COLOR:Dictionary = {
	"name": "detail_color",
	"type": TYPE_COLOR,
}
const GROUND_GRADIENT:Dictionary = {
	"name": "ground_gradient",
	"type": TYPE_FLOAT,
	"hint": PROPERTY_HINT_RANGE,
	"hint_string": "0,1,0.01",
}
#endregion

## Stroke results
var transforms:Array[Transform3D]
var bottom_colors:Array[Color]
var top_colors:Array[Color]

## Stroke-constant references
var root_node:EcoInstancer
var surface_position:Vector3
var instance_index:int
var radius:float

## Stroke-constant action-specific
var add_ratio:float
var remove_ratio:float
var primary_color:Color
var secondary_color:Color

## Stroke point. Updated every frame
var cursor_position:Vector3
var face_index:int



func _get_property_list():
	var properties:Array[Dictionary]
	match preset:
		ActionPreset.MULTI_MESH_INSTANCE_3D:
			properties.append(MESH)
			properties.append(GROUND_GRADIENT)
			mesh = AssetsManager.GRASS_3D
			scene = null
			resource_name = "Grass3D"
		ActionPreset.MULTI_MESH_INSTANCE_QUAD:
			#properties.append(MESH)
			properties.append(TEXTURE)
			properties.append(QUALITY)
			properties.append(GROUND_GRADIENT)
			properties.append(DETAIL)
			if details_enable: properties.append(DETAIL_COLOR)
			mesh = QuadMesh.new()
			mesh.orientation = PlaneMesh.FACE_Y
			mesh.center_offset.y = mesh.size.y*0.5
			mesh.material = AssetsManager.MATERIAL
			scene = null
			resource_name = "QuadGrass"
		
		ActionPreset.PACKED_SCENE:
			properties.append(SCENE)
			scene = AssetsManager.STONE
			mesh = null
			resource_name = "SceneStone"
	
	return properties

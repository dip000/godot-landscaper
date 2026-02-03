extends Resource
class_name GLScanData

# Expensive caches
# Use with GLSurfaceScanner
var mesh_instance:MeshInstance3D

var mdts:Dictionary[int, MeshDataTool]
var mdt:MeshDataTool:
	get: return mdts.get(shape)

var color_sources:Dictionary[int, Variant]
var color_source:Variant:
	get: return color_sources.get(shape)


# hit_info as in PhysicsDirectSpaceState3D.intersect_ray(..)
# Use with GLSceneRaycaster
var body:CollisionObject3D
var shape:int
var face_index:int
var position:Vector3
var normal:Vector3


func set_hit_info(hit_info:Dictionary):
	body = hit_info.collider
	face_index = hit_info.face_index
	position = hit_info.position
	normal = hit_info.normal
	shape = hit_info.shape

func has_new_shape() -> bool:
	return not mdts.has( shape )

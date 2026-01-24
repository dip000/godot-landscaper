extends RefCounted
class_name GLScanData

# Expensive caches
# Use with GLSurfaceScanner
var cached_collider:CollisionObject3D
var mesh_instance:MeshInstance3D
var mdts:Array[MeshDataTool]
var images:Array[Image]
var colors:Array[Color]

# hit_info as in PhysicsDirectSpaceState3D.intersect_ray(..)
# Use with SceneRaycaster
var collider:CollisionObject3D
var face_index:int
var shape:int
var position:Vector3
var normal:Vector3


func set_hit_info(hit_info:Dictionary) -> GLScanData:
	if hit_info:
		collider = hit_info.collider
		face_index = hit_info.face_index
		shape = hit_info.shape
		position = hit_info.position
		normal = hit_info.normal
	return self

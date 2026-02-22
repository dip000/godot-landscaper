## Scene Raycaster.
##
## An instance of this node will always be running and can be accessed
## with 'GLandscaper.scene.raycaster'. Use this instance for raycasting
## over the terrain.
## For more complex scene scanning, use GLSurfaceScanner

@tool
extends Node3D
class_name GLSceneRaycaster

const LAYER_ALL_NOT_INTERNAL:int = 0x7FFFFFFF # All but last layer
const LAYER_INTERNAL:int = 0x8000_0000 # Last layer
const LAYER_ALL:int = 0xFFFF_FFFF

var _ray_surfaces := PhysicsRayQueryParameters3D.new()
var _ray_points := PhysicsRayQueryParameters3D.new()
var _direct_space_state:PhysicsDirectSpaceState3D


func _ready():
	_direct_space_state = get_world_3d().direct_space_state


func update_collision_mask(mask:int):
	_ray_surfaces.collision_mask = mask


func cam_to_surface(cam:Camera3D, mouse_pos:Vector2) -> Dictionary:
	var result:Dictionary
	if _direct_space_state:
		_ray_surfaces.from = cam.project_ray_origin( mouse_pos )
		_ray_surfaces.to = _ray_surfaces.from + (cam.project_ray_normal( mouse_pos ) * cam.far)
		result = _direct_space_state.intersect_ray( _ray_surfaces )
		if not result:
			## The grid must be the lowest hit priority.
			## CollisionObject3D.collision_priority doesn't seem to work in this case
			## Next best thing is set-retry-reset dynamically
			_ray_surfaces.collision_mask |= LAYER_INTERNAL
			result = _direct_space_state.intersect_ray( _ray_surfaces )
			_ray_surfaces.collision_mask &= ~LAYER_INTERNAL
	return result


func point_to_point(from:Vector3, to:Vector3) -> Dictionary:
	if _direct_space_state:
		_ray_points.from = from
		_ray_points.to = to
		return _direct_space_state.intersect_ray( _ray_points )
	return {}

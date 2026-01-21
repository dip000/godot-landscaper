## Scene Raycaster.
##
## An instance of this node will always be running and can be accessed
## with 'Landscaper.scene.raycaster'. Use this instance for raycasting
## over the terrain.
## For more complex scene scanning, use GLSurfaceScanner

@tool
extends Node3D
class_name SceneRaycaster

var _ray_surfaces := PhysicsRayQueryParameters3D.new()
var _ray_points := PhysicsRayQueryParameters3D.new()
var _direct_space_state:PhysicsDirectSpaceState3D


func _ready():
	_direct_space_state = get_world_3d().direct_space_state


func set_collision_mask(collision_mask:int):
	_ray_surfaces.collision_mask = collision_mask


func cam_to_surface(cam:Camera3D, mouse_pos:Vector2) -> Dictionary:
	if _direct_space_state:
		_ray_surfaces.from = cam.project_ray_origin( mouse_pos )
		_ray_surfaces.to = _ray_surfaces.from + (cam.project_ray_normal( mouse_pos ) * cam.far)
		return _direct_space_state.intersect_ray( _ray_surfaces )
	return {}


func point_to_point(from:Vector3, to:Vector3) -> Dictionary:
	if _direct_space_state:
		_ray_points.from = from
		_ray_points.to = to
		return _direct_space_state.intersect_ray( _ray_points )
	return {}

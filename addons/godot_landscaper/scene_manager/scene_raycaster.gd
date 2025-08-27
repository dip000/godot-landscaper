## Raycaster utilities
## Pretty much a static class
@tool
extends Node3D
class_name SceneRaycaster

static var hit_info:Dictionary
var _ray_surfaces := PhysicsRayQueryParameters3D.new()
var _ray_points := PhysicsRayQueryParameters3D.new()
var _direct_space_state:PhysicsDirectSpaceState3D:
	get:
		if _direct_space_state:
			return _direct_space_state
		else:
			var root_scene:Node = get_tree().edited_scene_root
			if root_scene is Node3D:
				_direct_space_state = root_scene.get_world_3d().direct_space_state
			return _direct_space_state

@onready var scene_brush:SceneBrush = %SceneBrush


func update_hit_info(cam:Camera3D, mouse_pos:Vector2) -> Dictionary:
	if _direct_space_state:
		_ray_surfaces.from = cam.project_ray_origin( mouse_pos )
		_ray_surfaces.to = _ray_surfaces.from + (cam.project_ray_normal( mouse_pos ) * cam.far)
		return _direct_space_state.intersect_ray( _ray_surfaces )
	return {}


func set_collision_mask(collision_mask:int):
	_ray_surfaces.collision_mask = collision_mask


func point_to_point(from:Vector3, to:Vector3) -> Dictionary:
	if _direct_space_state:
		_ray_points.from = from
		_ray_points.to = to
		return _direct_space_state.intersect_ray( _ray_points )
	return {}

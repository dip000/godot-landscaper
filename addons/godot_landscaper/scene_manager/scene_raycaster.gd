@tool
extends Node3D
class_name SceneRaycaster

const BRUSH_LAYER:int = 0xFFFFFFFF
static var hit_info:Dictionary

@onready var scene_brush:SceneBrush = %SceneBrush

var _ray_surfaces := PhysicsRayQueryParameters3D.new()



func _ready():
	_ray_surfaces.collide_with_areas = false
	_ray_surfaces.collide_with_bodies = true


func _safe_intersect(ray:PhysicsRayQueryParameters3D) -> Dictionary:
	var root_scene:Node = get_tree().edited_scene_root
	if root_scene is Node3D:
		return root_scene.get_world_3d().direct_space_state.intersect_ray( ray )
	return {}


func update_hit_info(cam:Camera3D, mouse_pos:Vector2) -> Dictionary:
	_ray_surfaces.from = cam.project_ray_origin( mouse_pos )
	_ray_surfaces.to = _ray_surfaces.from + (cam.project_ray_normal( mouse_pos ) * cam.far)
	hit_info = _safe_intersect( _ray_surfaces )
	return hit_info

func set_collision_mask(collision_mask:int):
	_ray_surfaces.collision_mask = collision_mask



func point_to_point(from:Vector3, to:Vector3) -> Dictionary:
	_ray_surfaces.from = from
	_ray_surfaces.to = to
	_ray_surfaces.collision_mask = 0xFFFFFFFF
	return _safe_intersect( _ray_surfaces )

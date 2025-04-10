@tool
extends Node3D
class_name SceneRaycaster

const BRUSH_LAYER:int = 0xFFFFFFFF

@onready var scene_brush:SceneBrush = %SceneBrush

var _ray_surfaces := PhysicsRayQueryParameters3D.new()
var _cam:Camera3D
var _mouse_pos:Vector2


func _ready():
	_ray_surfaces.collide_with_areas = false
	_ray_surfaces.collide_with_bodies = true


func _safe_intersect(ray:PhysicsRayQueryParameters3D) -> Dictionary:
	var root_scene:Node = get_tree().edited_scene_root
	if root_scene is Node3D:
		return root_scene.get_world_3d().direct_space_state.intersect_ray( ray )
	return {}


func feed(cam:Camera3D, mouse_pos:Vector2) -> SceneRaycaster:
	_cam = cam
	_mouse_pos = mouse_pos
	return self


func cam_to_cursor() -> Dictionary:
	_ray_surfaces.from = _cam.project_ray_origin( _mouse_pos )
	_ray_surfaces.to = _ray_surfaces.from + (_cam.project_ray_normal( _mouse_pos ) * _cam.far)
	_ray_surfaces.collision_mask = 0xFFFFFFFF
	return _safe_intersect( _ray_surfaces )
	

func point_to_point(from:Vector3, to:Vector3) -> Dictionary:
	_ray_surfaces.from = from
	_ray_surfaces.to = to
	_ray_surfaces.collision_mask = 0xFFFFFFFF
	return _safe_intersect( _ray_surfaces )

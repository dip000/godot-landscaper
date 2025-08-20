@tool
extends Node3D
class_name SceneManager

@onready var raycaster:SceneRaycaster = $Raycaster
@onready var brush:SceneBrush = $SceneBrush


static func find_or_create_node(type, parent:Node, child_name:String):
	if parent.has_node( child_name ):
		GLDebug.internal("Found node %s" %child_name)
		return parent.get_node( child_name )
	return create_node( type, parent, child_name )


static func create_node(type, parent:Node, child_name:String) -> Node:
	var child:Node = type.new()
	parent.add_child( child )
	child.name = child_name
	child.owner = parent.owner
	GLDebug.internal("Created node %s" %child_name)
	return child


static func scan_mesh_from_hit_info(scan_parent:bool, scan_children:bool, ref_path:String) -> MeshInstance3D:
	if SceneRaycaster.hit_info:
		var collider:CollisionObject3D = SceneRaycaster.hit_info.collider
		return scan_mesh( collider, scan_parent, scan_children, ref_path )
	return null


static func scan_mesh(collider:CollisionObject3D, scan_parent:bool, scan_children:bool, ref_path:String) -> MeshInstance3D:
	if not collider:
		return null
	
	if scan_parent:
		var parent:Node = collider.get_parent()
		return parent if parent is MeshInstance3D else null
	
	if scan_children:
		for node in collider.get_children():
			if node is MeshInstance3D:
				return node
	
	if ref_path.is_relative_path():
		var node:Node = collider.get_node_or_null( ref_path )
		return node if node is MeshInstance3D else null
	
	return null


static func scan_material(instance:MeshInstance3D, active_material_indexes:Array[int]) -> Material:
	if not instance:
		return null
	
	for index in active_material_indexes:
		var material:Material = instance.get_active_material(index)
		if material:
			return material
	return null


static func scan_color_source(material:Material, standar_material_paths:Array[String], shader_material_paths:Array[String]) -> Variant:
	if not material:
		return null
	
	if material is StandardMaterial3D:
		for path in standar_material_paths:
			if path in material:
				return material[path]
	
	if material is ShaderMaterial:
		for path in standar_material_paths:
			if "shader_parameters/"+path in material:
				return material.get_shader_parameter(path)
	
	return null



func over_surface(pos:Vector3):
	brush.over_surface( pos )

func not_over_surface():
	brush.not_over_surface()

func scale_by(sca:float):
	brush.scale_by( sca )

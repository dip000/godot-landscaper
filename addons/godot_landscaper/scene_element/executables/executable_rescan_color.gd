@tool
extends Executable
class_name ExecMMIRescanColor

## Range in meters on Y axis that the grass will try to scan for a surface to sit on
@export var min_vertical_offset:float = -2.0
@export var max_vertical_offset:float = 2.0

var original_bottom_colors:Array[Color]


func run(element:SceneElement, save_data:GLSaveData) -> String:
	var anchor_node:Node = element.anchor_node
	if not anchor_node: return "'Anchor Node' not found"
	
	var original_mmi:MultiMeshInstance3D = element.anchor_node.get_node_or_null(NodePath(element.name))
	if not original_mmi: return "No 'MultiMeshInstance' to chunkify"
	
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	original_bottom_colors = save_data.bottom_colors.duplicate()
	
	for i in save_data.transforms.size():
		var original_transf:Transform3D = save_data.transforms[i]
		var global_position:Vector3 = original_mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position + Vector3.UP*max_vertical_offset
		var scan_lower:Vector3 = global_position + Vector3.UP*min_vertical_offset
		
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		if not result: continue
		
		var cache:Scanner.Cache = Scanner.cache_scan( result.collider, element, true )
		if cache.new:
			# PhysicsBody3D nodes require a frame after being created to detect raycasts
			await _frame()
			result = raycaster.point_to_point(scan_upper, scan_lower)
			if not result: continue
		
		var color:Color = Scanner.scan_color( result, cache )
		save_data.bottom_colors[i] = color
		await _index(i)
	
	Scanner.clear_cache()
	element.stroke_rebuild()
	GLDebug.state("Bottom grass was recolored from Ground Coloring settings")
	return "OK"


func reset(element:SceneElement, save_data:GLSaveData) -> String:
	var anchor_node:Node = element.anchor_node
	if not anchor_node: return "'Anchor Node' not found"
	
	var original_mmi:MultiMeshInstance3D = element.anchor_node.get_node_or_null(NodePath(element.name))
	if not original_mmi: return "No 'MultiMeshInstance' to chunkify"
	
	save_data.bottom_colors = original_bottom_colors
	element.stroke_rebuild()
	GLDebug.state("Grass colors were restored from previous action")
	return "OK"

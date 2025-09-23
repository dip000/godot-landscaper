@tool
extends Executable
class_name ExecMMIRescanLevel

## Range in meters on Y axis that the grass will try to scan for a surface to sit on
@export var min_vertical_offset:float = -2.0
@export var max_vertical_offset:float = 2.0

var original_top_colors:Array[Color]
var original_bottom_colors:Array[Color]
var original_transforms:Array[Transform3D]


func run(element:SceneElement, save_data:GLSaveData) -> String:
	var anchor_node:Node = element.anchor_node
	if not anchor_node: return "'Anchor Node' not found"
	
	var original_mmi:MultiMeshInstance3D = element.anchor_node.get_node_or_null(NodePath(element.name))
	if not original_mmi: return "No 'MultiMeshInstance' to chunkify"
	
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	var original_size:int = save_data.transforms.size()
	var updated_instances:int = 0
	var new_transforms:Array[Transform3D]
	original_top_colors = save_data.top_colors.duplicate()
	original_bottom_colors = save_data.bottom_colors.duplicate()
	original_transforms = save_data.transforms.duplicate()
	
	for i in original_size:
		var original_transf:Transform3D = save_data.transforms[i]
		var global_position:Vector3 = original_mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position + Vector3.UP*max_vertical_offset
		var scan_lower:Vector3 = global_position + Vector3.UP*min_vertical_offset
		
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		if not result: continue
		
		var cache:Scanner.Cache = Scanner.cache_scan( result.collider, element, false )
		if cache.new:
			await _frame()
			result = raycaster.point_to_point(scan_upper, scan_lower)
			if not result: continue
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
		var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
		# Compose rotation using quaternion magic
		basis *= Basis(
			# PI*0.5 on X axis compenzates for looking at the sky as mentioned before
			Quaternion(Vector3.RIGHT, save_data.rotation_base.x - PI * 0.5) *
			Quaternion(Vector3.UP, save_data.rotation_base.y) *
			Quaternion(Vector3.FORWARD, save_data.rotation_base.z) *
			Quaternion(Vector3.RIGHT, randf()*save_data.rotation_randomize.x) *
			Quaternion(Vector3.UP, randf()*save_data.rotation_randomize.y) *
			Quaternion(Vector3.FORWARD, randf()*save_data.rotation_randomize.z)
		)
		
		# to_local() takes rotation in consideration. Then feed back to result as global for color scaning
		var local_pos:Vector3 = original_mmi.to_local( result.position )
		result.position = local_pos + element.anchor_node.global_position
		
		# Save base and random values
		var local_transf:Transform3D = Transform3D( basis, local_pos )
		var size_offset:Vector3 = save_data.size_randomize * randf()
		local_transf = local_transf.scaled_local( save_data.size_base + size_offset )
		
		new_transforms.append( local_transf )
		await _index(i)
	
	# Resize down the new values if some were lost
	var new_size:int = new_transforms.size()
	if updated_instances != new_size:
		save_data.top_colors.resize(new_size)
		save_data.bottom_colors.resize(new_size)
	
	# Dump new transforms
	save_data.transforms = new_transforms
	
	original_mmi.global_position = element.anchor_node.global_position
	var lost_instances:int = original_size - new_size
	
	element.stroke_rebuild()
	Scanner.clear_cache()
	GLDebug.state("Grass was repositioned in Y axis. %s instances were lost" %lost_instances)
	return "OK"


func reset(element:SceneElement, save_data:GLSaveData) -> String:
	var anchor_node:Node = element.anchor_node
	if not anchor_node: return "'Anchor Node' not found"
	
	var original_mmi:MultiMeshInstance3D = element.anchor_node.get_node_or_null(NodePath(element.name))
	if not original_mmi: return "No 'MultiMeshInstance' to chunkify"
	
	if original_top_colors.size() * original_bottom_colors.size() * original_transforms.size() == 0:
		return "Nothing to reset"
	
	save_data.top_colors = original_top_colors
	save_data.bottom_colors = original_bottom_colors
	save_data.transforms = original_transforms
	element.stroke_rebuild()
	GLDebug.state("Grass positions were restored from previous action")
	return "OK"

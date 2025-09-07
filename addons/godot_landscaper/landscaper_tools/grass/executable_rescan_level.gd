@tool
extends Executable
class_name ExecMMIRescanLevel

## Range in meters on Y axis that the grass will try to scan for a surface to sit on
@export var min_vertical_offset:float = -2.0
@export var max_vertical_offset:float = 2.0

@export var min_horizontal_offset:float = 0.0
@export var max_horizontal_offset:float = 0.0

@export_tool_button("Rescan Ground Level", "UndoRedo") var _run:Callable = run_executable


func run(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	var mmi:MultiMeshInstance3D = tool.anchor_node.get_node_or_null(config.resource_name)
	if not mmi: return
	
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	var original_size:int = config.transforms.size()
	var original_top_colors:Array[Color] = config.top_colors
	var original_bottom_colors:Array[Color] = config.bottom_colors
	var new_transforms:Array[Transform3D]
	var new_bottom_colors:Array[Color]
	var new_top_colors:Array[Color]
	
	for i in original_size:
		var original_transf:Transform3D = config.transforms[i]
		var global_position:Vector3 = mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position + Vector3.UP*max_vertical_offset
		var scan_lower:Vector3 = scan_upper + Vector3.UP*min_vertical_offset
		
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		if not result: continue
		
		var cache:Scanner.Cache = Scanner.cache_scan( result.collider, tool, false )
		if cache.new:
			await Engine.get_main_loop().process_frame
			result = raycaster.point_to_point(scan_upper, scan_lower)
			if not result: continue
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
		var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
		# Compose rotation using quaternion magic
		basis *= Basis(
			# PI*0.5 on X axis compenzates for looking at the sky as mentioned before
			Quaternion(Vector3.RIGHT, config.rotation_base.x - PI * 0.5) *
			Quaternion(Vector3.UP, config.rotation_base.y) *
			Quaternion(Vector3.FORWARD, config.rotation_base.z) *
			Quaternion(Vector3.RIGHT, randf()*config.rotation_randomize.x) *
			Quaternion(Vector3.UP, randf()*config.rotation_randomize.y) *
			Quaternion(Vector3.FORWARD, randf()*config.rotation_randomize.z)
		)
		
		# to_local() takes rotation in consideration. Then feed back to result as global for color scaning
		var local_pos:Vector3 = mmi.to_local( result.position )
		result.position = local_pos + tool.anchor_node.global_position
		
		# Save base and random values
		var local_transf := Transform3D( basis, local_pos )
		var size_offset:Vector3 = config.size_randomize * randf()
		local_transf = local_transf.scaled_local( config.size_base + size_offset )
		
		new_transforms.append( local_transf )
		new_bottom_colors.append( original_bottom_colors[i] )
		new_top_colors.append( original_top_colors[i] )
	
	config.top_colors = new_top_colors
	config.bottom_colors = new_bottom_colors
	config.transforms = new_transforms
	mmi.global_position = tool.anchor_node.global_position
	
	var new_size:int = config.transforms.size()
	var lost_instances:int = original_size - new_size
	
	Scanner.clear_cache()
	GLDebug.state("Grass was repositioned in Y axis. %s instances were lost" %lost_instances)

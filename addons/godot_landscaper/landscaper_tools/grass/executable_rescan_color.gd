@tool
extends Executable
class_name ExecMMIRescanColor

## Range in meters on Y axis that the grass will try to scan for a surface to sit on
@export var min_vertical_offset:float = -2.0
@export var max_vertical_offset:float = 2.0
@export_tool_button("Rescan Bottom Color", "UndoRedo") var _run:Callable = run_executable


func run(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	var mmi:MultiMeshInstance3D = tool.anchor_node.get_node_or_null(config.resource_name)
	if not mmi: return
	
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	
	for i in config.transforms.size():
		var original_transf:Transform3D = config.transforms[i]
		var global_position:Vector3 = mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position + Vector3.UP*max_vertical_offset
		var scan_lower:Vector3 = scan_upper + Vector3.UP*min_vertical_offset
		
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		if not result: continue
		
		var cache:Scanner.Cache = Scanner.cache_scan( result.collider, tool, true )
		if cache.new:
			# PhysicsBody3D nodes require a frame after being created to detect raycasts
			await Engine.get_main_loop().process_frame
			result = raycaster.point_to_point(scan_upper, scan_lower)
			if not result: continue
		
		var color:Color = Scanner.scan_color( result, cache )
		config.bottom_colors[i] = color
	
	Scanner.clear_cache()
	GLDebug.state("Bottom grass was recolored from Ground Coloring settings")

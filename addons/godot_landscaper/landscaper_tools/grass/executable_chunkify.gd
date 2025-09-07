@tool
extends Executable
class_name ExecMMIChunkify

const META_MIN_INDEX:int = 0
const META_MAX_INDEX:int = 1
const META_COUNT:int = 2

@export var chunk_size:int = 32:
	set(v): chunk_size = max(1, v)
@export var chunks_parent_name:String = "Chunks"

@export_tool_button("     Chunkify     ", "Grid") var _run:Callable = run_executable
@export_tool_button(" Reset Chunks ", "Object") var _reset:Callable = reset_executable


func run(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	var original_mmi:MultiMeshInstance3D = tool.anchor_node.get_node_or_null(config.resource_name)
	if not original_mmi: return
	
	reset(tool, project, config)
	original_mmi.hide()
	
	await Engine.get_main_loop().process_frame
	var root_parent:Node = SceneManager.find_or_create_node(Node3D, tool.anchor_node, chunks_parent_name)
	
	var original_mm:MultiMesh = original_mmi.multimesh
	var aabb:AABB = original_mmi.get_aabb()
	var size:Vector3 = aabb.size
	var pos:Vector3 = aabb.position
	var lower_bound:Vector3 = pos + original_mmi.global_position
	var upper_bound:Vector3 = pos + size + original_mmi.global_position
	var lower_chunk:Vector2i = (Vector2(lower_bound.x, lower_bound.z) / float(chunk_size)).floor()
	var upper_chunk:Vector2i = (Vector2(upper_bound.x, upper_bound.z) / float(chunk_size)).floor()
	var total_chunks:Vector2i = upper_chunk - lower_chunk + Vector2i.ONE
	
	GLDebug.internal("------------------------------")
	GLDebug.internal("LowerBound: %s, UpperBound: %s" %[lower_bound, upper_bound])
	GLDebug.internal("LowerChunk: %s, UpperChunk: %s" %[lower_chunk, upper_chunk])
	GLDebug.internal("TotalChunks: %s" %total_chunks)
	
	# Every original index mapped as chunks
	# This avoids making and managing arrays of ChunkX[ChunkY[Transforms[],Colors[],Colors[],Min,Max]]
	# Instead just ChunkX[ChunkY[raw[min,max,indexes]]]
	var chunked_index_map:Array[Array]
	chunked_index_map.resize(total_chunks.x)
	
	# Fill map for performance, i guess
	for x in total_chunks.x:
		chunked_index_map[x].resize(total_chunks.y)
		for y in total_chunks.y:
			# Add min, max space for later
			var raw:Array
			raw.resize(META_COUNT)
			raw[META_MIN_INDEX] = Vector3.INF
			raw[META_MAX_INDEX] = -Vector3.INF
			chunked_index_map[x][y] = raw
	
	
	# Remaps MultiMesh data into chunk indexes
	for original_index in original_mm.instance_count:
		var original_local_transf:Transform3D = original_mm.get_instance_transform( original_index )
		var original_global_pos:Vector3 = original_mmi.to_global( original_local_transf.origin )
		var original_global_h_pos:Vector2 = Vector2(original_global_pos.x, original_global_pos.z)
		var global_chunk_coords:Vector2i = ( original_global_h_pos / float(chunk_size)).floor()
		
		# Make sure to index with positive numbers
		var positive:Vector2i = global_chunk_coords - lower_chunk
		var raw:Array = chunked_index_map[positive.x][positive.y]
		
		# Find Min/Max positions and store them as metadata
		# This creates a bounding box for each MultiMeshInstance3D
		raw[META_MIN_INDEX] = raw[META_MIN_INDEX].min( original_global_pos )
		raw[META_MAX_INDEX] = raw[META_MAX_INDEX].max( original_global_pos )
		raw.append( original_index )
		
	
	# Rebuilds MultiMeshInstance3D knowing the chunked indexes
	for row_index in chunked_index_map.size():
		var row:Array = chunked_index_map[row_index]
		
		for col_index in row.size():
			# Separate Raw with indexes
			var raw:Array = row[col_index]
			var original_indexes:Array = raw.slice( META_COUNT )
			
			if original_indexes.size() <= 0:
				continue
			
			# Return to global (possible) negative chunks
			var global_chunk:Vector2i = Vector2i( row_index, col_index ) + lower_chunk
			
			# Find center of the chunk instances (not to confuse with center of chunk)
			var global_min:Vector3 = raw[META_MIN_INDEX]
			var global_max:Vector3 = raw[META_MAX_INDEX]
			var global_center:Vector3 = global_min + 0.5*(global_max - global_min)
			
			# Place slot holders right in the middle of the chunk
			var slot_parent:Node3D = SceneManager.find_or_create_node(Node3D, root_parent, "Chunk_%s_%s" %[global_chunk.x, global_chunk.y])
			var instance_mmi:MultiMeshInstance3D = SceneManager.find_or_create_node(MultiMeshInstance3D, slot_parent, "%s_%s_%s" %[original_mmi.name, global_chunk.x, global_chunk.y])
			slot_parent.global_position = Vector3(global_chunk.x+0.5, 0 , global_chunk.y+0.5)
			slot_parent.global_position *= chunk_size
			
			# Place individual multimeshes in their global center position
			instance_mmi.global_position = global_center
			
			# Setup MultiMesh
			_fill_mmi(instance_mmi, original_mmi)
			var instance_mm:MultiMesh = instance_mmi.multimesh
			instance_mm.instance_count = original_indexes.size()
			GLDebug.spam("Chunk[row,col](%s,%s) = Raw[min,max,indexes.size()]%s" %[row_index, col_index, raw.size()])
			
			# Find the mapped instance data and dump it into the new Multi Meshes
			var instance_index:int = 0
			for original_index in original_indexes:
				
				# Compenzate moving the origin of the MMI Node by moving back each instance
				# By doing the whole local-global-local switcheroo, we include any rotation the referenced nodes might have
				var local_transform:Transform3D = original_mm.get_instance_transform( original_index )
				var world_pos: Vector3 = original_mmi.to_global(local_transform.origin)
				var local_pos: Vector3 = instance_mmi.to_local(world_pos)
				local_transform = Transform3D(local_transform.basis, local_pos)
				
				var colors_top:Color = original_mm.get_instance_custom_data( original_index )
				var colors_bottom:Color = original_mm.get_instance_color( original_index )
				
				instance_mm.set_instance_transform( instance_index, local_transform )
				instance_mm.set_instance_custom_data( instance_index, colors_top )
				instance_mm.set_instance_color( instance_index, colors_bottom )
				
				instance_index += 1

func reset(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	var original_mmi:MultiMeshInstance3D = tool.anchor_node.get_node_or_null(config.resource_name)
	if not original_mmi: return
	
	original_mmi.show()
	
	var root_parent:Node = tool.anchor_node.get_node_or_null(chunks_parent_name)
	if root_parent:
		root_parent.queue_free()
	

func _fill_mmi(new_mmi:MultiMeshInstance3D, original_mmi:MultiMeshInstance3D):
	new_mmi["instance_shader_parameters/variant_index"] = original_mmi["instance_shader_parameters/variant_index"]
	new_mmi.multimesh = MultiMesh.new()
	new_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	new_mmi.multimesh.mesh = original_mmi.multimesh.mesh
	new_mmi.multimesh.use_custom_data = true
	new_mmi.multimesh.use_colors = true
	

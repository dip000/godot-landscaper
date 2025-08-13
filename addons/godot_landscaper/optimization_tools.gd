@tool
extends Resource
class_name OptimizationTools

@export_group("Chunkify Grass")
@export var parent_node:NodePath = "."
@export var chunk_size:int = 32
@export_tool_button("     Chunkify     ", "Grid") var chunkify:Callable = _chunkify
@export_tool_button("        Reset        ", "Object") var reset_chunks:Callable = _reset_chunks

@export_group("Visibility And Level Of Detail")
@export_range(0.0, 1.0, 0.01) var visible_instances:float = 1.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32
@export_tool_button("      Update      ", "UndoRedo") var change_visible:Callable = _update_visiblity



func _chunkify():
	if not Engine.is_editor_hint() or not Landscaper.is_enabled:
		return
	
	if chunk_size < 4:
		GLDebug.error("Cannot chunkify below 4 meters!")
		return
	
	var tool:BakedQuadGrass = Landscaper.tool
	var parent:Node = tool.get_node(parent_node)
	
	for instance in tool.surface_mesh.get_children():
		if instance is MultiMeshInstance3D:
			instance.hide()
			_apply_to_instance( parent, instance )


func _reset_chunks():
	if not Engine.is_editor_hint() or not Landscaper.is_enabled:
		return
	
	var tool:BakedQuadGrass = Landscaper.tool
	var root:Node = tool.get_node(parent_node)
	
	# Show original instances
	for node in tool.surface_mesh.get_children():
		if node is MultiMeshInstance3D:
			node.show()
			node.visibility_range_end = 0
			node.visibility_range_end_margin = 0
	
	# Chunkified instances
	for grass_type in root.get_children():
		if grass_type is Node3D:
			grass_type.queue_free()
	

func _update_visiblity():
	if not Engine.is_editor_hint() or not Landscaper.is_enabled:
		return
	
	var tool:BakedQuadGrass = Landscaper.tool
	var holder:Node = tool.get_node(parent_node)
	
	# Original instances
	for node in tool.surface_mesh.get_children():
		if node is MultiMeshInstance3D:
			node.multimesh.visible_instance_count = node.multimesh.instance_count*visible_instances
			node.visibility_range_end = custom_lod_meters
			node.visibility_range_end_margin = 2.0 if custom_lod_meters > 0 else 0
	
	# Chunkified instances
	for grass_type in holder.get_children():
		for row in grass_type.get_children():
			for col in row.get_children():
				if col is MultiMeshInstance3D:
					col.multimesh.visible_instance_count = col.multimesh.instance_count*visible_instances
					col.visibility_range_end = custom_lod_meters
					col.visibility_range_end_margin = 2.0 if custom_lod_meters > 0 else 0


func _apply_to_instance(root_parent:Node, original_mmi:MultiMeshInstance3D):
	var aabb:AABB = original_mmi.get_aabb()
	var size:Vector3 = aabb.size
	var pos:Vector3 = aabb.position
	var lower_bound:Vector3 = pos + original_mmi.global_position
	var upper_bound:Vector3 = pos + size + original_mmi.global_position
	var lower_chunk:Vector2i = (Vector2(lower_bound.x, lower_bound.z) / float(chunk_size)).floor()
	var upper_chunk:Vector2i = (Vector2(upper_bound.x, upper_bound.z) / float(chunk_size)).floor()
	var total_chunks:Vector2i = upper_chunk - lower_chunk + Vector2i.ONE
	
	GLDebug.internal("LowerBound: %s, UpperBound: %s" %[lower_bound, upper_bound])
	GLDebug.internal("LowerChunk: %s, UpperChunk: %s" %[lower_chunk, upper_chunk])
	GLDebug.internal("TotalChunks: %s" %total_chunks)
	
	# Move the parent to the instance so every calculation over the children can be local
	var variant_parent:Node3D = SceneManager.find_or_create_node(Node3D, root_parent, "%sChunks" %original_mmi.name)	
	var variant_h_position := Vector2(original_mmi.global_position.x, original_mmi.global_position.z) 
	variant_parent.global_transform = original_mmi.global_transform
	
	# Every original index mapped as chunks
	# [TODO] Optimize using Array[Array[Dictionary]]
	var chunked_index_map:Dictionary[int, Dictionary]
	var original_mm:MultiMesh = original_mmi.multimesh
	
	# Remaps MultiMesh data in chunk indexes
	for original_index in original_mm.instance_count:
		var transf:Transform3D = original_mm.get_instance_transform( original_index )
		var h_pos:Vector2 = Vector2(transf.origin.x, transf.origin.z)
		var chunk_coords:Vector2i = ( h_pos / float(chunk_size)).floor()
		
		# Get or create the X/Y collections
		var chunk_x_map: Dictionary = chunked_index_map.get(chunk_coords.x, {})
		var chunk_y_list: Array = chunk_x_map.get(chunk_coords.y, [])
		
		chunk_y_list.append(original_index)
		chunk_x_map[chunk_coords.y] = chunk_y_list
		chunked_index_map[chunk_coords.x] = chunk_x_map
	
	
	# Rebuilds MultiMeshInstance3D knowing the chunked indexes
	for row in chunked_index_map:
		var row_parent:Node3D = SceneManager.find_or_create_node(Node3D, variant_parent, "Row%s"%row)	
		
		for col in chunked_index_map[row]:
			var original_indexes:Array = chunked_index_map[row][col]
			var instance_mmi:MultiMeshInstance3D = SceneManager.find_or_create_node(MultiMeshInstance3D, row_parent, "Col%s" %col)
			fill_mmi(instance_mmi, original_mmi)
			
			var instance_mm:MultiMesh = instance_mmi.multimesh
			instance_mm.instance_count = original_indexes.size()
			GLDebug.spam("Chunk(%s,%s) = Indexes%s" %[row, col, original_indexes])
			
			var instance_index:int = 0
			for original_index in original_indexes:
				var transform:Transform3D = original_mm.get_instance_transform( original_index )
				var colors_top:Color = original_mm.get_instance_custom_data( original_index )
				var colors_bottom:Color = original_mm.get_instance_color( original_index )
				
				instance_mm.set_instance_transform( instance_index, transform )
				instance_mm.set_instance_custom_data( instance_index, colors_top )
				instance_mm.set_instance_color( instance_index, colors_bottom )
				
				instance_index += 1
	


func fill_mmi(new_mmi:MultiMeshInstance3D, original_mmi:MultiMeshInstance3D):
	new_mmi["instance_shader_parameters/variant_index"] = original_mmi["instance_shader_parameters/variant_index"]
	new_mmi.multimesh = MultiMesh.new()
	new_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	new_mmi.multimesh.mesh = original_mmi.multimesh.mesh
	new_mmi.multimesh.use_custom_data = true
	new_mmi.multimesh.use_colors = true
	

@tool
extends Resource
class_name OptimizationTools


static func chunkify_mmi():
	if not Engine.is_editor_hint() or not Landscaper.is_enabled:
		return
	
	var tool:BakedQuadGrass = Landscaper.tool
	if tool.chunk_size.x < 4 or tool.chunk_size.y < 4:
		GLDebug.error("Cannot chunkify below 4 meters!")
		return
	GLDebug.state("chunkify_mmi NOT-IMPLEMENTED")


static func reset_chunks():
	if not Engine.is_editor_hint() or not Landscaper.is_enabled:
		return
	
	var tool:BakedQuadGrass = Landscaper.tool
	GLDebug.state("reset_chunks NOT-IMPLEMENTED")


static func update_visiblity():
	if not Engine.is_editor_hint() or not Landscaper.is_enabled:
		return
	
	var tool:BakedQuadGrass = Landscaper.tool
	GLDebug.state("update_visiblity NOT-IMPLEMENTED")

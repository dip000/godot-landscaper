@tool
extends Resource
class_name RebuildQuadGrass

@export_tool_button("   Reload Transforms    ", "UndoRedo") var reload_transforms:Callable = _reload_transforms
@export_tool_button("Repaint Ground Colors", "Color") var repaint_ground:Callable = _repaint_ground



func _repaint_ground():
	if not Landscaper.running():
		return
	
	GLDebug.state("_repaint NOT-IMPLEMENTED")
	

func _reload_transforms():
	if not Landscaper.running():
		return
	GLDebug.state("_reload_transforms NOT-IMPLEMENTED")

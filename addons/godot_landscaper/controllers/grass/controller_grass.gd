## CONTROLLER GRASS: 
##

@tool
@icon("uid://ckbdbf7cotire")
extends GLController
class_name GLControllerGrass


@export_category("Brushes")
## The source MultiMeshInstance3D tied to this controller.
## Lives under the anchor_node and has the same name as this controller
@export var mmi:MultiMeshInstance3D:
	get: return SceneManager.find_or_create_node(MultiMeshInstance3D, anchor_node, name)

## The parent for the generated MultiMeshInstance3D grass. Grass will be anchored to this node's position
## Consider using multiple GLController instances for non-static objects. Like a golem that will move at some point
@export var anchor_node:Node3D
var stroke_data:GLBuildDataGrass


@export_category("Controls")
@export_tool_button("Rebuild", "InstanceOptions") var _rebuild:Callable = build_all


func _ready():
	super()
	builder = GLBuilderGrass.new()
	brush_tabs = [
		InspectorTab.new(
			"Spawn",
			"Left click to spawn, right click to erase",
			["spawn_ratio", "erase_ratio"],
			AtlasIcon.Icon.GRASS_SCATTER,
			GLBrushGrassSpawn.new(),
		),
		InspectorTab.new(
			"Paint",
			"left cick to paint with primary color, right click for secondary",
			["primary_color", "secondary_color", "splash_height"],
			AtlasIcon.Icon.COLOR,
			GLBrushGrassPaint.new(),
		),
	]
	current_brush_tab = brush_tabs[0]
	fix_references()


## Called from InspectorManager on tab click
func select_brush(brush:GLBrush):
	current_brush = brush
	GLDebug.internal("Selected: %s/%s" %[name, brush.resource_name])


## Start landscaping according to the current brush
func stroke_start(hit_info:Dictionary):
	if fix_references(hit_info):
		stroke_data = GLBuildDataGrass.new()
		current_brush.start(hit_info, stroke_data, self)
	else:
		stroke_data = null


func stroke_primary(hit_info:Dictionary):
	if stroke_data:
		current_brush.primary(hit_info, stroke_data, self)
		builder.build(stroke_data, self)


func stroke_secondary(hit_info:Dictionary):
	if stroke_data:
		current_brush.secondary(hit_info, stroke_data, self)
		builder.build(stroke_data, self)


func stroke_end():
	if stroke_data:
		current_brush.end()
		build_all(stroke_data)


func build_all(stroke_data:GLBuildDataGrass):
	if not resources.source:
		resources.source = GLBuildDataGrass.new()
	
	if not resources.processed:
		resources.processed = GLBuildDataGrass.new()
	
	resources.source.append(stroke_data)
	for effect in effects:
		if effect:
			await effect.apply_safe(stroke_data, self)
	
	resources.processed.append(stroke_data)
	builder.build(resources.processed, self)


func fix_references(hit_info:Dictionary={}) -> bool:
	if not current_brush:
		GLDebug.error("There's no brush resource in selected tab of controller %s. Make sure InspectorTab.brush != null " %name)
		return false
	
	if not settings or not settings is GLSettingsGrass:
		settings = GLSettingsGrass.new()
	
	if not resources or not resources is GLResourcesGrass:
		resources = GLResourcesGrass.new()
	if not resources.fix_references(settings):
		GLDebug.error("Coundn't fix GLResourcesGrass references of controller %s" %name)
		return false
	
	if not effects:
		effects = []
	
	if not anchor_node and "collider" in hit_info:
		anchor_node = GLScanner.scan_mesh( hit_info.collider, settings)
		if anchor_node:
			GLDebug.warning("Auto selected anchor node %s. If this is not your intention please select the node in settings/anchor_node_path")
		else:
			GLDebug.error("There's no anchor node. Add one under 'Brushes' category")
			return false

	return true

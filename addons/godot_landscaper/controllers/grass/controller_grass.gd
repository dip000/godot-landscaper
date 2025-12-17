## CONTROLLER GRASS: 
##

@tool
@icon("uid://ckbdbf7cotire")
extends GLController
class_name GLControllerGrass


@export_category("Brushes")
## How many grass instances coincides to hit over the surface per editor frame
@export_range(1.0, 10.0, 1.0, "or_greater") var spawn_ratio:float = 1.0

## How many grass instances attempt to erase per editor frame
@export_range(0.1, 1.0, 0.1) var erase_ratio:float = 1.0

## Grass color with left button mouse
@export var primary_color:Color = Color.PALE_GOLDENROD

## Grass color with right button mouse
@export var secondary_color:Color = Color.PALE_VIOLET_RED

## The transition between the bottom terrain color and the top hand-painted color.
@export_range(-1.0, 1.0, 0.01) var splash_height:float = 0.0:
	set(v):
		splash_height = v
		resources.set_shader("splash_height", v)

## Uses the secondary color to manually paint the bottom of the grass instead of the top.
## Note that the scanning mechanics will auto detect the bottom colors.
@export var paint_bottom_with_sencondary_color:bool = false

## The source MultiMeshInstance3D tied to this controller.
## It will be auto-generated and placed under the brusshing surface if not provided.
@export var multimesh_instance:MultiMeshInstance3D


@export_category("Controls")
@export_tool_button("     Rebuild All     ", "InstanceOptions") var _build_all_btn:Callable = build_all
@export_tool_button("    Clear Effects    ", "Clear") var _clear_effects_btn:Callable = clear_effects
@export_tool_button("    Apply Effects    ", "BoneMapperHandleSelected") var _apply_effects_btn:Callable = apply_effects


func _ready():
	builder = GLBuilderGrass.new()
	brush_tabs = [
		InspectorTab.new(
			"Spawn",
			"Left click to spawn, right click to erase",
			["primary_color", "secondary_color", "splash_height", "paint_bottom_with_sencondary_color"],
			AtlasIcon.Icon.GRASS_SCATTER,
			GLBrushGrassSpawn.new(),
		),
		InspectorTab.new(
			"Paint",
			"left cick to paint with primary color, right click for secondary",
			["spawn_ratio", "erase_ratio", "multimesh_instance"],
			AtlasIcon.Icon.COLOR,
			GLBrushGrassPaint.new(),
		),
	]
	await super()
	fix_references()


## Called from InspectorManager on tab click
func select_brush(brush:GLBrush):
	current_brush = brush
	GLDebug.internal("Selected: %s/%s" %[name, brush.resource_name])


## Start landscaping according to the current brush
func stroke_start(hit_info:Dictionary):
	if fix_references(hit_info):
		current_brush.start( hit_info, self )


func stroke_primary(hit_info:Dictionary):
	current_brush.primary( hit_info, self )
	builder.build( multimesh_instance.multimesh, resources.source )


func stroke_secondary(hit_info:Dictionary):
	current_brush.secondary( hit_info, self )
	builder.build( multimesh_instance.multimesh, resources.source )


func stroke_end():
	current_brush.end()


func build_all():
	apply_effects()
	builder.build( multimesh_instance.multimesh, resources.processed )

func apply_effects():
	for effect in effects:
		effect.apply_safe(self)

func clear_effects():
	builder.build( multimesh_instance.multimesh, resources.source )


func fix_references(hit_info:Dictionary={}) -> bool:
	if not current_brush:
		GLDebug.error("There's no brush resource in selected tab of controller %s. Make sure InspectorTab.brush != null " %name)
		return false
	
	if not settings or not settings is GLSettingsGrass:
		settings = GLSettingsGrass.new()
	
	if not resources or not resources is GLResourcesGrass:
		resources = GLResourcesGrass.new()
	if not resources.fix_references( settings ):
		GLDebug.error("Coundn't fix GLResourcesGrass references of controller %s" %name)
		return false
	
	if not effects:
		effects = []
	
	if not multimesh_instance and "collider" in hit_info:
		var brush_surface:Node3D = GLScanner.scan_mesh( hit_info.collider, settings)
		var parent:Node3D = brush_surface if brush_surface else self
		multimesh_instance = SceneManager.find_or_create_node(MultiMeshInstance3D, parent, name)
		GLDebug.warning("Auto selected MultiMeshInstance '%s'. If this is not your intention please select the node manually" %multimesh_instance.name)
	
	if multimesh_instance:
		if not multimesh_instance.multimesh:
			multimesh_instance.multimesh = MultiMesh.new()
			multimesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh_instance.multimesh.use_colors = true
			multimesh_instance.multimesh.use_custom_data = true
		multimesh_instance.multimesh.mesh = resources.mesh
		multimesh_instance.set_instance_shader_parameter("variant_index", settings.instance_index)
	
	if not resources.source:
		resources.source = GLBuildDataGrass.new()
	
	return true

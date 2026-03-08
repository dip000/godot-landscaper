@tool
@icon("uid://bv48muu3c1tif")
extends GLController
class_name GLControllerTerrain

## Merges overhang edges with the closest cells.
## Disable if you want overhangs.
@export var sew_seams_on_build:bool = true


 ## Controls how much the terrain is raised or lowered per stroke.[br]
 ## Higher values produce steeper hills and deeper depressions.[br]
 ## Lower values allow for subtle shaping and fine adjustments.
@export_range(0.001, 1.0, 0.001, "or_greater", "exp") var strenght:float = 0.05

## Controls how the brush strength fades from the center toward the edges.[br]
## - Lower values create a softer, wider influence.[br]
## - Higher values concentrate the effect near the center for sharper shapes.[br]
## Refer to [url=https://raw.githubusercontent.com/godotengine/godot-docs/master/img/ease_cheatsheet.png] ease_cheatsheet [/url]
@export_range(-5.0, +5.0, 0.01, "or_greater", "or_less") var ease_curve:float = -2.0


## Flattens the affected terrain towards the minimum height if using the primary key.[br]
## Flattens to the max height if using secondary.
@export var level:bool = false

## The terrain target reference
@export var terrain:MeshInstance3D

## Paint blend value.
## Does not affect the color's alpha result.
@export_range(0, 100, 1, "suffix:%") var paint_strenght:float = 50

## Individual texture paint layers. Use the Paint Layers [GLUILayers] panel for convenience.
@export var layers:Array[GLPaintLayer]


@export_group("Primary Action", "primary_")
## Building behavior for the builder brush primary action
@export var primary_build_behavior:GLBrushTerrainBuider.Behavior = GLBrushTerrainBuider.Behavior.BUILD

## Terrain color with left button mouse.
## Use transparency to reveal the bottom layers.
@export var primary_color:Color = GLandscaper.DEEP_OCEAN

## Height behavior for the height brush primary action
@export var primary_height_behavior:GLBrushTerrainHeight.Behavior = GLBrushTerrainHeight.Behavior.RAISE

## The texturing behavior of the [member primary_paint_stencil]
@export var primary_paint_behavior:GLBrushTerrainPaint.Behavior = GLBrushTerrainPaint.Behavior.TEXTURE_TILING

## The splat texture to brush with. Use alpha gradients for a smooth falloff.[br]
## Create a custom stencil with [member stencil_maker]
@export var primary_paint_stencil:Texture2D


@export_group("Secondary Action", "secondary_")
## Building behavior for the builder brush secondary action
@export var secondary_build_behavior:GLBrushTerrainBuider.Behavior = GLBrushTerrainBuider.Behavior.ERASE

## Terrain color with right button mouse.
## Use transparency to reveal the bottom layers.
@export var secondary_color:Color = Color(GLandscaper.DEEP_OCEAN, 0)

## Height behavior for the height brush secondary action
@export var secondary_height_behavior:GLBrushTerrainHeight.Behavior = GLBrushTerrainHeight.Behavior.LOWER

## The texturing behavior of the [member secondary_paint_stencil]
@export var secondary_paint_behavior:GLBrushTerrainPaint.Behavior = GLBrushTerrainPaint.Behavior.SPLAT_PAINTING

## The splat texture to brush with. Use alpha gradients for a smooth falloff.[br]
## Create a custom stencil with [member stencil_maker]
@export var secondary_paint_stencil:Texture2D


@export_group("Tools")
## A convenient tool to make your own stencils.[br]
## Tip: Link the output with [member primary_paint_stencil] or [member secondary_paint_stencil]
## so you can edit the stencil live.
@export var stencil_maker:GLStencilMaker = GLStencilMaker.new()


func _setup_controller() -> void:
	validator = GLValidatorTerrain.new( self )
	builder = GLBuilderTerrain.new( self )
	brushes = GLAssetsManager.load_controller_brushes( "terrain" )
	use_grid = true




	

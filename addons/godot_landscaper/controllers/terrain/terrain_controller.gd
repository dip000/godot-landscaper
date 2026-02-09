@tool
@icon("uid://bv48muu3c1tif")
extends GLController
class_name GLControllerTerrain


## How many cells to build per meter squared.[br]
## You can always optimize by applying effects at the end.
@export_range(1.0, 10.0, 0.01, "or_greater", "or_less", "suffix:cells/meter") var cell_size:float = 1

## Joins hard-edges with the closest cells
@export var sew_seams_on_build:bool = true


 ## Controls how much the terrain is raised or lowered per stroke.
 ## Higher values produce steeper hills and deeper depressions.[br]
 ## Lower values allow for subtle shaping and fine adjustments.
@export_range(0.001, 1.0, 0.001, "or_greater", "exp") var strenght:float = 0.05

## Controls how the brush strength fades from the center toward the edges.[br]
## Lower values create a softer, wider influence.[br]
## Higher values concentrate the effect near the center for sharper shapes.
@export_range(-0.1, 3.0, 0.01, "or_greater", "or_less") var ease_curve:float = 0.5


## Flattens the affected terrain towards the minimum height if using the primary key.[br]
## Flattens to the max height if using secondary.
@export var level:bool = false


## Terrain color with left button mouse.[br]
## Use transparency for smooth blending.
@export var primary_color:Color = Color(GLandscaper.DEEP_OCEAN, 0.5)

## Terrain color with right button mouse.[br]
## Use transparency for smooth blending.
@export var secondary_color:Color = Color(GLandscaper.VERDIGIRS, 0.5)


## The terrain target reference
@export var terrain:MeshInstance3D


@export_group("Other")
## The splat texture to brush with.[br]
## Use alpha gradients for a smooth falloff
@export var brush_shape:Texture2D


func _setup_controller() -> void:
	validator = GLValidatorTerrain.new( self )
	builder = GLBuilderTerrain.new( self )
	brushes = GLAssetsManager.load_controller_brushes( "terrain" )
	use_grid = true
	
	
	

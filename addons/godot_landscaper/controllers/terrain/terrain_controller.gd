@tool
@icon("uid://bv48muu3c1tif")
extends GLController
class_name GLControllerTerrain


@export_category("Brushes")

## Height to build the terrain. You can heighten and lower with the Height Brush
@export var base_height:float = 0

## How many cells to build per meter squared.
## You can always optimize by applying effects at the end.
@export_range(1.0, 10.0, 0.01, "or_greater", "or_less", "suffix:cells/meter") var cell_size:float = 1

## How quickly you want to raise or lower the ground when you paint over the terrain
@export_range(0.01, 10.0, 0.01) var strenght:float = 1.0

## Terrain color with left button mouse.
## Use transparency for smooth blending.
@export var primary_color:Color = Color.PALE_GOLDENROD

## Terrain color with right button mouse
## Use transparency for smooth blending.
@export var secondary_color:Color = Color(Color.PALE_VIOLET_RED, 0.5)

## The terrain target reference
@export var terrain:MeshInstance3D


@export_group("Resources") 
@export var material:ShaderMaterial
@export var shader:Shader


func _setup_controller() -> void:
	validator = GLValidatorTerrain.new( self )
	builder = GLBuilderTerrain.new( self )
	brushes = AssetsManager.load_controller_brushes( "terrain" )
	use_grid = true

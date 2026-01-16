@tool
@icon("uid://bv48muu3c1tif")
extends GLController
class_name GLControllerTerrain


@export_category("Brushes")
## Terrain color with left button mouse.
## Use transparency for smooth blending.
@export var primary_color:Color = Color.PALE_GOLDENROD

## Terrain color with right button mouse
## Use transparency for smooth blending.
@export var secondary_color:Color = Color(Color.PALE_VIOLET_RED, 0.5)


func _setup_controller() -> void:
	validator = GLValidatorTerrain.new( self )
	builder = GLBuilderTerrain.new( self )
	brushes = AssetsManager.load_controller_brushes( "terrain" )

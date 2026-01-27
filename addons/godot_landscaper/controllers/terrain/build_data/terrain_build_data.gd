extends GLBuildData
class_name GLBuildDataTerrain

@export_group("Resources")
## You can use your own shader as long as you have a "uniform sampler2D albedo_texture" as the terrain texture
@export var shader:Shader

## It will be converted to ImageTexture while in use.
## Use the Terrain Formater effect for better format alternatives.
@export var texture:Texture2D


@export_group("Raw Data")
## Ordered map that stores the vertex raw data by given XZ coordinate
@export var vertices_map:Dictionary[Vector2i, PackedVector3Array]

## Ordered map that stores the UV raw data by given XZ coordinate.
## Usefull for custom UV mapping.
@export var uvs_map:Dictionary[Vector2i, PackedVector2Array]

var min:Vector3 = Vector3.INF
var max:Vector3 = -Vector3.INF

extends GLBuildData
class_name GLBuildDataTerrain

@export_group("Resources")
## You can use your own shader as long as you have a "uniform sampler2D albedo_texture" as the terrain texture
@export var shader:Shader

## It will be converted to ImageTexture while in use.
## Use the Terrain Formater effect for better format alternatives.
@export var texture:Texture2D


@export_group("Raw Data")
## Ordered map that stores the vertex raw data by given XZ coordinate.
@export var vertices_map:Dictionary[Vector2i, PackedVector3Array]

## Ordered map that stores the UV raw data by given XZ coordinate.
## Use for custom UV mapping.
## Leave empty for renormalizing UVs to scale to the terrain bounds
@export var uvs_map:Dictionary[Vector2i, PackedVector2Array]

# Used for chunkifiers
# [TODO] use AABB instead
var min:Vector3 = Vector3.INF
var max:Vector3 = -Vector3.INF

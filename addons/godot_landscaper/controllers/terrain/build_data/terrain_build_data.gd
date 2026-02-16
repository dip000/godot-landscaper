extends GLBuildData
class_name GLBuildDataTerrain

@export_group("Resources")
## You can use your own shader as long as you have a "uniform sampler2D terrain_texture" as the terrain texture
@export var shader:Shader

## Shader material to use
@export var material:ShaderMaterial

## Layer data.
## It will be converted to ImageTexture while in use.
@export var layers:Array[GLPaintLayer]


@export_group("Raw Data")
## Ordered map that stores the vertex raw data by given XZ coordinate.
@export var vertices_map:Dictionary[Vector2i, PackedVector3Array]

## Ordered map that stores the UV raw data by given XZ coordinate.[br]
## - Use for custom UV mapping.[br]
## - Leave empty for renormalizing UVs to scale to the terrain bounds
@export var uvs_map:Dictionary[Vector2i, PackedVector2Array]

## Ordered map that stores the Vertex Color raw data by given XZ coordinate.[br]
## - Use for custom Vertex Color mapping.[br]
## - Leave empty for using the texture.
@export var vertex_colors_map:Dictionary[Vector2i, PackedColorArray]


# Used for chunkifiers
# [TODO] use AABB instead
var min:Vector3 = Vector3.INF
var max:Vector3 = -Vector3.INF

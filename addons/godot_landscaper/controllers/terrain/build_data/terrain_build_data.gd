extends GLBuildData
class_name GLBuildDataTerrain

## Ordered map that stores the vertex raw data by given XZ coordinate
@export var vertices_map:Dictionary[Vector2i, PackedVector3Array]

## Ordered map that stores the UV raw data by given XZ coordinate.
## Usefull for custom UV mapping.
@export var uvs_map:Dictionary[Vector2i, PackedVector2Array]

var min:Vector3 = Vector3.INF
var max:Vector3 = -Vector3.INF

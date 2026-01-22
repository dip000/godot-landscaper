extends GLBuildData
class_name GLBuildDataTerrain

## The terrain texture expands and shrinks dynamically.
## Use Effects to chunkify and change resolution at the end.
@export var image:Image

## Ordered map that stores the vertex raw data by given XZ coordinate
@export var vertices_map:Dictionary[Vector2i, PackedVector3Array]

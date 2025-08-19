## Saved data for QuadGrassTool Tool.
@tool
@icon("res://addons/godot_landscaper/save_icon.svg")
extends SaveData
class_name QuadGrassSave

# Resources
# Pleaes save resources externally.
@export var grass_configs:Array[QuadGrassConfigs]
@export var mesh:QuadMesh

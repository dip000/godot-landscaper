## Individual Landscaper nodes' save data
## 1. Modular, avoids single-point failure
## 2. Simpler for the developer to manage
## 3. Follows Godot's best practices for project file management
extends Resource
class_name SaveData

# Common resources for every tool
@export var material:ShaderMaterial
@export var shader:Shader

## BRUSH: Interface members for all brush types
##  * A brush is the data mutation behavior while stroking over the scene.
##  * Every GLController has at least one Brush. Example: GLControllerGrass > GLBrushGrassPaint, GLBrushGrassSpawn

@tool
@abstract
extends Resource
class_name GLBrush

## Inspector UI Tab title
@export var title:String = ""
## Inspector UI Tab icon
@export var icon:Texture2D
## Inspector UI Infobox info
@export_multiline var info:String = ""
## Inspector UI properties to hide if tab is selected
@export var hide_properties:PackedStringArray = []


## Called once per stroke; validate, start subrocesses, etc..[br]
## 'scan_data'    Result of physics collision, brought to you by the main GLandscaper class[br]
## 'controller'  Scene node that host all references like GLBuildData
@abstract
func start(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController) -> void


## Called every ui frame after start().[br]
## 'scan_data'    Result of physics collision, brought to you by the main GLandscaper class.[br]
## 'controller'  Scene node that host all references like GLBuildData
@abstract
func action(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController) -> void


## Called once at the end of the stroke. End subprocesses, resets, etc..
@abstract
func end(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController) -> void





	

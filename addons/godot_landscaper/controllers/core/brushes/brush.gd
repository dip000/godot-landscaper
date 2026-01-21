## BRUSH: Interface members for all brush types
##  * A brush is the data mutation behavior while stroking over the scene.
##  * Every ElementController has at least one Brush. Example: GrassController > GrassPaintBrush, GrassSpawnBrush

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


## Called once per stroke; validate, start subrocesses, etc..
## 'scan_data'    Result of physics collision, brought to you by the main Landscaper class
## 'controller'  Scene node that host all references like GLSettings, GLSaveData, GLEffect, etc..
@abstract
func start(scan_data:GLScanData, controller:GLController) -> void

## Called every ui frame after start()
## 'scan_data'    Result of physics collision, brought to you by the main Landscaper class
## 'controller'  Scene node that host all references like GLSettings, GLSaveData, GLEffect, etc..
@abstract
func primary(scan_data:GLScanData, controller:GLController) -> void

## Called every ui frame after start()
## 'scan_data'    Result of physics collision, brought to you by the main Landscaper class
## 'controller'  Scene node that host all references like GLSettings, GLSaveData, GLEffect, etc..
@abstract
func secondary(scan_data:GLScanData, controller:GLController) -> void

## Called once at the end of the stroke. End subprocesses, resets, etc..
@abstract
func end() -> void

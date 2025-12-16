## BRUSH: Interface members for all brush types
##  * A brush is the data mutation behavior while stroking over the scene.
##  * Every ElementController has at least one Brush. Example: GrassController > GrassPaintBrush, GrassSpawnBrush

@tool
@abstract
extends Resource
class_name GLBrush

## Called once per stroke; validate, start subrocesses, etc..
## 'hit_info'    Result of physics collision, brought to you by the main Landscaper class
## 'stroke_data' Data packet to work with. Send it empty (not null) or with extra data if needed
## 'controller'  Scene node that host all references like GLSettings, GLSaveData, GLEffect, etc..
@abstract
func start(hit_info:Dictionary, stroke_data:GLBuildData, controller:GLController) -> void

## Called every ui frame after start()
## 'hit_info'    Result of physics collision, brought to you by the main Landscaper class
## 'stroke_data' Data packet to work with. Send it empty (not null) or with extra data if needed
## 'controller'  Scene node that host all references like GLSettings, GLSaveData, GLEffect, etc..
@abstract
func primary(hit_info:Dictionary, stroke_data:GLBuildData, controller:GLController) -> void

## Called every ui frame after start()
## 'hit_info'    Result of physics collision, brought to you by the main Landscaper class
## 'stroke_data' Data packet to work with. Send it empty (not null) or with extra data if needed
## 'controller'  Scene node that host all references like GLSettings, GLSaveData, GLEffect, etc..
@abstract
func secondary(hit_info:Dictionary, stroke_data:GLBuildData, controller:GLController) -> void

## Called once at the end of the stroke. End subprocesses, resets, etc..
@abstract
func end() -> void

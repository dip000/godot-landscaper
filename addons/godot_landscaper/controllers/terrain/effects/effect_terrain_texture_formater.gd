## ImageTexture To CompressedTexture2D with formating options.
## 
## By default, the landscaper will use a ImageTexture to process images,
## but only Godot's native importer has the ability to compress textures.

@tool
extends GLEffect
class_name GLTerrainTextureFormater

## Set the dictionary keys as the channel names used.
## Format each channel texture using the [GLImageFormater] class
@export var channel_formaters:Dictionary[String, GLImageFormater] = {
	"terrain_texture": GLImageFormater.from_save_path("res://terrain_texture.png")
}


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Texture Formater Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	if channel_formaters.is_empty():
		GLDebug.error("Terrain Texture Formater Failed: 'channel_formaters' is empty")
		return false
	
	controller = controller as GLControllerTerrain
	var processed:GLBuildDataTerrain = controller.processed
	var not_found_channels:Dictionary[String, GLImageFormater] = channel_formaters.duplicate()
	var unformated_channels:PackedStringArray
	var found_layers:Array[GLPaintLayer]
	
	for layer in processed.layers:
		var channel:String = layer.sampler
		var formater:GLImageFormater = channel_formaters.get( channel )
		
		if not formater:
			unformated_channels.append( channel )
			continue
		
		if not formater.format_and_save( layer.get_image() ):
			GLDebug.error("Terrain Texture Formater Failed")
			return false
		
		not_found_channels.erase( channel )
		found_layers.append( layer )
	
	# Warnings
	if unformated_channels:
		GLDebug.warning("Terrain Texture Formater: Channels '%s' are not being formated. Add these formaters in 'Channel Formaters' dictionary or remove the layers from the terrain controller" %unformated_channels)
	if not_found_channels:
		GLDebug.warning("Terrain Texture Formater: Channels '%s' do not exist in the controller. Remove them from 'Channel Formaters' dictionary or add the layers to the terrain controller" %not_found_channels.keys())
	
	# Await for the importer
	await _frame()
	EditorInterface.get_resource_filesystem().scan_sources()
	await _timeout( 0.5 )
	
	# Reload and set resources
	var material:ShaderMaterial = controller.terrain.material_override
	var channels_saved:PackedStringArray
	
	for found_layer in found_layers:
		var channel:String = found_layer.sampler
		var formater:GLImageFormater = channel_formaters[channel]
		var texture:Texture2D = load( formater.save_file )
		material.set_shader_parameter( found_layer.sampler, texture )
		channels_saved.append( channel )
	
	GLDebug.state("Terrain Texture Formater Succesfull: Channels Saved %s" %channels_saved)
	return true
	

func _clear(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Texture Formater Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	controller = controller as GLControllerTerrain
	var source:GLBuildDataTerrain = controller.source
	
	return true
	











	

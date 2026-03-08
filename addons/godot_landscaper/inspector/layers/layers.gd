## UI Layers Panel for [GLPaintLayer] resources
##

@tool
extends MarginContainer
class_name GLUILayers

@onready var _holder:VBoxContainer = %Holder
@onready var _add_layer:Button = %AddLayer
@onready var _preview:TextureRect = %Preview
@onready var _size:Label = %Size

var _buttons:ButtonGroup = ButtonGroup.new()
var _layers:Array[GLPaintLayer]


func _ready() -> void:
	_add_layer.pressed.connect( on_add_layer_connected )


## Add new and redraw all
func on_add_layer_connected():
	clear()
	_layers.append( GLPaintLayer.new() )
	reload_layers()


## Removes all children UI layers. Does not delete their [GLPaintLayer]
func clear():
	for ui_layer in _holder.get_children():
		ui_layer.queue_free()


## Updates and shows the current layers
func load_layers(layers:Array[GLPaintLayer]):
	_layers = layers
	reload_layers()


## Shows current layers without updating
func reload_layers():
	var current_index:int = 0
	var variations:Dictionary[String, float]
	
	# Get current index
	for i in _holder.get_child_count():
		var ui_layer:GLUILayer = _holder.get_child( i )
		if ui_layer.active.is_pressed():
			current_index = i
	
	if current_index >= _layers.size():
		current_index = 0
	
	# Setup UI layer
	for i in _layers.size():
		var layer:GLPaintLayer = _layers[i]
		if not layer:
			continue
		
		var ui_layer:GLUILayer = GLAssetsManager.UI_LAYER.instantiate()
		_holder.add_child( ui_layer )
		ui_layer.fill( layer )
		ui_layer.active.button_group = _buttons
		ui_layer.active.button_pressed = (i == current_index)
		ui_layer.active.pressed.connect( update_texture.bind(layer) )
		ui_layer.delete.pressed.connect( _on_delete_pressed.bind(layer) )
		
		# Color samplers with the same name with the same color
		var variation:float = variations.get( layer.sampler, randf_range(-0.5, 0.5) )
		ui_layer.set_color_variation( variation )
		variations[layer.sampler] = variation
	
	if _layers:
		update_texture( _layers[current_index] )


func update_texture(layer:GLPaintLayer):
	_preview.texture = layer.texture
	if layer.texture:
		_size.text = "%s x %s px" %[_preview.texture.get_width(), _preview.texture.get_height()]


func _on_delete_pressed(layer:GLPaintLayer):
	_layers.erase( layer )
	clear()
	reload_layers()







	



	

@tool
extends MarginContainer
class_name GLUILayers

@onready var holder:VBoxContainer = %Holder
@onready var add_layer:Button = %AddLayer
@onready var floating_holder:CanvasLayer = %FloatingHolder
@onready var content:VBoxContainer = %Content
@onready var preview:TextureRect = %Preview

var _buttons:ButtonGroup = ButtonGroup.new()
var _layers:Array[GLPaintLayer]


func _ready() -> void:
	add_layer.pressed.connect( on_add_layer_connected )


func on_add_layer_connected():
	clear()
	_layers.append( GLPaintLayer.new() )
	refill()


func clear():
	for ui_layer in holder.get_children():
		ui_layer.queue_free()


func fill(layers:Array[GLPaintLayer]):
	_layers = layers
	refill()


func refill():
	var current_index:int = 0
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	var variations:Dictionary[String, float]
	var total:int = _layers.size()
	
	for i in holder.get_child_count():
		var ui_layer:GLUILayer = holder.get_child( i )
		if ui_layer.active.button_pressed:
			current_index = i
	
	for i in total:
		var layer:GLPaintLayer = _layers[i]
		var ui_layer:GLUILayer = GLAssetsManager.UI_LAYER.instantiate()
		holder.add_child( ui_layer )
		ui_layer.fill( layer )
		ui_layer.active.button_group = _buttons
		ui_layer.active.button_pressed = (i == current_index)
		ui_layer.active.toggled.connect( _on_active_toggled.bind(layer) )
		ui_layer.channel.text_changed.connect( on_text_changed.bind(i) )
		
		var variation:float = variations.get( layer.material_channel, randf_range(-0.5, 0.5) )
		ui_layer.set_color_variation( variation )
		variations[layer.material_channel] = variation
	
	if current_index < _layers.size():
		preview.texture = _layers[current_index].texture


func _on_active_toggled(toggled_on:bool, layer:GLPaintLayer):
	preview.texture = layer.texture


func on_text_changed(new_text:String, index:int):
	if not new_text:
		_layers.remove_at( index )
		clear()
		refill()








	



	

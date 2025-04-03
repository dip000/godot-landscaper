extends Resource
class_name Utils

# Corresponds to the line in-code of such directive
enum Directives {BILLBOARD_Y, GL_COMPATIBILITY}


static func fix_shader_compatibility(shader:Shader, variants:Array) -> bool:
	var total_variants:int = variants.filter(func(v): return v).size()
	var needs_vulkan:bool = (total_variants > 1)
	var has_vulkan:bool = true if RenderingServer.get_rendering_device() else false
	
	if needs_vulkan and has_vulkan:
		set_shader_directive( shader, Directives.GL_COMPATIBILITY , false )
	elif needs_vulkan and not has_vulkan:
		set_shader_directive( shader, Directives.GL_COMPATIBILITY , true )
		return false
	else:
		set_shader_directive( shader, Directives.GL_COMPATIBILITY , true )
	return true

static func set_shader_directive(shader:Shader, directive:Directives, active:bool):
	var directive_name:String = Directives.keys()[directive]
	var not_directive:String = "//" + directive_name
	
	if active:
		shader.set_code( shader.code.replace(not_directive, directive_name) )
	elif not shader.code.contains( not_directive ):
		shader.set_code( shader.code.replace(directive_name, not_directive) )


static func format_texture(texture:Texture2D, resize:=Vector2i.ZERO) -> ImageTexture:
	var img:Image = texture.get_image()
	if img.is_compressed():
		img.decompress()
	if img.has_mipmaps():
		img.clear_mipmaps()
	if resize != Vector2i.ZERO:
		img.resize( resize.x, resize.y )
	return ImageTexture.create_from_image( img )

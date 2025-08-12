@tool
extends AtlasTexture
class_name AtlasIcon

const WIDTH:int = 64
const HEIGHT:int = 64


enum Icon {
	GRASS_SCATTER, BILLBOARD_CROSS, BILLBOARD_Y,
	DOWNLOAD, UPLOAD, SETTINGS, OPEN_FILE,
	UNDO, REDO, DROPBOX,
	COLOR,
	EDIT, ADD,
}

@export var icon:Icon:
	set(value):
		icon = value
		atlas = AssetsManager.ICONS
		region.position.x = WIDTH * icon
		region.size = Vector2i(WIDTH, HEIGHT)

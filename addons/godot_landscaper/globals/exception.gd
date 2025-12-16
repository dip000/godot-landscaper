extends RefCounted
class_name GLResult

var code:Error
var msg:String
var is_ok:bool:
	get: return code == OK


static func error(msg:String, code:int):
	GLDebug.error("%s: %s" %[code, msg])
	return GLResult.new(msg, code)

static func warning(msg:String):
	GLDebug.warning("%s: %s" %[OK, msg])
	return GLResult.new(msg, OK)

static func ok(msg:String=""):
	return GLResult.new(msg, OK)


func _init(msg:String, code:int):
	self.msg = msg
	self.code = code


func _to_string():
	return msg

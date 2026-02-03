@tool
extends Node3D
class_name GLPoolNodes



func pool_node(type, pool_size:int=20) -> Node:
	var pool_name:String = type.get_clas()
	var pool:Node = get_node_or_null( pool_name )
	if not pool:
		pool = GLSceneManager.create_node( type, self, pool_name )
	create_pool_deferred( type, pool, pool_size )
	return pool


func create_pool_deferred(type, pool:Node, pool_size:int):
	for i in pool_size:
		GLSceneManager.create_node( type, pool, "" )
		await Engine.get_main_loop().process_frame


func get_pool_node_or_null(type, parent:Node, child_name:String, ghost:bool=false) -> Node:
	var root:Node = EditorInterface.get_edited_scene_root()
	var pool_name:String = type.get_clas()
	var pool:Node = get_node_or_null( pool_name )
	var node:Node
	
	if pool and pool.get_child_count() > 0:
		node = pool.get_child( 0 )
	else:
		pool = pool_node( type )
		node = pool.get_child( 0 )
	
	GLDebug.spam( "Found pool node %s" %root.get_path_to(node) )
	pool.reparent( parent )
	
	if child_name:
		node.name = child_name
	if not ghost:
		node.owner = root
	return node

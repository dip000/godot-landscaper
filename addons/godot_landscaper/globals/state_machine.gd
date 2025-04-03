extends Resource
class_name StateMachine
## General purpose State Machine
## Has fallback states, queue, priority, clear, and next

signal on_stack_added(state:Object)

var _stack:Array[Object]
var _fallback:Object

var current:Object:
	get: return _stack.front()
var is_active:bool:
	get: return not _stack.is_empty()
var is_inactive:bool:
	get: return _stack.is_empty()


func _init(initial_state:Object=null):
	if initial_state:
		_push_and_enter_head( initial_state )


## Starts this state if the last state of the stack finished
func set_fallback_state(state:Object) -> StateMachine:
	_fallback = state
	if is_inactive:
		_push_and_enter_head( state )
	return self


## Ends current state and starts next in stack
func next():
	if is_active:
		_exit_and_pop_head()
		if is_active:
			current._enter()
		elif _fallback:
			_push_and_enter_head( _fallback )
	elif _fallback:
		_push_and_enter_head( _fallback )


## Removes every state
func clear():
	if is_active:
		_exit_and_pop_head()
		_stack.clear()



## Changes the current state for a new one
func switch(state:Object):
	on_stack_added.emit( state )
	if is_active:
		_exit_and_pop_head()
	_push_and_enter_head( state )


## Appends a state at the end of the stack
func queue(state:Object):
	on_stack_added.emit( state )
	if is_active:
		_stack.push_back( state )
	else:
		_push_and_enter_head(state)


## Appends a state at the begining of the stack
func priority(state:Object):
	on_stack_added.emit( state )
	if is_active:
		current._exit()
	_push_and_enter_head(state)


## Head operations. Badum' tsss..
func _exit_and_pop_head():
	_stack.front()._exit()
	_stack.pop_front()

func _push_and_enter_head(state:Object):
	_stack.push_front( state )
	_stack.front()._enter()

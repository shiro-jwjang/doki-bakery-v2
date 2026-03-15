extends Control
class_name BaseUIComponent

## BaseUIComponent
##
## Base class for UI components that provides safe update mechanisms.
## Prevents UI updates when the component is not inside the scene tree.
## SNA-163: Unified is_inside_tree() check pattern for UI components.
## SNA-160: Unified signal connection pattern with duplicate prevention.


## Safely connect a signal to a callback, preventing duplicate connections.
##
## This helper ensures signals are only connected once, avoiding errors
## from multiple connections of the same signal to the same callback.
##
## @param sig: The signal to connect
## @param callback: The callable to invoke when the signal fires
func _connect_signal(sig: Signal, callback: Callable) -> void:
	if not sig.is_connected(callback):
		sig.connect(callback)


## Safely execute a callable only if this component is inside the scene tree.
##
## This prevents errors from attempting to update UI elements when the node
## has been removed from the scene tree or not yet added.
##
## @param callable: The function to execute if inside tree
func safe_update(callable: Callable) -> void:
	if is_inside_tree():
		callable.call()

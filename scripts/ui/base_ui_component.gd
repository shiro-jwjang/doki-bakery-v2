class_name BaseUIComponent
extends Control

## BaseUIComponent
##
## Base class for UI components that provides safe update mechanisms.
## Prevents UI updates when the component is not inside the scene tree.
## SNA-163: Unified is_inside_tree() check pattern for UI components.


## Safely execute a callable only if this component is inside the scene tree.
##
## This prevents errors from attempting to update UI elements when the node
## has been removed from the scene tree or not yet added.
##
## @param callable: The function to execute if inside tree
func safe_update(callable: Callable) -> void:
	if is_inside_tree():
		callable.call()

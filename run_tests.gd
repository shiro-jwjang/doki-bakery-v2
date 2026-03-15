extends SceneTree

## Test Runner Script
## Run GUT tests from command line: godot --headless --script run_tests.gd

func _init():
	# Load GUT
	var GutRunner = load("res://addons/gut/gui/GutRunner.tscn")
	var runner = GutRunner.instantiate()

	# Configure runner
	var GutConfig = load("res://addons/gut/gut_config.gd")
	var config = GutConfig.new()
	config.load_options("res://.gutconfig.json")

	runner.gut_config = config

	# Add runner to root
	root.add_child(runner)

	# Run tests
	runner.run_tests(false)  # false = no GUI in headless mode

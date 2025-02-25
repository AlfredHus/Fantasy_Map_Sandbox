extends GutTest

#const HeightmapTemplates := preload("res://classes/World/heightmap_templates.gd")
var height_map_templates: HeightMapTemplates

func  before_all():
	height_map_templates= HeightMapTemplates.new()
	
func test_get_height_map_steps() -> void:
	# TESTING: This is the value from the HeightmapTemplates we are going to test.
	# var volcano: String: """Hill 1 90-100 44-56 40-60
	#	Multiply 0.8 50-100 0 0
	#	Range 1.5 30-55 45-55 40-60
	#	Smooth 3 0 0 0
	#	Hill 1.5 35-45 25-30 20-75
	#	Hill 1 35-55 75-80 25-75
	#	Hill 0.5 20-25 10-15 20-25
	#	Mask 3 0 0 0"""
			
	# Each substring after the first sub-string is prefixed with "\t\t" which
	# we will have to remove. split() creates substrings which are stored
	# in a PackedStringArray. This will allow us to reference each individual
	# step using an index into steps.
	var steps_string = height_map_templates.heightmap_templates["volcano"]["template"]
	var steps:PackedStringArray = steps_string.replace("\t", "").split("\n")
	var step_string_1: String = "Hill 1 90-100 44-56 40-60"
	var step_string_1_expected = steps[0]
	assert_eq(step_string_1, step_string_1_expected, "Trying to extract first velue for Volcano: Hill 1 90-100 44-56 40-60")
	step_string_1 ="Mask 3 0 0 0"
	step_string_1_expected = steps[7]
	assert_eq(step_string_1, step_string_1_expected , "Trying to extract last velue for Volcano: Mask 3 0 0 0")
	
	 # TESTING: This is the value in the HeightmapTemplates we are going to test. 
	 # "volcano": {"id": 0, "name": "Volcano", "template": volcano, "probability": 3}
	assert_eq(height_map_templates.heightmap_templates["volcano"]["id"], 0, "Trying to get id: 0")
	assert_eq(height_map_templates.heightmap_templates["volcano"]["name"], "Volcano", "Trying to get name: volcano")
	assert_eq(height_map_templates.heightmap_templates["volcano"]["probability"], 3, "Trying to get probability: 3")

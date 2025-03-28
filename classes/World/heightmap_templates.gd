class_name HeightMapTemplates
# These are various templates used to generate the heightfield. It uses
# multiline string literals using the triple quotes.
#
## Code from Azgaar's Fantasy Map Generator
## Ported from https://github.com/Azgaar/Fantasy-Map-Generator
#
# https://github.com/Azgaar/Fantasy-Map-Generator/blob/5bb33311fba48ed83f797c77779dbb909d6e1958/config/heightmap-templates.js#L4
# 
# A dictionary is used to store the heightmap templates and the ascociated
# data.
# The fuction returns a dictionary of heightmap templates which is assigned
# to the heightmap_template variable.
# 
# The .call() executes the function and assigns the returned dictionary
# to the height5map_template.
# This is an anonymous function, also known as lambdas.
# https://docs.godotengine.org/en/4.3/classes/class_callable.html#class-callable-method-call
#
# The hill step of this form I believe is a Mountain: "Hill 1 90-100 44-56 40-60"

var heightmap_templates: Dictionary = (func():
	var volcano: String = """Hill 1 90-100 44-56 40-60
		Multiply 0.8 50-100 0 0
		Range 1.5 30-55 45-55 40-60
		Smooth 3 0 0 0
		Hill 1.5 35-45 25-30 20-75
		Hill 1 35-55 75-80 25-75
		Hill 0.5 20-25 10-15 20-25
		Mask 3 0 0 0"""
	# Test Hill
	#var volcano: String = """Hill 1 20 50-50 50-50"""
	# Test Pit
	#var volcano: String = """
	#Hill 1 40 50-50 50-50
	#Pit 1 20 50-50 50-50
	#"""
	# Test Range
	#var volcano: String = """Range 1 40-50 50-60 50-50"""	
	# Test Range
	#var volcano: String = """
	#Hill 2 20 50-50 50-50
	##Pit 1 20 50-50 50-50
	##Range 1 40-50 50-60 50-50
	#"""
	# Test Add and Straits
	#var volcano: String = """
		#Add 20 all 0 0
		#Hill 2 40-50 15-85 20-80
		#Strait 5 vertical 0 0
		#Smooth 2 0 0 0
		#"""
		
	#var volcano: String = """
		#Add 20 all 0 0
		#Strait 5 vertical 0 0
		#"""
	var high_island: String = """Hill 1 90-100 65-75 47-53
		Add 7 all 0 0
		Hill 5-6 20-30 25-55 45-55
		Range 1 40-50 45-55 45-55
		Multiply 0.8 land 0 0
		Mask 3 0 0 0
		Smooth 2 0 0 0
		Trough 2-3 20-30 20-30 20-30
		Trough 2-3 20-30 60-80 70-80
		Hill 1 10-15 60-60 50-50
		Hill 1.5 13-16 15-20 20-75
		Range 1.5 30-40 15-85 30-40
		Range 1.5 30-40 15-85 60-70
		Pit 3-5 10-30 15-85 20-80"""

	var low_island: String = """Hill 1 90-99 60-80 45-55
		Hill 1-2 20-30 10-30 10-90
		Smooth 2 0 0 0
		Hill 6-7 25-35 20-70 30-70
		Range 1 40-50 45-55 45-55
		Trough 2-3 20-30 15-85 20-30
		Trough 2-3 20-30 15-85 70-80
		Hill 1.5 10-15 5-15 20-80
		Hill 1 10-15 85-95 70-80
		Pit 5-7 15-25 15-85 20-80
		Multiply 0.4 20-100 0 0
		Mask 4 0 0 0"""

	var continents: String = """Hill 1 80-85 60-80 40-60
		Hill 1 80-85 20-30 40-60
		Hill 6-7 15-30 25-75 15-85
		Multiply 0.6 land 0 0
		Hill 8-10 5-10 15-85 20-80
		Range 1-2 30-60 5-15 25-75
		Range 1-2 30-60 80-95 25-75
		Range 0-3 30-60 80-90 20-80
		Strait 2 vertical 0 0
		Strait 1 vertical 0 0
		Smooth 3 0 0 0
		Trough 3-4 15-20 15-85 20-80
		Trough 3-4 5-10 45-55 45-55
		Pit 3-4 10-20 15-85 20-80
		Mask 4 0 0 0"""

	var archipelago: String = """Add 11 all 0 0
		Range 2-3 40-60 20-80 20-80
		Hill 5 15-20 10-90 30-70
		Hill 2 10-15 10-30 20-80
		Hill 2 10-15 60-90 20-80
		Smooth 3 0 0 0
		Trough 10 20-30 5-95 5-95
		Strait 2 vertical 0 0
		Strait 2 horizontal 0 0"""

	var atoll: String = """Hill 1 75-80 50-60 45-55
		Hill 1.5 30-50 25-75 30-70
		Hill .5 30-50 25-35 30-70
		Smooth 1 0 0 0
		Multiply 0.2 25-100 0 0
		Hill 0.5 10-20 50-55 48-52"""

	var mediterranean: String = """Range 4-6 30-80 0-100 0-10
		Range 4-6 30-80 0-100 90-100
		Hill 6-8 30-50 10-90 0-5
		Hill 6-8 30-50 10-90 95-100
		Multiply 0.9 land 0 0
		Mask -2 0 0 0
		Smooth 1 0 0 0
		Hill 2-3 30-70 0-5 20-80
		Hill 2-3 30-70 95-100 20-80
		Trough 3-6 40-50 0-100 0-10
		Trough 3-6 40-50 0-100 90-100"""

	var peninsula: String = """Range 2-3 20-35 40-50 0-15
		Add 5 all 0 0
		Hill 1 90-100 10-90 0-5
		Add 13 all 0 0
		Hill 3-4 3-5 5-95 80-100
		Hill 1-2 3-5 5-95 40-60
		Trough 5-6 10-25 5-95 5-95
		Smooth 3 0 0 0
		Invert 0.4 both 0 0"""

	var pangea: String = """Hill 1-2 25-40 15-50 0-10
		Hill 1-2 5-40 50-85 0-10
		Hill 1-2 25-40 50-85 90-100
		Hill 1-2 5-40 15-50 90-100
		Hill 8-12 20-40 20-80 48-52
		Smooth 2 0 0 0
		Multiply 0.7 land 0 0
		Trough 3-4 25-35 5-95 10-20
		Trough 3-4 25-35 5-95 80-90
		Range 5-6 30-40 10-90 35-65"""

	var isthmus: String = """Hill 5-10 15-30 0-30 0-20
		Hill 5-10 15-30 10-50 20-40
		Hill 5-10 15-30 30-70 40-60
		Hill 5-10 15-30 50-90 60-80
		Hill 5-10 15-30 70-100 80-100
		Smooth 2 0 0 0
		Trough 4-8 15-30 0-30 0-20
		Trough 4-8 15-30 10-50 20-40
		Trough 4-8 15-30 30-70 40-60
		Trough 4-8 15-30 50-90 60-80
		Trough 4-8 15-30 70-100 80-100
		Invert 0.25 x 0 0"""
		
	var shattered: String = """Hill 8 35-40 15-85 30-70
		Trough 10-20 40-50 5-95 5-95
		Range 5-7 30-40 10-90 20-80
		Pit 12-20 30-40 15-85 20-80"""

	var taklamakan: String = """Hill 1-3 20-30 30-70 30-70
		Hill 2-4 60-85 0-5 0-100
		Hill 2-4 60-85 95-100 0-100
		Hill 3-4 60-85 20-80 0-5
		Hill 3-4 60-85 20-80 95-100
		Smooth 3 0 0 0"""

	var old_world: String = """Range 3 70 15-85 20-80
		Hill 2-3 50-70 15-45 20-80
		Hill 2-3 50-70 65-85 20-80
		Hill 4-6 20-25 15-85 20-80
		Multiply 0.5 land 0 0
		Smooth 2 0 0 0
		Range 3-4 20-50 15-35 20-45
		Range 2-4 20-50 65-85 45-80
		Strait 3-7 vertical 0 0
		Trough 6-8 20-50 15-85 45-65
		Pit 5-6 20-30 10-90 10-90"""

	var fractious: String = """Hill 12-15 50-80 5-95 5-95
		Mask -1.5 0 0 0
		Mask 3 0 0 0
		Add -20 30-100 0 0
		Range 6-8 40-50 5-95 10-90"""
		
	# Estuary template from : https://cartographyassets.com/assets/5119/estuary/
	var estuary: String = """Add 40 all 0 0
		Strait 20 horizontal 0 0
		Pit 100 40-50 0-35 0-100
		Multiply 0.6 35-40 0 0
		Smooth 2 0 0 0
		Strait 2-3 horizontal 0 0
		Trough 15-20 5-10 30-70 0-100
		Trough 10-15 3-7 25-45 0-20
		Trough 10-15 3-7 25-45-85 80-100"""
		
	var earth_like: String = """Hill 4-6 20-40 15-85 30-45
		Hill 3-7 20-40 15-85 55-70
		Strait 2-7 vertical 0 0
		Pit 1-2 40-50 35-55 20-80
		Strait 2-7 vertical 0 0
		Range 2-3 20-25 15-35 20-30
		Range 2-3 20-25 15-35 65-80
		Range 2-3 20-25 45-85 20-45
		Range 2-3 20-25 45-85 65-80
		Multiply .9 80-100 0 0
		Strait 2-7 vertical 0 0
		Pit 2-3 40-50 45-65 20-80
		Trough 1-2 40-50 15-45 20-45
		Trough 1-3 40-50 15-45 45-80
		Trough 1-2 40-50 45-85 20-45
		Trough 1-2 40-50 45-85 45-80
		Multiply 1.2 17-20 0 0
		Strait 2-7 horizontal 0 0
		Multiply 1.2 17-50 0 0
		Range 1-2 20-25 15-45 45-65
		Range 1-2 20-25 65-85 45-80
		Multiply 1.1 50-80 0 0
		Hill 1-2 20 15-45 20-80
		Hill 1-2 20 65-85 20-80
		Multiply 1.2 15-30 0 0
		Strait 2-7 vertical 0 0
		Trough 1-2 40-50 35-65 65-80
		Range 1-2 20-25 15-35 20-45
		Strait 2-7 vertical 0 0
		Range 1-2 20-25 65-85 45-80
		Multiply .9 70-100 0 0
		Hill 1-2 20-25 15-45 65-80
		Hill 1-2 20-25 65-85 20-45
		Hill 1 20-25 15-45 45-65
		Hill 1 20-25 65-85 45-65
		Strait 2-7 vertical 0 0
		Trough 1-2 20-50 15-45 45-65
		Trough 1-2 20-50 65-85 45-65
		Strait 2-7 horizontal 0 0
		Multiply 0.8 70-100 0 0
		Hill 1-2 20-25 35-45 45-65
		Hill 1-2 20-25 65-70 45-65
		Pit 2-3 40-50 45-65 30-70
		Trough 1-2 40-50 15-85 65-80
		Trough 1-2 40-50 15-85 10-35
		Strait 2-5 vertical 0 0
		Multiply 1.1 45-90 0 0
		Strait 3-7 vertical 0 0
		Trough 1-2 40-50 45-65 45-65"""
	#var fractious: String = """Hill 12-15 50-80 5-95 5-95
		#Add 100 all 0 0
		#Mask -.5 0 0 0"""

	return {
		"volcano": {"id": 0, "name": "Volcano", "template": volcano, "probability": 3},
		"highIsland": {"id": 1, "name": "High Island", "template": high_island, "probability": 19},
		"lowIsland": {"id": 2, "name": "Low Island", "template": low_island, "probability": 9},
		"continents": {"id": 3, "name": "Continents", "template": continents, "probability": 16},
		"archipelago": {"id": 4, "name": "Archipelago", "template": archipelago, "probability": 18},
		"atoll": {"id": 5, "name": "Atoll", "template": atoll, "probability": 1},
		"mediterranean": {"id": 6, "name": "Mediterranean", "template": mediterranean, "probability": 5},
		"peninsula": {"id": 7, "name": "Peninsula", "template": peninsula, "probability": 3},
		"pangea": {"id": 8, "name": "Pangea", "template": pangea, "probability": 5},
		"isthmus": {"id": 9, "name": "Isthmus", "template": isthmus, "probability": 2},
		"shattered": {"id": 10, "name": "Shattered", "template": shattered, "probability": 7},
		"taklamakan": {"id": 11, "name": "Taklamakan", "template": taklamakan, "probability": 1},
		"oldWorld": {"id": 12, "name": "Old World", "template": old_world, "probability": 8},
		"fractious": {"id": 13, "name": "Fractious", "template": fractious, "probability": 3},
		"estuary": {"id": 14, "name": "Estuary", "template": estuary, "probability": 3},
		"earthLike": {"id": 15, "name": "Earth Like", "template": earth_like, "probability": 3}
		}
).call() # Call the function

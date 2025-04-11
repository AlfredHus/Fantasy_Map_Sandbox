class_name HeightMapGenerator
extends Node
## Code from Azgaar's Fantasy Map Generator
## Ported from https://github.com/Azgaar/Fantasy-Map-Generator
##
## [url]https://github.com/Azgaar/Fantasy-Map-Generator/blob/master/modules/heightmap-generator.js[/url]
##
## TODO: SOme of the maps don't quite match the Azgaar maps, for example,
## contents do not always split apart.  Go through each of the maps and 
## make them match the Azgaar maps.

# Public Variables

## Heights contains the height(elevation) for each voronoi cell as calculated in
## the functions contained in the [b]HeightMapGenerator class[/b]
## Heights range from 0 - 100 and are integer values
var heights: Array[int] = []
## Used to store the starting point of a heightmap type so we can display it as a
## circle on the final map. Used for debugging purposes.
var starting_point

#Private Variables
var _heightmap_templates: HeightMapTemplates
var _blob_power: float
var _line_power: float
var _grid: Grid
var _voronoi: Voronoi

## Constructor
func _init(grid: Grid, voronoi: Voronoi, heightmap_type: String) -> void:
	
	_heightmap_templates = HeightMapTemplates.new()
	_voronoi = voronoi
	_grid = grid
	# points are the grid points that were calculated by Grid.get_jittered_grid
	heights.resize(grid.points_n)
	# Calculate blob and line powers
	_blob_power = get_blob_power(grid.cells_desired)
	_line_power = get_line_power(grid.cells_desired)

	generate(heightmap_type)
	grid.heights = heights
	grid.cells["h"] = heights
	
## Used to start the process of creating the map. 
## Params: heightmap_type - the type of height map to create,
##          ex., "volcano", "HighIsland", etc
func generate(heightmap_type: String) -> void:
	from_template(heightmap_type)

## Get the type of template from HeightMapTemplate which will define the parameters
## for creating the map, for example, "volcano"
func from_template(id: String) -> void:	
	# Get the template for the map we are gonig to create
	var template_string: String = _heightmap_templates.heightmap_templates[id]["template"]
	# Convert the multiline string to an array and strip out the leading "\t\t"
	var steps: PackedStringArray = template_string.replace("\t", "").split("\n")
	
	# if steps is empty, we passed in an invalid id value.
	# TODO: Add better error handling
	if steps.is_empty():
		print("Heightmap template: no steps. Template: %s. Steps: %s" % [id, steps])
	
	# A template has a set of steps that are used to construct the map, for example, "Smooth", 
	# Hill", "Pit". Eeach of these elements consist of a set of paramters that define the step.
	for step in steps:
		var elements: PackedStringArray = step.split(" ")
		if elements.size() < 2:
			print("Heightmap template: steps < 2. Template: %s. Step: %s" % [id, elements])
			continue
		# callv calls the method represented by the Callable, in this case, 
		# add_step. It passes all of the array values in elements as separate 
		# arguments. add_step will recieve theses arguments as individual
		# variables, for example: add_step(tool, a2, a3, a4, a5).
		# NOTE: We could of justd passed in the element as an array and 
		# accessed the invidual values in the array in add_step. The callv 
		# approach is how the source code did it, so for now we will keep the
		# same approach.
		add_step.callv(elements)

## A modifier for the blobs that are layed down during the height map creation
## The more cells, the larger the blob.		
func get_blob_power(cells: int) -> float:
	# Create a map for blob power
	var blob_power_map: Dictionary = {
		1000: 0.93,
		2000: 0.95,
		5000: 0.97,
		10000: 0.98,
		20000: 0.99,
		30000: 0.991,
		40000: 0.993,
		50000: 0.994,
		60000: 0.995,
		70000: 0.9955,
		80000: 0.996,
		90000: 0.9964,
		100000: 0.9973
	}
	# Return the value from the map or a default value of 0.98
	return blob_power_map.get(cells, 0.98)

## A modifier for the lines that are layed down during the height map creation
## A line is used for troughs and ridges. The more cells, the larger the blob.	
func get_line_power(cells: int) -> float:
	# Create a map for line power
	var line_power_map: Dictionary = {
		1000: 0.75,
		2000: 0.77,
		5000: 0.79,
		10000: 0.81,
		20000: 0.82,
		30000: 0.83,
		40000: 0.84,
		50000: 0.86,
		60000: 0.87,
		70000: 0.88,
		80000: 0.91,
		90000: 0.92,
		100000: 0.93
	}
	# Return the value from the map or a default value of 0.81
	return line_power_map.get(cells, 0.81)
	
## Add a step from the heightmap template. Each heightmap template has multiple
## steps. For each step, call the appropriate function to generate the step.
func add_step(tool: String , a2: String, a3: String, a4: String, a5: String) -> void:
	if (tool == "Hill"): return add_hill(a2, a3, a4, a5)
	if (tool == "Pit"): return add_pit(a2, a3, a4, a5)
	if (tool == "Range"): return add_range(a2, a3, a4, a5)
	if (tool == "Trough"): return add_trough(a2, a3, a4, a5)
	if (tool == "Strait"): return add_strait(a2, a3)
	if (tool == "Mask"): return mask(a2.to_float())
	if (tool == "Invert"): return invert(a2.to_float(), a3)
	if (tool == "Add"): return modify(a3, a2.to_float(), 1) 
	if (tool == "Multiply"): return modify(a3, 0, a2.to_float()) 
	if (tool == "Smooth"): return smooth(a2.to_float())

  #
## Raises the surrounding land
## Params
## - Count: The numbert of hill blobs to generate
func add_hill(count: String, height: String, range_x: String, range_y: String) -> void:
	var counter = ProbabilityUtilities.get_number_in_range(count)
	while counter > 0:
		add_one_hill(height, range_x, range_y)
		counter -= 1
	
## Adds a hill to the map. A hill by definition is a large blob
## that starts high and slowly descrease in height as you move farther away from
## the starting point.
# The function randomly gets a starting point and for this and every other
# point it processes, gets the neighbors of that point and assigns heights to
# them. It records whenever a point has had a height assigned to it in the
# the "change" array so it does not re-assign a height to that specific 
# point. When it is processing the point and its neighbours, it stores the 
# points and its neighbours that have not had a point assigned to it in a 
# "queue" which it uses to continue processing of the points for the hill.
# It continues this process until there are no more points in the queue.
# The result is that it will process many points to create one large
# hill blob, but there will be points remaining that have not had a 
# height value assigned to it. For example, if cells_desired is 1000 points
# then it may haave only assigned 600 points height values with the remaining 
# points having a height of "0".
# The range_x and range_y are used to specify where the hill be on map. 
func add_one_hill(height: String, range_x: String, range_y: String) -> void:
	var change := PackedInt32Array()
	var limit: int = 0
	var start: int
	var h: float

	# Get a random height value that is between the range "height", for example
	# the height range passed in might be "90-100" as a string. This height
	# will be used for the starting point of the hill.
	h = clamp(ProbabilityUtilities.get_number_in_range(height), 0, 100)
	
	# The change array is used to store the assigned heights and to check 
	# whether a height has been assigned to a point.
	change.resize(heights.size())
	
	# This block of code finds the initial starting point.
	while true:
		var x: float = get_point_in_range(range_x, _grid.width)
		var y: float = get_point_in_range(range_y, _grid.height)
		
		# Get the initial start point that will be used to begin the height 
		# map population
		start = _grid.find_grid_cell(x, y)
		
		# Make sure that the height value is > 90
		if heights[start] + h <= 90 or limit >= 50:
			break
		limit += 1
		
	# Used for debugging the code. Shows where the start cell is.
	var start_point = _grid.points[start] # DEBUG
	starting_point = start_point #DEBUG

	# Assign the initial height to the start location
	change[start] = h

	# Queue is used to store the points that have not yet had points assigned
	# to them. The initial will be of size 1 and contain the initial height
	#var queue: Array[float]
	var queue: Array[int]
	queue = [start]
	
	# Process cells using a queue
	while queue.size() > 0:
		var q: int = queue.pop_front()
		# cells["c"] contains the edges around a point for each point in the 
		# voronoi diagram. These are the triangle points. For each point we 
		# will have three or more entries. The are stored in the cells["c"]
		# dic666tionary where each point in the dictionary will consist
		# of an array of the edge indexes that are around the point.
		# For each edge in the array value is calculated "change[c]" which is
		# the calculated height for that edge
		# cells["c"] stores the neighbours of a point, i.e. the edges around the point
		# for each unused neighbor
		for c in _grid.cells["c"][q]:
			if change[c] > 0:
				continue		
			# Calculate the height for the point and mark it as used
			# For each height, add some randomness to provide for more 
			# irregularity.
			change[c] = pow(change[q], _blob_power) * (randf() * 0.2 + 0.9)
			if change[c] > 1:
				# Add the point to the queue
				queue.append(c)
	# Put the heights into the heights array. Clamp the values so the height will be between 0 and 100
	for i in heights.size():
		heights[i] = clamp(heights[i] + change[i], 0, 100)

## Lowers the surrounding land		
func add_pit(count: String, height: String, range_x: String, range_y: String) -> void:
	var counter = ProbabilityUtilities.get_number_in_range(count)
	while counter > 0:
		add_one_pit(height, range_x, range_y)
		counter -= 1

## Lower the surrounding land by one pit step.
func add_one_pit(height: String, range_x: String, range_y: String) -> void:
	var used := PackedInt32Array()
	used.resize(heights.size())	
	
	var limit: int = 0
	var start: int = 0
	var h: float
	
	h = clamp(ProbabilityUtilities.get_number_in_range(height), 0, 100)
	
	used.resize(heights.size())	
	
	while true:
		var x = get_point_in_range(range_x, _grid.width)
		var y = get_point_in_range(range_y, _grid.height)
		
		start = _grid.find_grid_cell(x, y)
		
		# Save the starting point so we can draw it on the map
		# USed for debugging
		starting_point = _grid.points[start] #DEBUG
		
		if heights[start] >= 20 and limit >= 50:
			break
		limit += 1
		
		var queue: Array[int]
		queue = [start]
		
		while queue.size() > 0:
			var q = queue.pop_front()
			h = pow(h, _blob_power) * (randf() * 0.2 + 0.9)
			if (h < 1.0): return;
			
			for c in _grid.cells["c"][q]:
				if used[c] == 1:
					continue
				heights[c] = int(clamp(heights[c] - h * (randf() * 0.2 + 0.9), 1, 100))
				used[c] = 1
				queue.append(c)		

# Creates a thin raised section
func add_range(count: String, height: String, range_x: String, range_y: String) -> void:
	var counter = ProbabilityUtilities.get_number_in_range(count)
	while counter > 0:
		add_one_range(height, range_x, range_y)
		counter -= 1

# Creates a thin raised section by one step.
func add_one_range(height: String, range_x: String, range_y: String) -> void:
	var used := PackedInt32Array()
	var start_cell: int
	var end_cell: int 
	var h: float = clamp(ProbabilityUtilities.get_number_in_range(height), 1, 100)
	
	used.resize(heights.size())

	if range_x and range_y:
		# Find start and end points
		var start_x: int = get_point_in_range(range_x, _grid.width)
		var start_y: int = get_point_in_range(range_y, _grid.height)

		var dist: int = 0
		var limit: int = 0
		var end_x: int
		var end_y: int

		while (dist < _grid.width / 8 or dist > _grid.width / 3) and limit < 50:
			end_x = randf() * _grid.width * 0.8 + _grid.width * 0.1
			end_y = randf() * _grid.height * 0.7 + _grid.height * 0.15
			dist = abs(end_y - start_y) + abs(end_x - start_x)
			limit += 1

		start_cell = _grid.find_grid_cell(start_x, start_y)
		end_cell = _grid.find_grid_cell(end_x, end_y)
		
		# Used for debugging
		var start_point:  = _grid.points[start_cell] # DEBUG
		starting_point = start_point #DEBUG

	var range_values = get_range(start_cell, end_cell, used, _grid.points, 0.85)

	# Add height to ridge and cells around
	var queue: Array[int] = range_values.slice(0) 
	var i = 0
	while queue.size() > 0:
		var frontier: Array[int] = queue.slice(0) 
		queue.clear()
		i += 1
		for cur in frontier:
			heights[cur] = int(clamp(heights[cur] + h * (randf() * 0.3 + 0.85), 1, 100))

		h = h ** _line_power - 1
		if h < 2:
			break
		for f in frontier:
			for neighbor in _grid.cells["c"][f]:
				if used[neighbor] == 0:
					queue.append(neighbor)
					used[neighbor] = 1

	# Generate prominences
	for d in range_values.size():
		if d % 6 != 0: # Only process every 6th element
			continue
		var cur: int = range_values[d]
		for l in range(i):
			var neighbors: Array = _grid.cells["c"][cur]
			var min_index: int = scan(neighbors, Callable(self, "_compare_heights"))

			var min: int = neighbors[min_index]
			heights[min] = int((heights[cur] * 2.0 + heights[min]) / 3.0)
			cur = min

## Creates a thin lowered section	
func add_trough(count: String, height: String, range_x: String, range_y: String) -> void:
	var counter: int = ProbabilityUtilities.get_number_in_range(count)
	while counter > 0:
		add_one_trough(height, range_x, range_y)
		counter -= 1

## Creates a single thin lowered section	
func add_one_trough(height: String, range_x: String, range_y: String) -> void:
	var used := PackedInt32Array()
	var start_cell: int
	var end_cell: int
	
	used.resize(heights.size())

	var h: float = clamp(ProbabilityUtilities.get_number_in_range(height), 1, 100)
	
	# NOTE: range_x and range_y do not change in the function so the "if" 
	# statement will always evaluate to "true". Looks like its only function
	# is to ensure that both "range_x" and "range_y" have values
	if range_x and range_y:
		# Find start and end points
		var limit: int = 0
		var start_x: int
		var start_y: int
		var dist: int = 0
		var end_x: int
		var end_y: int

		# Find the start cell
		while limit < 50:
			start_x = get_point_in_range(range_x, _grid.width)
			start_y = get_point_in_range(range_y, _grid.height)
			start_cell = _grid.find_grid_cell(start_x, start_y)
			if heights[start_cell] >= 20:
				break
			limit += 1
			
		# Save the starting point so we can draw it on the map
		# Used for debugging
		starting_point = _grid.points[start_cell] #DEBUG

		# Find the end cell
		limit = 0
		while limit < 50:
			end_x = randf() * _grid.width * 0.8 + _grid.width * 0.1
			end_y = randf() * _grid.height * 0.7 + _grid.height * 0.15
			dist = abs(end_y - start_y) + abs(end_x - start_x)
			if _grid.width / 8 <= dist and dist <= _grid.width / 2:
				break
			limit += 1

		end_cell = _grid.find_grid_cell(end_x, end_y)

	# get main ridge
	var trough_range: Array[int] = get_range(start_cell, end_cell, used, _grid.points, 0.80)

	# Add height to ridge and surrounding cells
	var queue: Array[int] = trough_range.slice(0)
	var i: int = 0
	while queue.size() > 0:
		var frontier: Array[int] = queue.slice(0)
		queue.clear()
		i += 1
		for f in frontier:
			heights[f] = int(clamp(heights[f] - h * (randf() * 0.3 + 0.85), 1, 100))
		h = pow(h, _line_power - 1)
		if h < 2:
			break
		for f in frontier:
			for neighbor in _voronoi.cells["c"][f]:
				if not used[neighbor]:
					queue.append(neighbor)
					used[neighbor] = true

	# Generate prominences
	for d in trough_range.size():
		var cur: int = trough_range[d]
		if d % 6 != 0:
			continue

		for l in range(i):
			var neighbors: Array = _grid.cells["c"][cur]
			var min_index: int = scan(neighbors, Callable(self, "_compare_heights"))
			var min: int = neighbors[min_index]
			heights[min] = (heights[cur] * 2 + heights[min]) / 3
			cur = min

# Creates a vertical or horizontal lowered section
func add_strait(width: String, direction: String = "vertical") -> void:
	
	var width_of_strait: float = min(ProbabilityUtilities.get_number_in_range(width), _grid.cells_x / 3)

	if width_of_strait < 1 and ProbabilityUtilities.P(width):
		return

	var used: Array[int]
	used.resize(heights.size())
	
	var vert: bool = (direction == "vertical")
	var start_x: int = floor(randf() * _grid.width * 0.4 + _grid.width * 0.3) if vert else 5
	var start_y: int = 5 if vert else floor(randf() * _grid.height * 0.4 + _grid.height * 0.3)
	var end_x: int = floor(_grid.width - start_x - _grid.width * 0.1 + randf() * _grid.width * 0.2) if vert else _grid.width - 5
	var end_y: int = _grid.height - 5 if vert else floor(_grid.height - start_y - _grid.height * 0.1 + randf() * _grid.height * 0.2)
	var start: int = _grid.find_grid_cell(start_x, start_y)
	var end: int = _grid.find_grid_cell(end_x, end_y)
	
	# NOTE: "used" is an array and is passed by reference. get_range populates
	# "used" and when the function returns, "used" is populated with values
	# In the javascript code, "ger_range" is an inner function to add_strait,
	# so it has access to the values that are modified in get_range.
	var strait_range: Array[int] = get_range(start, end, used, _grid.points, 0.80)
	var query: Array[int]

	# Save the starting point so we can draw it on the map
	# Sed for debugging
	starting_point = _grid.points[start] #DEBUG

	var step: float = 0.1 / width_of_strait

	while width_of_strait > 0:
		var exp: float = 0.9 - step * width_of_strait
		for r in strait_range:
			# Walk through the neighbors of the range valye "r"
			# REmember that cells["c"] is a dictionary of arrays where
			# each array contains the neighbors for the point
			for e in _grid.cells["c"][r]:
				if used[e]:
					continue
				used[e] = 1
				query.append(e)
				heights[e] = int(heights[e] ** exp)
				if heights[e] > 100:
					heights[e] = 5

		strait_range  = query.slice(0)
		width_of_strait -= 1

## Modify is called when you are doing an Add or a Multiply step from the templates.
## Add ir Subtract from all heights
## Multiply all heights
## When doing an Add, the step will look like this: 
## "Add 7 all 0 0" or this: "Add -20 30-100 0 0". The second parameter can be either "all" or a 
## range.
## For Multiply, the step will look like this: "Multiply 0.8 50-100 0 0" or "Multiply 0.8 land 0 0
## The second parameter can be either a range or "land".
## When adding a step for Add, the parameters and their order look this: modify(a3, a2.to_float(), 1)
## Only three of the four parameters are used. If you look at a Add step, "Add 7 all 0 0", 
## where tool = "add", a2 = 7, a3 = all, a4 = 0, a5 = 0
## The paremeters would be modify("all", 7, 1). 
## For the second Add format, "Add -20 30-100 0 0", where tool "Add", a2 = -20, a3 = 30-100, a4 = 0
## and a5 = 0. The parmeters for modify would be modify(30-100, -20, 1)
## When adding a step for Multiply, it will look like this: modify(a3, 0, a2.to_float())
## Only three of the four parameters are used. Looking at "Multiply 0.8 50-100 0 0", 
## tool = "multiply", a2 = 0.8, a3 = 50-100, a4 = 0, a5 = 0. The paremeters for modify would be
## modify (50-100, 0, 0.8)
## For the other format, "Multiply 0.8 land 0 0", the parmeters would be a2 = "Multiply", 
## a2 = 0.8, "a3 = "land", a4 = 0, a5 = 0. The call to modify would be modify("land", 0, 0.8)
## So a summary of the combinations would look like this:
## For Add:
##  modify(target_range = "all", add = 7, mult = 1, power = 0)
##  modify(target_range = 30-100, add = -20, mult = 1, power = 0)
## For Multiply:
##  modify (target_range = 50-100, add = 0, multi = 0.8)
##  modify(target_range = "land", add = 0, multi = 0.8)
##
## The Add step adds or subracts a value from all heights in range
## The multiply step multiplies all heights in range by a factor
func modify(target_range: String, add: float, mult: float, power: float = 0.0) -> void:
	# target_range can either be a range, 30-100 or "land", or "all"
	# power does not seem to be used, so it will default to 0.0
	var minimum: float
	var maximum: float
	var is_land: bool

	# if target_range is "land, set a minimum and maximum range of 20 - 100.
	if target_range == "land":
		minimum = 20.0
		maximum = 100.0
		is_land = true
	# if target_range = "all", set a minimum and maximum range of 0 = 100.
	elif target_range == "all":
		minimum = 0.0
		maximum = 100.0
		is_land = false
	else:
		# if target_range is an actual range value like "30 - 100", we need to strip out the two range values
		# and convert the string format to a float,
		var range_parts : PackedStringArray = target_range.split("-")
		minimum = float(range_parts[0])
		maximum = float(range_parts[1])	
		
	# We set is_land to true if the minimum value has been set to 20. This occurs if the target_range = "land"
	# It is also possible this could be set to 20.0 if the range starts with a 20, for example, 20 - 30
	is_land = (minimum == 20.0)

	for i in heights.size():
		var h: int = heights[i]
		if h < minimum or h > maximum:
			continue

		# When converting a float to an int, godot truncates the float discarding 
		# anything after the floating point.
		# https://docs.godotengine.org/en/stable/classes/class_int.html
		if add != 0:
			h = max(h  + add, 20) if is_land else h + add # Ternary operator in GDscript
			
		if mult != 1:
			h = (h - 20) * mult + 20 if is_land else h * mult

		if power != 0:
			h = pow(h - 20, power) + 20 if is_land else pow(h, power)

		heights[i] = clamp(h, 0, 100)	


## Smooth all heights
## The smooth step looks like this: "Smooth 3 0 0 0" where there is only one value being set
## The add step for smooth is this: smooth(a2) where you only pass in one value, a2.
## The other way it is used is in the editor for Azgaars fantasy map where you can this format:
## smooth(4, 1.5), where you have two arguments being passed in.  Note, in this example, 
## the values are being passed in as numbers and not a string like it is done with add step.
#
## Smooth smooths the map by replacing cell heights by the average values of its neighbors.
## This means land next to a pit will lower, and land next to a hill will rise. Smooth removes any 
## spiky bits near land
func smooth(fr: float = 2.0, add: float = 0.0) -> void:
	var new_heights: Array[int]= []
	for i in range(heights.size()):
		var neighbors: Array[int] = [heights[i]]  # Include the current height
		for c in _grid.cells["c"][i]: # Add the neighbors' heights
			neighbors.append(heights[c])

		var mean: float = Statistics.mean(neighbors)
		if fr == 1:
			new_heights.append(int(mean + add))
		else:
			var smoothed: int = clamp((heights[i] * (fr - 1) + mean + add) / fr, 1, 100)
			new_heights.append(smoothed)
	
	heights = new_heights


## Mask heightmap (lower all cells along the map edge or in the map center
## The mask step looks like this: "Mask 3 0 0 0". Only the first value is used.
## Mask lowers cells near edges or in map center
func mask(power: float = 1.0) -> void:
	var fr: float = abs(power) if power != 0.0 else 1.0
	
	for i in heights.size():
		var h: int = heights[i]
		var point: Vector2 = _grid.points[i]
		var nx: float = (2 * point[0]) / _grid.width - 1.0 # [-1, 1], 0 is center
		var ny: float = (2 * point[1]) / _grid.height - 1.0 # [-1, 1], 0 is center
		var distance: float = (1 - nx ** 2) * (1 - ny ** 2) # 1 is center, 0 is edge
		if power < 0.0:
			distance = 1 - distance # inverted, 0 is center, 1 is edge
		var masked: float = h * distance
		heights[i] = int(clamp((h * (fr - 1) + masked) / fr, 1, 100))

## Invert the heightmap (mirror by x,y or both axes)
## The invert step looks like this: "Invert 0.4 both 0 0"
## Invert heightmap along the axes
func invert(count: float, axes: String) -> void:
	if not ProbabilityUtilities.P(count):
		print ("No count value provided in the invert function")
		return

	var invert_x: bool = axes != "y"
	var invert_y: bool = axes != "x"
	var cells_x: int = _grid.cells_x
	var cells_y: int = _grid.cells_y
	var inverted: Array[int]

	for i in heights.size():
		var x: int = i % cells_x
		var y = floor(i / cells_x)
		var nx: int = cells_x - x - 1 if invert_x else x
		var ny: int = cells_y - y - 1 if invert_y else y
		var inverted_i: int = nx + (ny * cells_x)
		inverted.append(heights[inverted_i])
	heights = inverted

# Returns an range of integer values
func get_range(cur: int, end: int, used: Array[int], points: PackedVector2Array, diff_random: float) -> Array[int]:
	var range_values: Array[int] = [cur]
	used[cur] = 1

	while cur != end:
		var minimum: float = INF
		
		for e in _grid.cells["c"][cur]:
			if used[e]:
				continue
				
			var diff: float = pow(points[end][0] - points[e][0], 2) + pow(points[end][1] - points[e][1], 2)
			if randf() > diff_random:
				diff /= 2
			if diff < minimum:
				minimum = diff
				cur = e
		if minimum == INF:
			return range_values
		range_values.append(cur)
		used[cur] = 1

	return range_values
	
## This function returns a random point that is between a lower and upper
## range as defined by the String argument "target_range"
func get_point_in_range(target_range: String, length: float) -> float:
	if typeof(target_range) != TYPE_STRING:
		print("Range should be a string")
		return 0.0

	var split_range: PackedStringArray = target_range.split("-")
	var minimum: float = (float(split_range[0]) / 100.0) if split_range.size() > 0 else 0.0
	var maximum: float = (float(split_range[1]) / 100.0) if split_range.size() > 1 else minimum

	# Return a random value between the minimum and maximum
	return ProbabilityUtilities.rand(minimum * length, maximum * length)
	
# Scan an array lineraly and return the index of the minumum
# element according to the specified comparator
#
# Parameters
# * array: Contains a array of elements whose minimum value is to be
#   calculated and the respective index returned
# * comparator: specifies how the minimum element is to be obtained
#
func scan(array: Array, comparator: Callable) -> int:
	if array.is_empty():
		return -1  # Return -1 if the array is empty

	var min_index: int = 0
	for i in range(1, array.size()):
		if comparator.call(array[i], array[min_index]) < 0:
			min_index = i

	return min_index
	
# Helper function to compare heights.
func _compare_heights(a, b) -> int:
	return heights[a] - heights[b]	

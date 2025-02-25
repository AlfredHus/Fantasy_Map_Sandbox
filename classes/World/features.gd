class_name Features
extends Node



###################################################################################################
# Public Variables
###################################################################################################
# Feature type constants
const DEEPER_LAND = 3
const LANDLOCKED = 2
const LAND_COAST = 1
const UNMARKED = 0
const WATER_COAST = -1
const DEEP_WATER = -2

const INT8_MAX: int = 127

###################################################################################################
# Private Variables
###################################################################################################
# Variables used to measure the time it takes to do something
var _time_now: int 
var _time_elapsed: int

var _grid
# Make a copy of the heights array to use
#var heights: Array[int] = grid.heights.duplicate()
# FIXME. I need to change the packed arrays back to typed arrays.
# For now, this is a workaround. Array Array ( PackedInt32Array from )
var _heights: Array[int] = []
# The number of cells does not include the boundary points
var _cells_number: int
# grid.cells.t
var _distance_field: Array[int] = [] 
## grid.cells.f
#var _feature_ids: Array[int] = []
#var neighbors = grid.cells["c"].duplicate
#var _neighbors
#var _border_cells
var _features = []
var _path_utils: PathUtils
var _common_utils: CommonUtils
var _polygon: Polygon
#var _haven = []
#var _harbor = []




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print ("ENTERING FEATURES NODE")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _init(grid: Grid):
	_grid = grid
		# Make a copy of the heights array to use
	#var heights: Array[int] = grid.heights.duplicate()
	# FIXME. I need to change the packed arrays back to typed arrays.
	# For now, this is a workaround. Array Array ( PackedInt32Array from )
	#var heights := Array(grid.heights)
	# The number of cells does not include the boundary points
	_heights = grid.heights.duplicate()
	
	#var cells_number: int = grid.points_n
	#_cells_number = grid.i.size()
	#_cells_number = grid.cells["i"].size()
	_cells_number = grid.points_n
	# grid.cells.t
	#var distance_field: Array[int] = [] 
	# grid.cells.f
	#var feature_ids: Array[int] = []
	#_neighbors = grid.cells["c"]
	##var neighbors = grid.cells["c"]
	#
	##var border_cells = grid.cells["b"]
	#_border_cells = grid.cells["b"]
	#var features: Array[int] = [0]
	#var features = []
	_distance_field.resize(_cells_number)
	#_feature_ids.resize(_cells_number)
	
	
	#_haven.resize(_cells_number)
	#_harbor.resize(_cells_number)
	
	_path_utils = PathUtils.new()
	_common_utils = CommonUtils.new()
	_polygon = Polygon.new()
	
	

## Mark Grid features (ocean, lakes, islands) and calculate distance field
func markup_grid(grid: Grid) -> void:
	
	var _neighbors
	var _border_cells
	_neighbors = grid.cells["c"]
	_border_cells = grid.cells["b"]
	# Measure the time it takes to perform this task
	_time_now  = Time.get_ticks_msec()	

	var queue: Array[int]
	queue = [0]
	var feature_id: int = 1
	var land: bool
	var counter: int = 0 # TEMP
	# grid.cells.f
	var _feature_ids: Array[int] = []
	_feature_ids.resize(_cells_number)
	while queue[0] != -1:
		counter += 1 # TEMP
		var first_cell: int = queue[0]
		_feature_ids[first_cell] = feature_id
		land = true if _heights[first_cell] >= 20 else false
		# set true if feature touches map edge
		var border: bool = false 
		
		while queue.size() > 0:
			# NOTE: In Javascript, array.pop() removes the last element from 
			# an array. The equivalent in gdscript is array.pop_back()
			#var cell_id: int = queue.pop_back()
			var cell_id: int = queue.pop_back()

			if not border and _border_cells[cell_id]:
				border = true
				
			for neighbor_id in _neighbors[cell_id]:
				var is_neib_land: bool = _heights[neighbor_id] >= 20

				if land == is_neib_land and _feature_ids[neighbor_id] == UNMARKED:
					_feature_ids[neighbor_id] = feature_id
					queue.append(neighbor_id)
				# if the cell is land, but there is no neighboring cell that is
				# land, then the cell is a cosst
				elif land and not is_neib_land:
					_distance_field[cell_id] = LAND_COAST
					_distance_field[neighbor_id] = WATER_COAST 

		## Determine the feature type.
		var type: String = ""
		if land:
			type = "island"
		elif border:
			type = "ocean"
		else:
			type = "lake"
		

		_features.append({
			"i": feature_id,
			"land": land,
			"border": border,
			"type": type
		})
		
		var unmarked_index: int = _feature_ids.find(UNMARKED)
		queue.append(unmarked_index)

		feature_id += 1 	# End while feature loop


	# Markup deep ocean cells.
	markup(_distance_field, _neighbors,DEEP_WATER, -1, -10)
	
	print ("Counter = ", counter)

# Distance field from water level. 
# 1, 2, .... - land cells  
# -1, -2, ... - water cells
# 0 - unmarked cell
	grid.t = _distance_field
# indexes of the features
	grid.f = _feature_ids
	grid.features = _features
	#print ("Features: ", _features)
	#print ("Features ID: ", grid.f)
	#print ("Size of grid.t: ", grid.t.size())
	#print ("Size of grid.f: ", grid.f.size())
	#print ("Size of grid.features: ", grid.features.size())

	_time_elapsed = Time.get_ticks_msec() - _time_now
	print("markup_grid time: ", _time_elapsed)
		
func markup(distance_field, neighbors, start, increment, limit = INT8_MAX) -> void:
	var distance: int = start
	var marked = INF

	while marked > 0 and distance != limit:
		marked = 0
		var prev_distance = distance - increment
	
		for cell_id in range(neighbors.size()):
			if distance_field[cell_id] != prev_distance:
				continue

			for neighbor_id in neighbors[cell_id]:
				#print ("neighbor_id: ", neighbor_id, "Cell_id: ", cell_id)
				if distance_field[neighbor_id] != UNMARKED:
					continue
				distance_field[neighbor_id] = distance
				marked += 1
		distance += increment
		
## Mark Grid features (ocean, lakes, islands) and calculate distance field
func markup_grid_packed(grid: Grid) -> void:
	var _haven = []
	var _harbor = []
	
	var _neighbors
	var _border_cells
	# Measure the time it takes to perform this task
	_time_now  = Time.get_ticks_msec()	

	_haven.resize(_cells_number)
	_harbor.resize(_cells_number)
	_neighbors = grid.cells["c"]
	_border_cells = grid.cells["b"]
	# FIXME. I need to change the packed arrays back to typed arrays.
	# For now, this is a workaround. Array Array ( PackedInt32Array from )

	#var haven = []
	#var harbor = []

	
	var queue: Array[int]
	queue = [0]
	var feature_id: int = 1
	var land: bool
	var counter: int = 0 # TEMP
	var features = []
	var _feature_ids: Array[int] = []
	
	_feature_ids.resize(_cells_number)
	while queue[0] != -1:
		counter += 1 # TEMP
		var first_cell: int = queue[0]
		_feature_ids[first_cell] = feature_id
		land = true if _heights[first_cell] >= 20 else false
		# true if feature touches map border
		var border: bool = true if _border_cells[first_cell] == 1 else false
		#  count cells in a feature
		var total_cells: int = 1	
		
		while queue.size() > 0:
			# NOTE: In Javascript, array.pop() rempoves the last element from 
			# an array. The equivalent in gdscript is array.pop_back()
			#var cell_id: int = queue.pop_back()
			var cell_id: int = queue.pop_back()

			if _border_cells[cell_id]: 
				border = true;
				
			if not border and _border_cells[cell_id]:
				border = true
			
			for neighbor_id in _neighbors[cell_id]:
				var is_neib_land: bool
				if  _heights[neighbor_id] >= 20:
					is_neib_land = true
					
				if (land == true and is_neib_land == false):
					_distance_field[cell_id] = LAND_COAST
					_distance_field[neighbor_id] = WATER_COAST
					if (_haven[cell_id] == 0):
						define_haven(cell_id, _neighbors, _haven, _harbor)
				elif (land == true and is_neib_land == true):
					if _distance_field[neighbor_id] == UNMARKED and _distance_field[cell_id] == LAND_COAST:
						_distance_field[neighbor_id] = LANDLOCKED
				elif _distance_field[cell_id] == UNMARKED and _distance_field[neighbor_id] == LAND_COAST:
					_distance_field[cell_id] == LANDLOCKED
				
				if !_feature_ids[neighbor_id] and land == is_neib_land:
					queue.append(neighbor_id)
					_feature_ids[neighbor_id] = feature_id
					total_cells += 1
					
		features.append(add_feature(first_cell, land, border, feature_id, total_cells, _feature_ids, _border_cells, _neighbors))
		print ("markup_grid_packed:_features: ", _features)
		#var temp_feature = add_feature(first_cell, land, border, feature_id, total_cells, _feature_ids)
		#queue.append(_feature_ids.find(UNMARKED))
		if queue == []:
			queue = [0]
		queue[0] = _feature_ids.find(UNMARKED)
		feature_id += 1 	# End while feature loop
	
	
	markup(_distance_field, _neighbors,  DEEPER_LAND, 1) # markup pack land
	markup(_distance_field, _neighbors, DEEP_WATER, -1, -10) # markup pack water
	
	grid.t = _distance_field
	grid.f = _feature_ids
	grid.features = _features
	grid.haven = _haven
	grid.harbor = _harbor
	
	grid.pack["t"] = _distance_field
	grid.pack["f"] = _feature_ids
	grid.pack["features"] = features
	grid.pack["haven"] = _haven
	grid.pack["harbor"] = _harbor
	
	print ("Features: ", _features)
	print ("Features ID: ", _feature_ids)
	print ("Size of grid.t: ", grid.t.size())
	print ("Size of grid.f: ", grid.f.size())
	print ("Size of grid.features: ", grid.features.size())

	_time_elapsed = Time.get_ticks_msec() - _time_now
	print("markup_grid_packed time: ", _time_elapsed)


func markup_packed(grid: Grid) -> void:
	var _haven = []
	var _harbor = []
	
	var _neighbors
	var _border_cells
	# Measure the time it takes to perform this task
	_time_now  = Time.get_ticks_msec()	

	_haven.resize(_cells_number)
	_harbor.resize(_cells_number)
	_neighbors = grid.cells["c"]
	_border_cells = grid.cells["b"]
	# FIXME. I need to change the packed arrays back to typed arrays.
	# For now, this is a workaround. Array Array ( PackedInt32Array from )

	#var haven = []
	#var harbor = []

	
	var queue: Array[int]
	queue = [0]
	var feature_id: int = 1
	var land: bool
	var counter: int = 0 # TEMP
	var features = []
	var _feature_ids: Array[int] = []
	
	_feature_ids.resize(_cells_number)
	while queue[0] != -1:
		counter += 1 # TEMP
		var first_cell: int = queue[0]
		_feature_ids[first_cell] = feature_id
		land = true if _heights[first_cell] >= 20 else false
		# true if feature touches map border
		var border: bool = true if _border_cells[first_cell] == 1 else false
		#  count cells in a feature
		var total_cells: int = 1	
		
		while queue.size() > 0:
			# NOTE: In Javascript, array.pop() rempoves the last element from 
			# an array. The equivalent in gdscript is array.pop_back()
			#var cell_id: int = queue.pop_back()
			var cell_id: int = queue.pop_back()

			if _border_cells[cell_id]: 
				border = true;
				
			if not border and _border_cells[cell_id]:
				border = true
			
			for neighbor_id in _neighbors[cell_id]:
				var is_neib_land: bool
				if  _heights[neighbor_id] >= 20:
					is_neib_land = true
					
				if (land == true and is_neib_land == false):
					_distance_field[cell_id] = LAND_COAST
					_distance_field[neighbor_id] = WATER_COAST
					if (_haven[cell_id] == 0):
						define_haven(cell_id, _neighbors, _haven, _harbor)
				elif (land == true and is_neib_land == true):
					if _distance_field[neighbor_id] == UNMARKED and _distance_field[cell_id] == LAND_COAST:
						_distance_field[neighbor_id] = LANDLOCKED
				elif _distance_field[cell_id] == UNMARKED and _distance_field[neighbor_id] == LAND_COAST:
					_distance_field[cell_id] == LANDLOCKED
				
				if !_feature_ids[neighbor_id] and land == is_neib_land:
					queue.append(neighbor_id)
					_feature_ids[neighbor_id] = feature_id
					total_cells += 1
					
		features.append(add_feature(first_cell, land, border, feature_id, total_cells, _feature_ids, _border_cells, _neighbors))
		print ("markup_grid_packed:_features: ", _features)
		#var temp_feature = add_feature(first_cell, land, border, feature_id, total_cells, _feature_ids)
		#queue.append(_feature_ids.find(UNMARKED))
		if queue == []:
			queue = [0]
		queue[0] = _feature_ids.find(UNMARKED)
		feature_id += 1 	# End while feature loop
	
	
	markup(_distance_field, _neighbors,  DEEPER_LAND, 1) # markup pack land
	markup(_distance_field, _neighbors, DEEP_WATER, -1, -10) # markup pack water
	
	grid.t = _distance_field
	grid.f = _feature_ids
	grid.features = _features
	grid.haven = _haven
	grid.harbor = _harbor
	
	grid.pack["t"] = _distance_field
	grid.pack["f"] = _feature_ids
	grid.pack["features"] = features
	grid.pack["haven"] = _haven
	grid.pack["harbor"] = _harbor
	
	print ("Features: ", _features)
	print ("Features ID: ", _feature_ids)
	print ("Size of grid.t: ", grid.t.size())
	print ("Size of grid.f: ", grid.f.size())
	print ("Size of grid.features: ", grid.features.size())

	_time_elapsed = Time.get_ticks_msec() - _time_now
	print("markup_grid_packed time: ", _time_elapsed)
#func add_feature(first_cell: int, land: bool, border: bool, feature_id: int, total_cells: int, _feature_ids) -> Dictionary:
#
	#var type: String
	#if land:
		#type = "island"
	#elif border:
		#type = "ocean"
	#else:
		#type = "lake"
	#
	#var cells_data: Array = get_cells_data(_feature_ids, type, first_cell)
	#var start_cell: int = cells_data[0]
	#var feature_vertices: Array = cells_data[1]
	#
	#var points: Array = []
	#for vertex in feature_vertices:
		#points.append(_grid.vertices["p"][vertex])
		#
	#points = _common_utils.clip_poly(points, _grid.width, _grid.height)
	#var area = _polygon.polygon_area(points)
	#var abs_area = abs(GeneralUtilities.rn(area))
#
	#var feature: Dictionary = {
		#"i": feature_id,
		#"type": type,
		#"land": land,
		#"border": border,
		#"cells": total_cells,
		#"firstCell": start_cell,
		#"vertices": feature_vertices,
		#"area": abs_area
	#}
#
	#if type == "lake":
		#if area > 0:
			#feature["vertices"].reverse()  
#
		#var shoreline_temp: Array = []
		#for vertex in feature["vertices"]:
			#for cell in _grid.vertices["c"][vertex]:
				##if is_land(cell):
				#if _grid.heights[cell] >= 20:
					#shoreline_temp.append(cell)
		#feature["shoreline"] = _common_utils.unique(shoreline_temp)
		##feature["height"] = Lakes.get_height(feature)
		#
	#return feature
func add_feature(first_cell: int, land: bool, border: bool, feature_id: int, total_cells: int,  feature_ids: Array,  border_cells, neighbors) -> Dictionary:
	var type_str = ""
	if land:
		type_str = "island"
	elif border:
		type_str = "ocean"
	else:
		type_str = "lake"
	
	# Get the starting cell and the list of feature vertices.
	var cells_data = get_cells_data1(type_str, first_cell, feature_ids,border_cells, neighbors)
	var start_cell = cells_data[0]
	var feature_vertices = cells_data[1]
	
	# Map feature vertices to points and clip the polygon.
	var points = []
	for vertex in feature_vertices:
		points.append(_grid.vertices["p"][vertex])
	points = _common_utils.clip_poly(points, _grid.width, _grid.height)
	var area = _polygon.polygon_area(points)
	var abs_area = abs(GeneralUtilities.rn(area))
	
	var feature: Dictionary = {
		"i": feature_id,
		"type": type_str,
		"land": land,
		"border": border,
		"cells": total_cells,
		"firstCell": start_cell,
		"vertices": feature_vertices,
		"area": abs_area
	}
	
	if type_str == "lake":
		if area > 0:
			#feature["vertices"] = feature["vertices"].duplicate()
			feature["vertices"].reverse()
		var shoreline = []
		for vertex in feature["vertices"]:
			var filtered = []
			for cell_val in  _grid.vertices["c"][vertex]:
				if _grid.isLand(cell_val):
					filtered.append(cell_val)
			shoreline += filtered
		feature["shoreline"] = _common_utils.unique(shoreline)
		#feature["height"] = Lakes.get_height(feature)
	
	return feature	


#func get_cells_data(feature_ids: Array[int], feature_type: String, first_cell: int) -> Array:
	#
	#if feature_type == "ocean":
		#return [first_cell, []]
		#
	#var get_type = func (cell_id: int, feature_ids): 
		#return feature_ids[cell_id]
	#var type = get_type(first_cell, feature_ids)
	#var of_same_type = func (cell_id: int):
		#get_type(cell_id, feature_ids) == type
	#var of_different_type = func (cell_id: int):
		#return get_type(cell_id, feature_ids) != type
	#
	##var type: int = get_type(first_cell)
	#var start_cell: int = find_on_border_cell(first_cell, type, feature_ids)
	#
	#var feature_vertices: Array = get_feature_vertices(start_cell, type, feature_ids, of_different_type)
	#
	#return[start_cell, feature_vertices]
	
func get_cells_data1(feature_type: String, first_cell: int, feature_ids: Array, border_cells: Array, neighbors) -> Array:
	
	if feature_type == "ocean":
		return [first_cell, []]
		
	var get_type = func (cell_id: int, feature_ids): 
		return feature_ids[cell_id]
	var type = get_type.call(first_cell, feature_ids)
	var of_same_type = func (cell_id: int):
		get_type.call(cell_id, feature_ids) == type
	var of_different_type = func (cell_id: int):
		return get_type.call(cell_id, feature_ids) != type
	
	#var type: int = get_type(first_cell)
	var start_cell = find_on_border_cell(first_cell, border_cells, neighbors, feature_ids, type)
	var temp1 = _grid.cells["v"][start_cell]
	#var temp2 = _grid.vertices["c"][v].any(of_different_type)
	
	#var feature_vertices = _grid.cells["v"][start_cell].filter(func(v): return _grid.vertices["c"][v].any(of_different_type))
	var starting_vertex = _grid.cells["v"][start_cell].find(func(v): return _grid.vertices["c"][v].any(of_different_type))
	#var feature_vertices: Array = get_feature_vertices(start_cell, type, feature_ids, of_different_type)
	#var feature_vertices = _path_utils.connect_vertices(feature_ids, type, _grid.vertices, starting_vertex, false)
	#var feature_vertices = 1
	#starting_vertex = -1  # Default to -1 (no match found)
#
	for v in _grid.cells["v"][start_cell]:  # Iterate over each vertex in the cell
		for item in _grid.vertices["c"][v]:  # Iterate over elements in vertices.c[v]
			var temp4 = of_different_type.call(item)
			if of_different_type.call(item):  # Check condition
				starting_vertex = v  # Store the first matching vertex
				break  # Exit inner loop
		if starting_vertex != -1:
			break  # Exit outer loop once a match is found
	
	var feature_vertices = _path_utils.connect_vertices(feature_ids, type, _grid.vertices, starting_vertex, false)
	return[start_cell, feature_vertices]

func get_cells_data(feature_type: String, first_cell: int, feature_ids: Array, border_cells: Array, neighbors) -> Array:
	if feature_type == "ocean":
		return [first_cell, []]
	var type_val = feature_ids[first_cell]
	var start_cell = find_on_border_cell(first_cell, border_cells, neighbors, feature_ids, type_val)
	var feature_vertices = get_feature_vertices(start_cell, feature_ids, type_val)

	
	return [start_cell, feature_vertices]

	

		


## Returns the type (an int) of a given cell.
## Replaces javascript: "const getType = cellId => featureIds[cellId];"
#func get_type(cell_id: int, feature_ids) -> int:
	#return feature_ids[cell_id]
#
## Checks if a cell has the same type as the given target type.
## Replaces javascript function: "const ofSameType = cellId => getType(cellId) === type;"
#func of_same_type(cell_id: int, target_type: int, feature_ids) -> bool:
	#return get_type(cell_id, feature_ids) == target_type
#
## Replaces javascript function: "const ofDifferentType = cellId => getType(cellId) !== type;"
#func of_different_type(cell_id: int, target_type: int, feature_ids) -> bool:
	#return get_type(cell_id, feature_ids) != target_type	

#func find_on_border_cell(first_cell: int, type: int, feature_ids) -> int:
	## If the first cell is on the border, return it.
	#if is_on_border(first_cell, type, feature_ids):
		#return first_cell
	## Otherwise, iterate over all cells in grid.i
	#for start_cell in _grid.i:
		#if get_type(start_cell, feature_ids) == type and is_on_border(start_cell, type, feature_ids):
			#return start_cell
	#push_error("Markup: firstCell %d is not on the feature or map border" % first_cell)
	#return -1	
	
func find_on_border_cell(first_cell: int, border_cells: Array, neighbors, feature_ids: Array, type_val: int) -> int:
	if is_cell_on_border(first_cell, border_cells, neighbors, feature_ids, type_val):
		return first_cell
	for cell_id in _grid.i:
		if feature_ids[cell_id] == type_val and is_cell_on_border(cell_id, border_cells, neighbors, feature_ids, type_val):
			return cell_id
	push_error("Markup: firstCell %s is not on the feature or map border" % str(first_cell))
	return first_cell  # Fallback.
		
#func is_on_border(cell_id: int, type: int, feature_ids) -> bool:
	## A cell is on the border if it is flagged in border_cells...
	#if _border_cells[cell_id]:
		#return true
	## ...or if any of its neighbors is of a different type.
	#for neighbor in _neighbors[cell_id]:
		#if get_type(neighbor, feature_ids) != type:
			#return true
	#return false
func is_cell_on_border(cell_id: int, border_cells: Array, neighbors, feature_ids: Array, type_val: int) -> bool:
	if border_cells[cell_id]:
		return true
	for nb in neighbors[cell_id]:
		if feature_ids[nb] != type_val:
			return true
	return false
		
func define_haven(cell_id, _neighbors, _haven, _harbor):
	# GSimpler version
	#var water_cells: Array = []
	#for neighbor_id in _neighbors[cell_id]:
		#if _grid.is_water(neighbor_id):
			#water_cells.append(neighbor_id)
			
	# Get the water cells containing only neighbors of cell_id that satisfy
	# the is_water condition, i.e., height is < 20
	var water_cells = _neighbors[cell_id].filter(_grid.is_water)
	
	#Simpler version
	#var distances: Array = []
	#for water_cell_id in water_cells:
		#distances.append(_grid.dist2(_grid.cells["p"][cell_id], _grid.cells["p"][water_cell_id]))
	
	# Get the distances for each neigbor cell in a water cell
	var distances = water_cells.map(func(neib_cell_id):
		return _grid.dist2(_grid.cells["p"][cell_id], _grid.cells["p"][neib_cell_id]))
	# Simpler version.
	#var minimum_distance = distances.min()
	#var closest = distances.find(minimum_distance)
	# Get the index (closest) of the first occurance of the minimum value in the array "distance"
	var closest = distances.find(distances.min())
	# Set the haven to be the water cell with the smallest distance.
	_haven[cell_id] = water_cells[closest]
	# Store the number of water neighbors.
	_harbor[cell_id] = water_cells.size()

#func get_feature_vertices(start_cell, feature_type, _feature_ids):
	#var starting_vertex = null
	#
	#
	## Iterate through each vertex in cells.v[start_cell]
	#for v in _grid.cells["v"][start_cell]:
		## Check if any neighbor cell in vertices.c[v] satisfies of_different_type.
		## This mimics JavaScript's .find() combined with .some().
		#var test = of_different_type.call(1)
		##if _grid.vertices["c"][v].filter(of_different_type.call(1)).size() > 0: # DEBUG:AH
		#var temp = _grid.vertices["c"][v]
		##if _grid.vertices["c"][v].filter(test).size() > 0: # DEBUG:AH	
		#if temp.filter(of_different_type.call(v)).size() > 0:
			#starting_vertex = v
			#break
#
	#if starting_vertex == null:
		#push_error("Markup: startingVertex for cell " + str(start_cell) + " is not found")
		#return []
		#
	#return _path_utils.connect_vertices(_feature_ids, feature_type, _grid.vertices["c"], starting_vertex, false)

func get_feature_vertices(start_cell: int, feature_ids: Array, type_val: int) -> Array:
	var type_value = feature_ids[start_cell]  # Get the type of the first cell
	var starting_vertex = -1
	for v in _grid.cells["v"][start_cell]:
		var found_different = false
		for cell_val in _grid.vertices["c"][v]:
			if feature_ids[cell_val] != type_value:
				found_different = true
				break
		if found_different:
			starting_vertex = v
			break
	if starting_vertex == -1:
		push_error("Markup: startingVertex for cell %s is not found" % str(start_cell))
		return []
	# Call to connect_vertices() now passes the required parameters instead of a lambda.
	return _path_utils.connect_vertices(feature_ids, type_val, _grid.vertices, starting_vertex, false)

	
func specify(grid):
	
	#for feature in _features:
	for feature in grid.pack["features"]:
		if !feature || feature.type == "ocean":
			continue
		feature["group"] = define_group(feature)
		
		if feature.type == "lake":
			# NOTE: Lakes has yet to be defined, so put in some fake data
			#feature.height = Lakes.getHeight(feature)
			#feature.name = Lakes.getName(feature)
			feature.height = 10
			feature.name = "lake"

func define_group(feature):
	if (feature.type == "island"):
		return define_island_group(feature)
	if (feature.type == "ocean"):
		return define_ocean_group(feature)
	if (feature.type == "lake"):
		return define_lake_group(feature)
		
	push_error("Markup: unknown feature type", feature.type)	
	
func define_ocean_group(feature):
	var grid_cells_number = _grid.i.size()
	var OCEAN_MIN_SIZE = grid_cells_number / 25;
	var SEA_MIN_SIZE = grid_cells_number / 1000;
	if (feature.cells > OCEAN_MIN_SIZE):
		return "ocean"
	if (feature.cells > SEA_MIN_SIZE):
		return "sea"
	
	return "gulf"
		
func define_island_group(feature):
	var grid_cells_number = _grid.i.size()	
	var CONTINENT_MIN_SIZE = grid_cells_number / 10;
	var ISLAND_MIN_SIZE = grid_cells_number / 1000;
	
	var temp3 = feature
	var temp2 = feature["firstCell"]
	var temp1 = _grid.f[feature["firstCell"] - 1]
	var prevFeature = _grid.features[_grid.f[feature["firstCell"] - 1]];
	if (prevFeature && prevFeature.type == "lake"):
		return "lake_island"
	if (feature.cells > CONTINENT_MIN_SIZE):
		return "continent"
	if (feature.cells > ISLAND_MIN_SIZE):
		return "island";
		
	return "isle"
		

func define_lake_group(feature):
	if (feature.temp < -3):
		return "frozen"
	if (feature.height > 60 && feature.cells < 10 && feature.firstCell % 10 == 0):
		return "lava"

	if (!feature.inlets && !feature.outlet):
		if (feature.evaporation > feature.flux * 4):
			return "dry"
		if (feature.cells < 3 && feature.firstCell % 10 == 0):
			return "sinkhole"

	if (!feature.outlet && feature.evaporation > feature.flux):
		return "salt"

	return "freshwater"
	
	
	

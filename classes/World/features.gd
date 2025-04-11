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

var _grid: Grid
# Make a copy of the heights array to use
# FIXME. I need to change the packed arrays back to typed arrays.
# For now, this is a workaround. Array Array ( PackedInt32Array from )
var _heights: Array[int] = []
# The number of cells does not include the boundary points
var _cells_number: int
#var _packed_cells_number: int
var _distance_field: Array[int] = [] 
var _features = []
var _path_utils: PathUtils
var _common_utils: CommonUtils
var _polygon: Polygon

func _init(grid: Grid) -> void:
	_grid = grid
	# FIXME. I need to change the packed arrays back to typed arrays.
	# For now, this is a workaround. Array Array ( PackedInt32Array from )
	# The number of cells does not include the boundary points
	_heights = grid.cells["h"].duplicate()
	_cells_number = grid.points_n
	_distance_field.resize(_cells_number)
	_path_utils = PathUtils.new()
	_common_utils = CommonUtils.new()
	_polygon = Polygon.new()
	
## Mark Grid features (ocean, lakes, islands) and calculate distance field
func markup_grid(grid: Grid) -> void:
	
	var _neighbors: Array = []
	var _border_cells: Array = []
	_neighbors = grid.cells["c"]
	_border_cells = grid.cells["b"]
	# Measure the time it takes to perform this task
	_time_now  = Time.get_ticks_msec()	

	var queue: Array[int] = []
	queue = [0]
	var feature_id: int = 1
	var land: bool
	#var counter: int = 0 # TEMP
	var _feature_ids: Array[int] = []
	_feature_ids.resize(_cells_number)
	_features = [0]
	
	while queue[0] != -1:
		#counter += 1 # TEMP
		var first_cell: int = queue[0]
		_feature_ids[first_cell] = feature_id
		land = true if _heights[first_cell] >= 20 else false
		# set true if feature touches map edge
		var border: bool = false 
		
		while queue.size() > 0:
			# NOTE: In Javascript, array.pop() removes the last element from 
			# an array. The equivalent in gdscript is array.pop_back()
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

		feature_id += 1 
	# Markup deep ocean cells.
	markup(_distance_field, _neighbors,DEEP_WATER, -1, -10)

	# Distance field from water level. 
	# 1, 2, .... - land cells  
	# -1, -2, ... - water cells
	# 0 - unmarked cell
	grid.cells["t"] = _distance_field
	grid.cells["f"] = _feature_ids
	grid.features = _features
	_time_elapsed = Time.get_ticks_msec() - _time_now
	print("markup_grid time: ", _time_elapsed)
	
func markup(distance_field: Array, neighbors: Array, start: int, increment: int, limit: int = INT8_MAX) -> void:
	var distance: int = start
	var marked: float = INF

	while marked > 0 and distance != limit:
		marked = 0
		var prev_distance: int = distance - increment
	
		for cell_id in range(neighbors.size()):
			if distance_field[cell_id] != prev_distance:
				continue

			for neighbor_id in neighbors[cell_id]:
				if distance_field[neighbor_id] != UNMARKED:
					continue
				distance_field[neighbor_id] = distance
				marked += 1
		distance += increment
		
func markup_grid_packed(pack: Pack) -> void:
	# When features was constructed, we only set up the _grid object. Now we 
	# set up the pack object.
	var haven: Array[int] = []
	var harbor: Array[int] = []
	
	var _neighbors: Array = []
	var _border_cells: Array = []
	var _distance_field: Array[int] = []
	var pack_cells_length: int
	# Measure the time it takes to perform this task
	_time_now  = Time.get_ticks_msec()	
	pack_cells_length = pack.cells["i"].size()
	if (pack_cells_length == 0):
		return # no cells. Nothing to do 

	haven.resize(pack_cells_length)
	harbor.resize(pack_cells_length)
	_distance_field.resize(pack_cells_length)
	
	_neighbors = pack.cells["c"]
	_border_cells = pack.cells["b"]

	var queue: Array[int] = []
	queue = [0]
	var feature_id: int = 1
	var land: bool
	var counter: int = 0 # TEMP
	var features: Array[Dictionary] = [] # Array of feature dictionary elements
	var _feature_ids: Array[int] = []
	
	_feature_ids.resize(pack_cells_length)
	while queue[0] != -1:
		counter += 1 # TEMP
		var first_cell: int = queue[0]
		_feature_ids[first_cell] = feature_id
		land = pack.is_land(first_cell)
		# true if feature touches map border
		var border: bool = true if _border_cells[first_cell] == 1 else false
		#  count cells in a feature
		var total_cells: int = 1	
		
		while queue.size() > 0:
			# NOTE: In Javascript, array.pop() rempoves the last element from 
			# an array. The equivalent in gdscript is array.pop_back()
			var cell_id: int = queue.pop_back()

			if _border_cells[cell_id]: 
				border = true;
				
			if not border and _border_cells[cell_id]:
				border = true
			var neib_id: Array = _neighbors[cell_id]
			if neib_id == null:
				continue
			for neighbor_id in _neighbors[cell_id]:
				var is_neib_land: bool
				if  pack.cells["h"][neighbor_id] >= 20:
					is_neib_land = true
					
				if (land == true and is_neib_land == false):
					_distance_field[cell_id] = LAND_COAST
					_distance_field[neighbor_id] = WATER_COAST
					if (haven[cell_id] == 0):
						_define_haven(cell_id, _neighbors, haven, harbor, pack)
				elif (land == true and is_neib_land == true):
					if _distance_field[neighbor_id] == UNMARKED and _distance_field[cell_id] == LAND_COAST:
						_distance_field[neighbor_id] = LANDLOCKED
				elif _distance_field[cell_id] == UNMARKED and _distance_field[neighbor_id] == LAND_COAST:
					_distance_field[cell_id] == LANDLOCKED
				
				if !_feature_ids[neighbor_id] and land == is_neib_land:
					queue.append(neighbor_id)
					_feature_ids[neighbor_id] = feature_id
					total_cells += 1
					
		features.append(_add_feature(first_cell, land, border, feature_id, total_cells, _feature_ids, _border_cells, _neighbors, pack))
		queue.append(_feature_ids.find(UNMARKED))
		if queue == []:
			queue = [0]
		queue[0] = _feature_ids.find(UNMARKED)
		feature_id += 1 
	
	markup(_distance_field, _neighbors,  DEEPER_LAND, 1)
	markup(_distance_field, _neighbors, DEEP_WATER, -1, -10)
	
	pack.cells["t"] = _distance_field
	pack.cells["f"] = _feature_ids
	pack.cells["features"] = features
	pack.features = features
	pack.cells["haven"] = haven
	pack.cells["harbor"] = harbor
	
	print ("Size of grid.t: ", pack.cells["t"].size())
	print ("Size of grid.f: ", pack.cells["f"].size())
	print ("Size of grid.features: ", pack.cells["features"].size())

	_time_elapsed = Time.get_ticks_msec() - _time_now
	print("markup_grid_packed time: ", _time_elapsed)
		

# The following functions are only used for the packed grid via markup_grid_packed()
# They are not used for the features assigned to a grid.
func _add_feature(first_cell: int, land: bool, border: bool, feature_id: int, total_cells: int,  feature_ids: Array,  border_cells, neighbors, pack) -> Dictionary:
	var type_str = ""
	if land:
		type_str = "island"
	elif border:
		type_str = "ocean"
	else:
		type_str = "lake"
	
	# Get the starting cell and the list of feature vertices.
	var cells_data = _get_cells_data(type_str, first_cell, feature_ids,border_cells, neighbors, pack)
	var start_cell = cells_data[0]
	var feature_vertices = cells_data[1]
	
	# Map feature vertices to points and clip the polygon.
	var points: Array
	for vertex in feature_vertices:
		var temp1 = pack.vertices["p"][vertex]
		points.append(pack.vertices["p"][vertex])
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
			feature["vertices"].reverse()
		var shoreline = []
		for vertex in feature["vertices"]:
			var filtered = []
			for cell_val in  pack.vertices["c"][vertex]:
				if pack.is_land(cell_val):
					filtered.append(cell_val)
			shoreline += filtered
		feature["shoreline"] = _common_utils.unique(shoreline)
		# PLACEHOLDER
		#feature["height"] = Lakes.get_height(feature)
	
	return feature	
	

func _get_cells_data(feature_type: String, first_cell: int, feature_ids: Array, border_cells: Array, neighbors, pack) -> Array:
	
	if feature_type == "ocean":
		return [first_cell, []]

	var get_type = func (cell_id: int, feature_ids): 
		if cell_id < 0 or cell_id >= feature_ids.size():
			return null
		return feature_ids[cell_id]
	var type = get_type.call(first_cell, feature_ids)
	var of_same_type = func (cell_id: int):
		get_type.call(cell_id, feature_ids) == type
	var of_different_type = func (cell_id: int):
		return get_type.call(cell_id, feature_ids) != type
	var start_cell: int = _find_on_border_cell(first_cell, border_cells, neighbors, feature_ids, type, pack)
	

	var starting_vertex: int = -1  # Default value in case no valid vertex is found

	for v in pack.cells["v"][start_cell]: 
		for item in pack.vertices["c"][v]:  
			if of_different_type.call(item): 
				starting_vertex = v  
				break  
		if starting_vertex != -1:
			break  

	var feature_vertices: Array = _path_utils.connect_vertices(feature_ids, type, pack.vertices, starting_vertex, false)

	return[start_cell, feature_vertices]
	
func _find_on_border_cell(first_cell: int, border_cells: Array, neighbors: Array, feature_ids: Array, type_val: int, pack) -> int:
	if _is_cell_on_border(first_cell, border_cells, neighbors, feature_ids, type_val):
		return first_cell
		
	for cell_id in pack.cells["i"]:
		if feature_ids[cell_id] == type_val and _is_cell_on_border(cell_id, border_cells, neighbors, feature_ids, type_val):
			return cell_id
	push_error("Markup: firstCell %s is not on the feature or map border" % str(first_cell))
	return first_cell  # Fallback.
		
## Check to see if a cell is a border cell
func _is_cell_on_border(cell_id: int, border_cells: Array, neighbors: Array, feature_ids: Array, type_val: int) -> bool:
	# A cell is on the border if it is flagged in border_cells
	if border_cells[cell_id]:
		return true
	# or if any of its neighbors is of a different type.
	for nighbour_cell in neighbors[cell_id]:
		if feature_ids[nighbour_cell] != type_val:
			return true
	return false
	
## Check to see if we have a haven or harbor
func _define_haven(cell_id: int, neighbors: Array, haven: Array, harbor: Array, pack: Pack) -> void:
	var water_cells: Array = neighbors[cell_id].filter(func(i): return pack.cells["h"][i])
	# Get the distances for each neigbor cell in a water cell
	var distances: Array = water_cells.map(func(neigbour_cell_id):
		return _grid.dist2(pack.cells["p"][cell_id], pack.cells["p"][neigbour_cell_id]))
	var closest: int = distances.find(distances.min())
	# Set the haven to be the water cell with the smallest distance.
	haven[cell_id] = water_cells[closest]
	# Store the number of water neighbors.
	harbor[cell_id] = water_cells.size()	

# NOTE: This code is not currently being used. This code would normally be used
# by _get_cells_data. For now, there is embeded code in _get_cells_data. This
# code is different. FIXME: Need to determine which one I will keep.
func _get_feature_vertices(start_cell: int, feature_ids: Array, type_val: int) -> Array:
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

	
# Add properties to pack features
func specify(grid: Grid, pack: Pack) -> void:
	
	for feature in pack["features"]:
		if !feature || feature["type"] == "ocean":
			continue
		feature["group"] = _define_group(feature, pack)
		
		if feature["type"] == "lake":
			# NOTE: Lakes has yet to be defined, so put in some fake data
			#feature.height = Lakes.getHeight(feature)
			#feature.name = Lakes.getName(feature)
			feature["height"] = 10
			feature["name"] = "lake"

## Define the group that the feature belongs to. 
func _define_group(feature: Dictionary, pack: Pack) -> String:
	var f_type = feature["type"]
	if (feature["type"] == "island"):
		var type_i = _define_island_group(feature, pack)
		return _define_island_group(feature, pack)
	if (feature["type"] == "ocean"):
		var type_o = _define_ocean_group(feature)
		return _define_ocean_group(feature)
		
	return "freshwater" # WORKAROUND till  the lake code is put in
	# Lakes not yet implemented
	#if (feature["type"] == "lake"):
		#return _define_lake_group(feature)
	push_error("Markup: unknown feature type", feature.type)	

## Returns the type of oscean. An ociean can be one of:
## "ocean", "sea", or "gulf".
func _define_ocean_group(feature: Dictionary) -> String:
	var grid_cells_number = _grid.cells["i"].size()	
	var OCEAN_MIN_SIZE = grid_cells_number / 25;
	var SEA_MIN_SIZE = grid_cells_number / 1000;
	if (feature["cells"] > OCEAN_MIN_SIZE):
		return "ocean"
	if (feature["cells"]  > SEA_MIN_SIZE):
		return "sea"
	
	return "gulf"

## Returns the type of 	island. An island can be one of:
## "lake_island", "continent", "island" "isle"
func _define_island_group(feature: Dictionary, pack:Pack) -> String:
	var grid_cells_number = _grid.cells["i"].size()	
	var CONTINENT_MIN_SIZE = grid_cells_number / 10;
	var ISLAND_MIN_SIZE = grid_cells_number / 1000;
	var prevFeature = pack.features[pack.cells["f"][feature["firstCell"] - 1]];
	
	if (prevFeature && prevFeature["type"] == "lake"):
		return "lake_island"
	if (feature["cells"] > CONTINENT_MIN_SIZE):
		return "continent"
	if (feature["cells"] > ISLAND_MIN_SIZE):
		return "island";
		
	return "isle"
		

# Lakes are not yet implemented, so this code cannot yet be used. Fix it
# when lakes are implemented.
#func _define_lake_group(feature: Dictionary) -> String:
	#if (feature.cells["temp"] < -3):
		#return "frozen"
	#if (feature["height"] > 60 && feature.cells < 10 && feature.firstCell % 10 == 0):
		#return "lava"
#
	#if (!feature.inlets && !feature.outlet):
		#if (feature.evaporation > feature.flux * 4):
			#return "dry"
		#if (feature.cells < 3 && feature.firstCell % 10 == 0):
			#return "sinkhole"
#
	#if (!feature.outlet && feature.evaporation > feature.flux):
		#return "salt"
#
	#return "freshwater"
	
	

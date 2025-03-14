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
var _pack
# Make a copy of the heights array to use
#var heights: Array[int] = grid.heights.duplicate()
# FIXME. I need to change the packed arrays back to typed arrays.
# For now, this is a workaround. Array Array ( PackedInt32Array from )
var _heights: Array[int] = []
# The number of cells does not include the boundary points
var _cells_number: int
var _packed_cells_number: int
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
	
func _init(grid: Grid, pack: Pack):
	_grid = grid
	_pack = pack
		# Make a copy of the heights array to use
	#var heights: Array[int] = grid.heights.duplicate()
	# FIXME. I need to change the packed arrays back to typed arrays.
	# For now, this is a workaround. Array Array ( PackedInt32Array from )
	#var heights := Array(grid.heights)
	# The number of cells does not include the boundary points
	#_heights = grid.heights.duplicate()
	_heights = grid.cells["h"].duplicate()
	
	#var cells_number: int = grid.points_n
	#_cells_number = grid.i.size()
	#_cells_number = grid.cells["i"].size()
	_cells_number = grid.points_n
	#_packed_cells_number = pack.points_n
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
	_features = [0]
	
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
	#grid.t = _distance_field
	grid.cells["t"] = _distance_field
# indexes of the features
	#grid.f = _feature_ids
	grid.cells["f"] = _feature_ids
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
		


	

	

	
	
	

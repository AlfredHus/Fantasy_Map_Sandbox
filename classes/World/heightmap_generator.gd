class_name HeightMapGenerator
extends Node

const HeightmapTemplates := preload("res://classes/World/heightmap_templates.gd")


var heightmap: HeightmapTemplates

var grid: Grid

var heights: PackedInt32Array


func _init(grid: Grid):
	# Code used for testing for now. Should move to a unit test at some point
	heightmap= HeightmapTemplates.new()
	self.grid = grid
	heights.resize(grid.points.size()) # points are the grid points that were calculated
	#print(heightmap.heightmap_templates["volcano"]["template"]) # prints the volcano template string
	#print(heightmap.heightmap_templates["shattered"]["probability"]) # prints the probability of the shattered template

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func generate():
	pass
	
	
func add_step(tool, a2, a3, a4, a5):
	if (tool == "Hill"): return add_hill(a2, a3, a4, a5)
	#if (tool == "Pit"): return addPit(a2, a3, a4, a5)
	#if (tool == "Range"): return addRange(a2, a3, a4, a5)
	#if (tool == "Trough"): return addTrough(a2, a3, a4, a5)
	#if (tool == "Strait"): return addStrait(a2, a3)
	#if (tool == "Mask"): return mask(a2)
	#if (tool == "Invert"): return invert(a2, a3)
	#if (tool == "Add"): return modify(a3, +a2, 1)
	#if (tool == "Multiply"): return modify(a3, 0, +a2)
	#if (tool == "Smooth"): return smooth(a2);
  
func add_hill(count: String, height: String, range_x: String, range_y: String):
	var counter = ProbabilityUtilities.get_number_in_range(count)
	while counter > 0:
		add_one_hill(height, range_x, range_y)
		counter -= 1
		
func add_one_hill(height: String, range_x: String, range_y: String):
	var change:= PackedByteArray()
	var limit: int = 0
	var start
	var h: float
	
	h = clamp(ProbabilityUtilities.get_number_in_range(height), 1, 100)
	change.resize(heights.size())
	
		# Find a valid starting cell
	while true:
		var x = get_point_in_range(range_x, grid.width)
		var y = get_point_in_range(range_y, grid.height)
		start = grid.find_grid_cell(x, y)
		if heights[start] + h <= 90 or limit >= 50:
			break
		limit += 1
		
	# Initialize the height change
	change[start] = h
	var queue = [start]
	
# Process cells using a queue
	while queue.size() > 0:
		var q = queue.pop_front()

		#for c in grid.cells.c[q]:
			#if change[c] > 0:
				#continue
			#change[c] = pow(change[q], blob_power) * (randf() * 0.2 + 0.9)
			#if change[c] > 1:
				#queue.append(c)
#
	## Update heights with the changes
	#for i in heights.size():
		#heights[i] = lim(heights[i] + change[i])	
		
		
		
		
func get_point_in_range(range: String, length: float) -> float:
	if typeof(range) != TYPE_STRING:
		print("Range should be a string")
		return 0.0

	var split_range: PackedStringArray = range.split("-")
	var min: float = (float(split_range[0]) / 100.0) if split_range.size() > 0 else 0
	var max: float = (float(split_range[1]) / 100.0) if split_range.size() > 1 else min
	return randf_range(min * length, max * length)
	

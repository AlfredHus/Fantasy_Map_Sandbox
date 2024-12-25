class_name Grid
extends Node


var spacing: float
var cells_desired: int
var cells_x: int
var cells_y: int
var points: PackedVector2Array
var boundary_points: PackedVector2Array
var area: Rect2
var width: int
var height: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
# Create a  grid of random points
func _init(cells_desired: int, area: Rect2):
	self.cells_desired = cells_desired
	self.area = area
	width = self.area.size.x
	height = self.area.size.y
	#spacing = roundf(sqrt((area.size.x * area.size.y) / cells_desired))
	# snapped() is used to set the decimal places of the float value to 2
	spacing = snappedf(sqrt((width * height) / cells_desired),0.01)
	boundary_points = add_boundary_points(self.area, spacing)
	points =  get_jittered_grid(self.area, spacing)
	cells_x = floor((width + 0.5 * spacing - 1e-10) / spacing)
	cells_y = floor((height + 0.5 * spacing - 1e-10) / spacing)
	
	
	
# Add points along map edge to pseudo-clip voronoi cells
# TODO: This is a duplicate of a function poissonDiscSampling. Need to address
# this at some point. For now, will just duplicate it and figure out 
# where to put it later
# URL: https://github.com/Azgaar/Fantasy-Map-Generator/blob/23f36c3210d583c32760ddde3c5e6c65ecc8ab52/utils/graphUtils.js
func add_boundary_points(area: Rect2, spacing: float) -> PackedVector2Array:
	var offset: int = roundi(-1 * spacing)
	var b_spacing: int = spacing * 2
	var boundary: PackedVector2Array
	var width: int = area.size.x - offset * 2
	var height: int = area.size.y- offset * 2
	var number_x: int = int(ceil(width / b_spacing)) - 1
	var number_y: int = int(ceil(height / b_spacing)) - 1

	for i in range(0.5, number_x):
		var x: int = int(ceil((width * i) / number_x + offset))
		boundary.append(Vector2(x, offset))
		boundary.append(Vector2(x, height + offset))

	for i in range(0.5, number_y):
		var y: int = int(ceil((height * i) / number_y + offset))
		boundary.append(Vector2(offset, y))
		boundary.append(Vector2(width + offset, y))

	return boundary		
	
# Gets points on a regular square grid and jitters. Does the same thing as 
# Possion Disk Sampling. The main diference is you can set the points to be 
# put ont the rectangle rather than having the Possion dediding on the number 
# of points.
func get_jittered_grid(area: Rect2, spacing) -> PackedVector2Array:
	var radius: float = spacing / 2.0 # square radius
	var jittering: float = radius * 0.9; # max deviation
	var double_jittering: float = jittering * 2.0
		
	var points: PackedVector2Array
	for y in range(radius, area.size.y, spacing):
		for x in range(int(radius), area.size.x, spacing):
			var xj = min(round(x + (randf() * double_jittering - jittering)), area.size.x)
			var yj = min(round(y + (randf() * double_jittering - jittering)), area.size.y)
			points.append(Vector2(xj, yj))
	return points
	
# Return cell index on a regular square grid
func find_grid_cell(x: int, y:int):
	return floor(min(y / spacing, cells_y - 1)) * cells_x + floor(min(x / spacing, cells_x - 1))


	


	
	
	

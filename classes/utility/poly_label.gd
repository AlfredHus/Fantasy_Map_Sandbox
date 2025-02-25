#
# Port of https://github.com/eqmiller/polylabel-csharp/tree/main
# https://github.com/eqmiller/polylabel-csharp/blob/main/src/Polylabel-CSharp/Polylabel.cs
#
# For a detailed explanation on how this all works:
# https://github.com/mapbox/polylabel/tree/master
#
# Given polygon coordinates in GeoJSON-like format 
# (an array of arrays of [x, y] points) and precision (1.0 by default), 
# Polylabel returns the pole of inaccessibility coordinate in [x, y] format. 
# The distance to the closest polygon point (in input units) is included as a 
# distance property.
#
class_name PolyLabel
extends Node

#const Cells := preload("res://classes/utility/cell.gd")

var distance

func custom_compare(a: int, b: int) -> int:
	return b - a

# Finds the polygon pole of inaccessibility
func get_polylabel(polygon: Array, precision: float = 1.0, debug: bool = false) -> Array:
	# Generate initial square cells that fully cover the polygon (with cell size
	# equal to either width or height, whichever is lower
	var min_x: float = polygon[0].map(func(p): return p[0]).min()
	var min_y: float = polygon[0].map(func(p): return p[1]).min()
	var max_x: float = polygon[0].map(func(p): return p[0]).max()
	var max_y: float = polygon[0].map(func(p): return p[1]).max()

	var width = max_x - min_x
	var height = max_y - min_y
	# Cell size equal to either width or height, whichever is lower
	var cell_size = min(width, height)
	var h = cell_size / 2
	


	if cell_size == 0:
		return [min_x, min_y]

	# Priority queue of cells ordered by their "potential"
	# Put the clls into a priority queue sorted by the maximum potential
	# distance  from a point inside a cell, defined as a sum of the 
	# distance from the center and the cell radius (equal to
	# cell_size * sqrt(20 / 2)
	var cell_queue = TinyQueue.new([], Callable(self, "custom_compare"))
	# For future reference, range only returns an integer value, so if 
	# cell_size is < 1.0F, then range will return 0, which results in 
	# a "Step argument is zero" error. TO fix this problem, use a while 
	# statement. TODO: Check elsewhere where this might be a problem
	#for x in range(min_x, max_x, cell_size):
		#for y in range(min_y, max_y, cell_size):
			#cell_queue.push(Cell.new(x + h, y + h, h, polygon))
	var x = min_x
	while x < max_x:
		var y = min_y
		while y < max_y:
			cell_queue.push(Cell.new(x + h, y + h, h, polygon))
			y += cell_size
		x += cell_size		
	

	# Use centroid as the initial guess
	# Calculate the dinstance from the centroid of the ploygon and pick it as
	# the first "best so far"
	var best_cell = get_centroid_cell(polygon)

	# Special case for rectangular polygons
	var bbox_cell = Cell.new(min_x + width / 2, min_y + height / 2, 0, polygon)
	if bbox_cell.d > best_cell.d:
		best_cell = bbox_cell

	var num_probes = cell_queue.length
	# Pull out cells from the priority queue one by one. If the cell's distance
	# is better than the current bestm save it.
	while cell_queue.length > 0:
		var cell = cell_queue.pop()

		# Update the best cell if a better one is found
		if cell.d > best_cell.d:
			best_cell = cell
			if debug:
				print("Found better cell with distance ", round(cell.d), " after ", num_probes, " probes.")

		# Stop if further refinement won't improve precision
		# If the cell potentially contains a better solution than the
		# current best (cell_max - best_dist > precision, split it into 
		# 4 childrencells and put them into the queue.
		if cell.max - best_cell.d <= precision:
			continue

		# Split the cell into four smaller cells
		h = cell.h / 2
		cell_queue.push(Cell.new(cell.x - h, cell.y - h, h, polygon))
		cell_queue.push(Cell.new(cell.x + h, cell.y - h, h, polygon))
		cell_queue.push(Cell.new(cell.x - h, cell.y + h, h, polygon))
		cell_queue.push(Cell.new(cell.x + h, cell.y + h, h, polygon))
		num_probes += 4

	if debug:
		print("Number of probes: ", num_probes)
		print("Best distance: ", best_cell.d)
	
	distance = best_cell.d
	return [best_cell.x, best_cell.y]

# Calculates the centroid of a polygon
func get_centroid_cell(polygon: Array) -> Cell:
	var area = 0.0
	var x = 0.0
	var y = 0.0
	var points = polygon[0]

	var len = points.size()
	var j = len - 1
	for i in range(len):
		var a = points[i]
		var b = points[j]
		var f = a[0] * b[1] - b[0] * a[1]
		x += (a[0] + b[0]) * f
		y += (a[1] + b[1]) * f
		area += f * 3
		j = i
	if area == 0:
		return Cell.new(points[0][0], points[0][1], 0, polygon)
	return Cell.new(x / area, y / area, 0, polygon)

class_name PoissonDiscSampling
#source: https://github.com/stephanbogner/godot-poisson-sampling

# The points created by the poisson disk sampling. 
var points = []
# The boundary points for pesudo-clipping.
var boundary_points: PackedVector2Array

# radius - minimum distance between points
# region_shape - takes any of the following:
# 		-a Rect2 for rectangular region
#		-an array of Vector2 for polygon region
#		-a Vector3 with x,y as the position and z as the radius of the circle
# retries - maximum number of attempts to look around a sample point, reduce this value to speed up generation
# start_pos - optional parameter specifying the starting point
# returns an Array of Vector2D with points in the order of their discovery
func generate_points(radius: float, region_shape, retries:int = 30, start_pos := Vector2(INF, INF)) -> Array:
	randomize()
	
	# If no special start position is defined, pick one
	if start_pos.x == INF:
		start_pos = __get_default_start_position(region_shape)
	
	var region_bbox = __get_region_bbox(region_shape)
	var cols_and_rows = __get_cols_and_rows(region_bbox, __get_cell_size(radius))
	var cell_size_scaled = __get_cell_size_scaled(region_bbox, cols_and_rows.cols, cols_and_rows.rows)
	# use tranpose to map points starting from origin to calculate grid position
	var transpose = __get_transpose(region_bbox)
	var grid = __get_grid(cols_and_rows.cols, cols_and_rows.rows)
	

	var radii = []
	
	var spawn_points = []
	spawn_points.append(start_pos)
	while spawn_points.size() > 0:
		var spawn_index: int = randi() % spawn_points.size()
		var spawn_centre: Vector2 = spawn_points[spawn_index]
		var sample_accepted: bool = false
		for i in retries:
			var angle: float = 2 * PI * randf()
			var sample: Vector2 = spawn_centre + Vector2(cos(angle), sin(angle)) * (radius + radius * randf())
			if __is_valid_sample(sample, radius, points, radii, region_shape, region_bbox, grid, cols_and_rows.cols, cols_and_rows.rows, transpose, cell_size_scaled):
				grid[int((transpose.x + sample.x) / cell_size_scaled.x)][int((transpose.y + sample.y) / cell_size_scaled.y)] = points.size()
				points.append(sample)
				radii.append(radius)
				spawn_points.append(sample)
				sample_accepted = true
				break
		if not sample_accepted:
			spawn_points.remove_at(spawn_index)
	return points

func generate_points_on_image(min_radius:float, max_radius:float, image_texture_resource:CompressedTexture2D, region_shape, scale_reference_image := Vector2(1,1), retries: int = 30, start_pos := Vector2(INF, INF)):
	randomize()
	
	# If no special start position is defined, pick one
	if start_pos.x == INF:
		start_pos = __get_default_start_position(region_shape)
	
	#var image:Image = image_texture_resource.get_data()
	var image: Image = image_texture_resource.get_image()
	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	var region_bbox = __get_region_bbox(region_shape)
	var cols_and_rows = __get_cols_and_rows(region_bbox, __get_cell_size(min_radius))
	var cell_size_scaled = __get_cell_size_scaled(region_bbox, cols_and_rows.cols, cols_and_rows.rows)
	# use tranpose to map points starting from origin to calculate grid position
	var transpose = __get_transpose(region_bbox)
	var grid = __get_grid(cols_and_rows.cols, cols_and_rows.rows)
	
	var points = []
	var radii = []
	
	var spawn_points = []
	spawn_points.append(start_pos)
	while spawn_points.size() > 0:
		var spawn_index: int = randi() % spawn_points.size()
		var spawn_centre: Vector2 = spawn_points[spawn_index]
		var sample_accepted: bool = false
		for i in retries:
			var angle: float = 2 * PI * randf()
			var brightness: float = __get_brightness_of_pixel_at(image, spawn_centre * scale_reference_image)
			var radius: float = __map(brightness, 0, 1, min_radius, max_radius)
			var sample: Vector2 = spawn_centre + Vector2(cos(angle), sin(angle)) * (radius + radius * randf())
			if __is_valid_sample(sample, radius, points, radii, region_shape, region_bbox, grid, cols_and_rows.cols, cols_and_rows.rows, transpose, cell_size_scaled):
				grid[int((transpose.x + sample.x) / cell_size_scaled.x)][int((transpose.y + sample.y) / cell_size_scaled.y)] = points.size()
				points.append(sample)
				radii.append(radius)
				spawn_points.append(sample)
				sample_accepted = true
				break
		if not sample_accepted:
			spawn_points.remove_at(spawn_index)
	
	return {
		"points": points,
		"radii": radii
	}

func __is_valid_sample(sample: Vector2, sample_radius:float, points:Array, radii:Array, region_shape, region_bbox, grid, cols, rows, transpose, cell_size_scaled) -> bool:
	if __is_point_in_region(sample, region_shape, region_bbox):
		var cell := Vector2(int((transpose.x + sample.x) / cell_size_scaled.x), int((transpose.y + sample.y) / cell_size_scaled.y))
		var cell_search_radius:int = 2
		var cell_start := Vector2(max(0, cell.x - cell_search_radius), max(0, cell.y - cell_search_radius))
		var cell_end := Vector2(min(cell.x + cell_search_radius, cols - 1), min(cell.y + cell_search_radius, rows - 1))
	
		for i in range(cell_start.x, cell_end.x + 1):
			for j in range(cell_start.y, cell_end.y + 1):
				var search_index: int = grid[i][j]
				if search_index != -1:
					var dist: float = points[search_index].distance_to(sample)
					var min_distance:float = (radii[search_index] + sample_radius) / 2
					if dist < min_distance:
						return false
		return true
	return false


func __is_point_in_region(sample: Vector2, region_shape, region_bbox) -> bool:
	if region_bbox.has_point(sample):
		match typeof(region_shape):
			TYPE_RECT2:
				return true
			TYPE_PACKED_VECTOR2_ARRAY, TYPE_ARRAY:
				if Geometry2D.is_point_in_polygon(sample, region_shape):
					return true
			TYPE_VECTOR3:
				if Geometry2D.is_point_in_circle(sample, Vector2(region_shape.x, region_shape.y), region_shape.z):
					return true
			_:
				return false
	return false

func __get_default_start_position(region_shape):
	match typeof(region_shape):
		TYPE_RECT2:
			return Vector2(
				region_shape.position.x + region_shape.size.x * randf(),
				region_shape.position.y + region_shape.size.y * randf()
			)
		
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_ARRAY:
			var n: int = region_shape.size()
			var i: int = randi() % n
			return region_shape[i] + (region_shape[(i + 1) % n] - region_shape[i]) * randf()
		
		TYPE_VECTOR3:
			var angle: float = 2 * PI * randf()
			
			
			
			return Vector2(region_shape.x, region_shape.y) + Vector2(cos(angle), sin(angle)) * region_shape.z * randf()
	
		_:
			return Vector2.ZERO

func __get_region_bbox(region_shape):
	match typeof(region_shape):
		TYPE_RECT2:
			return region_shape
	
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_ARRAY:
			var start: Vector2 = region_shape[0]
			var end: Vector2 = region_shape[0]
			for i in range(1, region_shape.size()):
				start.x = min(start.x, region_shape[i].x)
				start.y = min(start.y, region_shape[i].y)
				end.x = max(end.x, region_shape[i].x)
				end.y = max(end.y, region_shape[i].y)
			return Rect2(start, end - start)
		
		TYPE_VECTOR3:
			var x = region_shape.x
			var y = region_shape.y
			var r = region_shape.z
			return Rect2(x - r, y - r, r * 2, r * 2)

		_:
			push_error("Unrecognized shape!!! Please input a valid shape")
			return Rect2(0, 0, 0, 0)

func __get_cell_size(radius):
	return radius / sqrt(2)

func __get_cols_and_rows(region_bbox, cell_size):
	return {
		"cols": max(floor(region_bbox.size.x / cell_size), 1),
		"rows": max(floor(region_bbox.size.y / cell_size), 1)
	}

func __get_cell_size_scaled(region_bbox, cols, rows) -> Vector2:
	return Vector2(
		region_bbox.size.x / cols,
		region_bbox.size.y / rows
	)

func __get_transpose(region_bbox):
	return -region_bbox.position

func __get_grid(cols, rows):
	var grid = []
	for i in cols:
		grid.append([])
		for j in rows:
			grid[i].append(-1)
	return grid

func __get_brightness_of_pixel_at(image:Image, position:Vector2) -> float:
	var pixel_position := Vector2( round(position.x), round(position.y) )
	if pixel_position.x >= image.get_size().x || pixel_position.y >= image.get_size().y:
		return 0.0
	var pixel_data = image.get_pixelv(pixel_position)
	return (pixel_data[0] + pixel_data[1] + pixel_data[2]) / 3.0

# Re-maps a number from one range to another.
# For example, calling map(2, 0, 10, 0, 100) returns 20. The first three arguments set the 
# original value to 2 and the original range from 0 to 10. The last two arguments set the 
# target range from 0 to 100. 20's position in the target range [0, 100] is proportional 
# to 2's position in the original range [0, 10].

# The sixth parameter, withinBounds, is optional. By default, map() can return values 
# outside of the target range. For example, map(11, 0, 10, 0, 100) returns 110. 
# Passing true as the sixth parameter constrains the remapped value to the target range. 
# For example, map(11, 0, 10, 0, 100, true) returns 100.
# Parameters
# value	Number:the value to be remapped.	
# from_start: Number:	lower bound of the value's current range.
# from_end  Number:upper bound of the value's current range.
# to_start	Number: lower bound of the value's target range.
# to_end: Number: upper bound of the value's target range.
func __map(value:float, from_start:float = 0, from_end:float = 1, to_start:float = 0, to_end:float = 1):
	# Ported from p5 https://github.com/processing/p5.js/blob/eef4ce6747bef887ecfb2f1112acec07fc944687/src/math/calculation.js#L448
	return (value - from_start) / (from_end - from_start) * (to_end - to_start) + to_start
	
	
###################################################################################################
#################### Code Added to the original ###################################################
###################################################################################################
# Add points along map edge to pseudo-clip voronoi cells
# URL: https://github.com/Azgaar/Fantasy-Map-Generator/blob/23f36c3210d583c32760ddde3c5e6c65ecc8ab52/utils/graphUtils.js
func add_boundary_points(area: Rect2, spacing: float) -> PackedVector2Array:
	var offset: int = roundi(-1 * spacing)
	var b_spacing: int = spacing * 2
 
	var width: int = area.size.x - offset * 2
	var height: int = area.size.y- offset * 2
	var number_x: int = int(ceil(width / b_spacing)) - 1
	var number_y: int = int(ceil(height / b_spacing)) - 1

	for i in range(0.5, number_x):
		var x: int = int(ceil((width * i) / number_x + offset))
		boundary_points.append(Vector2(x, offset))
		boundary_points.append(Vector2(x, height + offset))

	for i in range(0.5, number_y):
		var y: int = int(ceil((height * i) / number_y + offset))
		boundary_points.append(Vector2(offset, y))
		boundary_points.append(Vector2(width + offset, y))

	return boundary_points		

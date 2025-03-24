extends GutTest

#const Delaunator := preload("res://classes/geometry/delaunator.gd")
#const Voronoi := preload("res://classes/geometry/voronoi.gd")
#const HeightMapGenerator := preload("res://classes/World/heightmap_generator.gd")
#const Grid := preload("res://classes/geometry/grid.gd")


#
var delaunay: Delaunator
var voronoi: Voronoi
var grid: Grid
var heightmap_generator: HeightMapGenerator

var area := Rect2(0.0, 0.0, 1152, 648)
var points := PackedVector2Array()

func  before_all():
	var size = get_viewport().size
	grid = Grid.new(1000, area)
	grid.place_points()
	points = grid.points
	delaunay = Delaunator.new(points)
	voronoi = Voronoi.new(points,grid, delaunay, area)
	var world_selected: String = "volcano"

	heightmap_generator = HeightMapGenerator.new(grid, voronoi, world_selected)
	
#
func test_get_blob_power() -> void:
	var cell_1: int = 1000
	var cell_2: int = 100000
	var cell_3: int = 50000
	var invalid_cell: int = 14
	
	var default_value: float = heightmap_generator.get_blob_power(invalid_cell)
	assert_eq(default_value, 0.98, "Default value failed. Expected .98")
	default_value = heightmap_generator.get_blob_power(cell_1)
	assert_eq(default_value, 0.93, "Default value failed. Expected .93")
	default_value = heightmap_generator.get_blob_power(cell_2)
	assert_eq(default_value, 0.9973, "Default value failed. Expected 0.9973")
	default_value = heightmap_generator.get_blob_power(cell_3)
	assert_eq(default_value, 0.994, "Default value failed. Expected 0.994")
	
func test_get_line_power() -> void:
	var cell_1: int = 1000
	var cell_2: int = 100000
	var cell_3: int = 50000
	var invalid_cell: int = 14
	
	var default_value: float = heightmap_generator.get_line_power(invalid_cell)
	assert_eq(default_value, 0.81, "Default value failed. Expected .81")
	default_value = heightmap_generator.get_line_power(cell_1)
	assert_eq(default_value, 0.75, "Default value failed. Expected .75")
	default_value = heightmap_generator.get_line_power(cell_2)
	assert_eq(default_value, 0.93, "Default value failed. Expected 0.93")
	default_value = heightmap_generator.get_line_power(cell_3)
	assert_eq(default_value, 0.86, "Default value failed. Expected 0.86")

# Test the scan function. The two compare functions following this test are
# used soley by this test.		
func test_scan():
	var test_array = [42, 71, 91, 67, 43, 17, 53]
	var expected_index = 5
	var expected_value  = 17
	
	var min_index = heightmap_generator.scan(test_array, Callable(self, "compare_value_min"))	
	assert_eq(min_index, expected_index, "Expected result should be 5")
	assert_eq(test_array[min_index], expected_value, "Expected result should be 17")

	expected_index = 2
	expected_value  = 91
	
	var max_index = heightmap_generator.scan(test_array, Callable(self, "compare_value_max"))	
	assert_eq(max_index, expected_index, "Expected result should be 2")
	assert_eq(test_array[max_index], expected_value, "Expected result should be 91")

func compare_value_min(a, b):
	return a - b
	
func compare_value_max(a, b):
	return  b - a

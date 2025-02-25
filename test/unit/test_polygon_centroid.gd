extends GutTest

# Port of tests for d3.polygon
# https://github.com/d3/d3-polygon/blob/main/test/centroid-test.js

var polygon: Polygon

func  before_all():
	polygon = Polygon.new()
	
# Test the expected value for closed counterclockwise polygons
func test_closed_counterclockwise_polygon():
	var points = [[0, 0], [0, 1], [1, 1], [1, 0], [0, 0]]
	var expected_result = [0.5, 0.5]
	
	var result = polygon.polygon_centroid(points)
	assert_eq(result, expected_result)
	
# Tests the expected value for closed clockwise polygons
func test_closed_clockwise_polygon():
	var points = [[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]
	var expected_result = [0.5, 0.5]
	
	var result = polygon.polygon_centroid(points)
	assert_eq(result, expected_result)
	
	points = [[1, 1], [3, 2], [2, 3], [1, 1]]
	expected_result = [2.0, 2.0]
	
	result = polygon.polygon_centroid(points)
	assert_eq(result, expected_result)
	
# Tests the expected value for open counterclockwise polygons
func test_open_counterclockwise_polygon():
	var points = [[0, 0], [0, 1], [1, 1], [1, 0]]
	var expected_result = [0.5, 0.5]
	
	var result = polygon.polygon_centroid(points)
	assert_eq(result, expected_result)
	
# Tests the expected value for open clockwise polygons
func test_open_clockwise_polygon():
	var points = [[0, 0], [1, 0], [1, 1], [0, 1]]
	var expected_result = [0.5, 0.5]
	
	var result = polygon.polygon_centroid(points)
	assert_eq(result, expected_result)
	
	points = [[1, 1], [3, 2], [2, 3]]
	expected_result = [2.0, 2.0]
	
	result = polygon.polygon_centroid(points)
	assert_eq(result, expected_result)
	
# Tests the expected value for a very large polygon
func test_large_polygon():
	var stop = 1e8
	var step = 1e4
	var points = []
	var expected_result = [49999999.75000187, 49999999.75001216]
	
	for value in range(0, stop, step):
		points.push_back([0, value])

	for value in range(0, stop, step):
		points.push_back([value, stop])

	for value in range(stop - step, -1, -step):
		points.push_back([stop, value])

	for value in range(stop - step, -1, -step):
		points.push_back([value, 0])
		
	var result = polygon.polygon_centroid(points)
	assert_eq(result, expected_result)
	
	
	

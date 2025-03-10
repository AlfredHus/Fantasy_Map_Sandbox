extends GutTest

# Test the rounding of floating point values
func test_rn():
	var arg1 = 40.314
	var expected_result: float = 40
	var result: float
	
	result = GeneralUtilities.rn(arg1)
	assert_eq(result, expected_result)
	
	var arg2 = 2
	var expected_result1 = 40.31
	
	result = GeneralUtilities.rn(arg1, arg2)
	assert_eq(result, expected_result1)
	
	
	
	

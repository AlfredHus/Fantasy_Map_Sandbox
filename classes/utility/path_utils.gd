class_name PathUtils


func _init():
	pass
	
func connect_vertices(feature_ids, feature_type, vertices, starting_vertex, close_ring):
	#print ("connect_vertices: ", vertices["c"].size())
	var MAX_ITERATIONS = vertices["c"].size()
	var chain: Array = []  # Chain of vertices to form a path
	
	var next = starting_vertex
	var i = 0
	# Loop until we return to the starting vertex (ensuring we run at least once)
	while i == 0 or next != starting_vertex:
		#var previous = chain.size() > 0 ? chain[chain.size() - 1] : null
		
		var previous = chain[chain.size() - 1] if  chain.size() > 0 else null
		var current = next
		chain.append(current)
		
		var neib_cells = vertices["c"][current]
		# If add_to_checked is provided, call it on every neighbor cell that passes of_same_type.
		# IN the Azgaar code, this addtoChecked is used, but it is not defined in the code for this
		# function. When I comment out the line, it does not see to have any affect. For now,
		# I will leave it out. Code is left here as a reminder and placeholder.
		#if add_to_checked:
			#for cell in neib_cells:
				#if of_same_type(cell):
					#add_to_checked(cell)
		
		# Map neighbor cells through of_same_type.
		# (Assumes that neib_cells has exactly three entries.)
		var mapped: Array = []
		for cell in neib_cells:
			if cell >= feature_ids.size():
				mapped.append(false)
			else:
			#mapped.append(of_same_type(feature_ids, cell, feature_type))
				mapped.append(feature_ids[cell] == feature_type)
		var c1 = mapped[0]
		var c2 = mapped[1]
		var c3 = mapped[2]
		
		# Retrieve the three vertex connections for the current vertex.
		var v_arr = vertices["v"][current]
		
		var v1 = v_arr[0]
		var v2 = v_arr[1]
		var v3
		if v_arr.size() ==2:
			v3 = -1
		else:
		#var v3 = v_arr[2]
			v3 = v_arr[2]
		
		# Decide on the next vertex based on the conditions.
		if v1 != previous and c1 != c2:
			next = v1
		elif v2 != previous and c2 != c3:
			next = v2
		elif v3 != previous and c1 != c3:
			next = v3
		
		# Error checking for out-of-bounds or stuck vertex.
		if next >= vertices["c"].size():
			push_error("ConnectVertices: next vertex is out of bounds")
			break

		if next == current:
			push_error("ConnectVertices: next vertex is not found")
			break

		if i == MAX_ITERATIONS:
			push_error("ConnectVertices: max iterations reached (" + str(MAX_ITERATIONS) + ")")
			break
		
		i += 1
	
	# If we need to close the ring, append the starting vertex.
	if close_ring:
		chain.append(starting_vertex)
	
	return chain

# Checks if a cell has the same type as the given target type.
# Replaces javascript function: "const ofSameType = cellId => getType(cellId) === type;"
func of_same_type(feature_ids, cell_id: int, target_type: int) -> bool:
	var temp = feature_ids[cell_id] # TEMP
	return feature_ids[cell_id] == target_type

class_name Lakes
extends Node

var _elevation_limit: int

func _init():
	pass
	
func add_lakes_in_deep_depression(grid: Grid, elevation_limit: int):
	
	if elevation_limit == 80: 
		return 
	
	for i in grid.cells["i"]:
		if grid.cells["b"][i] || grid.cells["h"][i] < 20:
			continue
		# JAVASCRIPT CODE: const minHeight = d3.min(c[i].map(c => h[c]));
		var minimum_height = grid.cells["c"][i].map(func(j): return grid.cells["h"][j]).min()
		
		#var minimum_height = INF 
		#for j in grid.cells["c"][i]:  # Iterate over neighboring cells
			#var j_temp = grid.cells["c"][i]
			#var height = grid.cells["h"][j]
			#if height < minimum_height:
				#minimum_height = height  # Update if a smaller value is found
		#pass
		
		if grid.cells["h"][i] > minimum_height:
			continue
			
		var deep: bool = true
		var threshold: int = grid.cells["h"][i]  + elevation_limit
		var queue = [i]
		var checked: Array[bool]
		checked.resize(grid.cells["h"].size())
		checked[i] = true
		
		# check if elevated cell can potentially pour to water
		while deep && queue.size() > 0:
			var q = queue.pop_front()
			
			for n in grid.cells["c"][q]:
				if checked[n]:
					continue
				if grid.cells["h"][n] >= threshold:
					continue
				if grid.cells["h"][n] < 20:
					deep = false
					break
					
				checked[n] = true
				queue.push_back(n)
		
		# if not, add a lake	
		if deep:
			# JAVASCRIPT CODE: const lakeCells = [i].concat(c[i].filter(n => h[n] === h[i]));
			var lake_cells = [i] + grid.cells["c"][i].filter(func(n): return grid.cells["h"][n] == grid.cells["h"][i])
			add_lake(lake_cells, grid)		
	
	
func add_lake(lake_cells, grid: Grid):
	var f: int = grid.features.size()

	for i in lake_cells:
		grid.cells["h"][i] = 19
		grid.cells["t"][i] = -1
		grid.cells["f"][i] = f
		for n in grid.cells["c"][i]:
			if not lake_cells.has(n):
				grid.cells["t"][n] = 1

	grid.features.append({ "i": f, "land": false, "border": false, "type": "lake" })
	pass
	
# near sea lakes usually get a lot of water inflow, most of them should break 
# threshold and flow out to sea (see Ancylus Lake)
func open_near_sea_lakes(grid: Grid, world_type: String) -> void:
	if world_type == "atoll": # No need for Atolls
		return
	
	# JAVASCRIPT CODE: if (!features.find(f => f.type === "lake"))	
	# checks if any feature in the features array is a lake
	#if not grid.features.any(func(feature): return feature["type"] == "lake"): # No lakes
		#return  
		
	var has_lake = false

	for feature in grid.features:
		# In Asgaars feature class, the features array's first element is a integer = 0, followed 
		# by dictionary elements. In Javascript, doing feature["type"] where you are looking
		# the [0] element gives you an error (it works fine in Javascript). SO what
		# we do is ignore the first element [0]. We can do this by checking if the element
		# is a dictionary (which we do below) or we could check to see if the feature = 0.
		if typeof(feature) != TYPE_DICTIONARY:
			continue
		if feature["type"] == "lake":
			has_lake = true
			break  # Stop checking once a lake is found

	if not has_lake:
		return  # No lakes
		
	const LIMIT: int = 22 # max height that can be breached by water
	
	for i in grid.cells["i"]:
		var lake_feature_id = grid.cells["f"][i]
		if grid.features[lake_feature_id]["type"] != "lake": 
			continue  # Not a lake
		
		# Check neighbors
		for c in grid.cells["c"][i]:
			if grid.cells["t"][c] != 1 or grid.cells["h"][c] > LIMIT:
				continue  # Water cannot break this

			for n in grid.cells["c"][c]:
				var ocean = grid.cells["f"][n]
				if grid.features[ocean]["type"] != "ocean":
					continue  # Not an ocean
				
				remove_lake(grid, c, lake_feature_id, ocean)
				break  # Stop checking once lake is removed
	
func remove_lake(grid: Grid, threshold_cell_id: int, lake_feature_id: int, ocean_feature_id: int) -> void:
	
	grid.cells["h"][threshold_cell_id] = 19 # Height
	grid.cells["t"][threshold_cell_id] = -1 # distance field
	grid.cells["f"][threshold_cell_id] = ocean_feature_id # index of feature
	
	# Mark as coastline
	for c in grid.cells["c"][threshold_cell_id]:
		if grid.cells["h"][c] >= 20:
			grid.cells["t"][c] = 1

	# Convert entire lake to ocean
	for i in grid.cells["i"]:
		if grid.cells["f"][i] == lake_feature_id:
			grid.cells["f"][i] = ocean_feature_id

	# Mark former lake as ocean
	grid.features[lake_feature_id]["type"] = "ocean"
	
	

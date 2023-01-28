class_name Utils
extends Object
	
static func shuffle(rng: RandomNumberGenerator, target: Array) -> void:
	for i in range(len(target)):
		var j: int = rng.randi_range(0, len(target) - 1)
		var swap = target[i]
		target[i] = target[j]
		target[j] =swap

static func _get_chains_from_lines(perimeter: Array) -> Array:  # (perimeter: Array[Edge]) -> Array[Array[Edge]]
	"""
	Given an array of unordered Edges on the perimeter of a shape
	Return an array, each element of which is an array of Edges ordered by
	the path around the perimeter. One of the arrays will be the outer shape and the
	rest will be internal "holes" in the shape.
	"""
	var perimeter_lines := perimeter.duplicate()
	# Identify chains by tracking each point in series of perimeter lines
	var chains: Array = []
	while not perimeter_lines.empty():
		# Setup the next chain, pick the end of a line
		var chain_done = false
		var chain_flipped = false
		var chain: Array = []
		var next_chain_line: Edge = perimeter_lines.pop_back()
		var start_chain_point: Vertex = next_chain_line.get_points().front()
		var next_chain_point: Vertex = next_chain_line.other_point(start_chain_point)
		# Follow the lines until we reach back to the beginning
		while not chain_done:
			chain.append(next_chain_line)
			
			# Do we have a complete chain now?
			if len(chain) >= 3 and chain.front().shares_a_point_with(chain.back()):
				chains.append(chain)
				chain_done = true
				continue
			
			# Which directions can we go from here?
			var connections = next_chain_point.get_connections()
			var directions: Array = []
			for line in connections:
				# Skip the current line
				if line == next_chain_line:
					continue
				if perimeter_lines.has(line):
					directions.append(line)
			
			# If there's no-where to go, something went wrong
			if len(directions) <= 0:
				printerr("FFS: This line goes nowhere!")
			
			# If there's only one way to go, go that way
			elif len(directions) == 1:
				next_chain_line = directions.front()
				next_chain_point = next_chain_line.other_point(next_chain_point)
				perimeter_lines.erase(next_chain_line)
			
			else:
				# Any links that link back to start of the current chain?
				var loop = false
				for line in directions:
					if line.other_point(next_chain_point) == start_chain_point:
						loop = true
						next_chain_line = line
						next_chain_point = next_chain_line.other_point(next_chain_point)
						perimeter_lines.erase(line)
				
				if not loop:
					# Multiple directions with no obvious loop, 
					# Reverse the chain to extend it in the opposite direction
					if chain_flipped:
						# This chain has already been flipped, both ends are trapped
						# Push this chain back into the pool of lines and try again
						chain.append_array(perimeter_lines)
						perimeter_lines = chain
						chain_done = true
						continue
					
					chain.invert()
					var old_start_point : Vertex = start_chain_point
					start_chain_point = next_chain_point
					next_chain_line = chain.pop_back()
					next_chain_point = old_start_point
					chain_flipped = true
	
	return chains

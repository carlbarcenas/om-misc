#!/usr/bin/python

"""
1) Parses *.gdt files and generates list of object representing paths and boundaries
2) Decomposes the boundaries into rectangles
-Store all vertical lines
-For every concave vertex create a horizontal interior cut to the nearest vertical line
   -Inside of the figure determined by number of right and left "turns" (cannot assume CW or CCW)
   -Should be twice as many right turns if we are going CW around the figure
   -If CW, left turns are concave
3) Determines the percentage of each layer that is made up of figures
"""

# This class represents a path element in the GDT file. It will have a width (w and 2 xy points)
class Path:
	def __init__(self, layer, dt, pt, w, bx, ex):
		self.layer = layer
		self.xy = []
		self.w = w

# This class represents a boundary element in the GDT file. It will have a variable number of xy points.
# Boundary will not contain holes and no two points should be the same.
class Boundary:
	def __init__(self, layer, dt, lines=[]):
		self.layer = layer
		self.dt = dt
		self.lines = lines
		self.xy = []
	def createLines(self):
		self.lines = []
		for a in range(len(self.xy)/2 - 1):
			self.lines.append(Line(self.xy[a*2], self.xy[a*2+1], self.xy[a*2+2], self.xy[a*2+3]))
		self.lines.append(Line(self.xy[len(self.xy)-2], self.xy[len(self.xy)-1], self.xy[0], self.xy[1]))
	def determineInterior(self):
		self.turns = []
		left_turns = 0
		right_turns = 0
		# Count up right or left turns to determine whether we're going CW or CCW around the shape
		for a in range(len(self.lines) - 1):
			line1 = self.lines[a]
			line2 = self.lines[a+1]
			# +x (line 1)
			if(line1.x2 > line1.x1):
				# +y (line 2)
				if(line2.y2 > line2.y1):
					left_turns = left_turns + 1
					self.turns.append("L")
					# print "+x+y"
				elif(line2.y2 < line2.y1):
					right_turns = right_turns + 1
					self.turns.append("R")
				else:
					return False
##					print line1
##					print line2
##					sys.exit("Failed on turn detection +x")
			# -x (line 1)
			elif(line1.x1 > line1.x2):
				# -y (line 2)
				if(line2.y1 > line2.y2):
					left_turns = left_turns + 1
					self.turns.append("L")
					# print "-x-y"
				elif(line2.y1 < line2.y2):
					right_turns = right_turns + 1
					self.turns.append("R")
				else:
					return False
##					print line1
##					print line2
##					sys.exit("Failed on turn detection -x")
			# +y (line 1)
			elif(line1.y2 > line1.y1):
				# -x (line 2)
				if(line2.x1 > line2.x2):
					left_turns = left_turns + 1
					self.turns.append("L")
					# print "+y-x"
				elif(line2.x1 < line2.x2):
					right_turns = right_turns + 1
					self.turns.append("R")
				else:
					return False
##					print line1
##					print line2
##					sys.exit("Failed on turn detection +y")
			# -y (line 1)
			elif(line1.y1 > line1.y2):
				# +x (line 2)
				if(line2.x2 > line2.x1):
					left_turns = left_turns + 1
					self.turns.append("L")
					# print "-y+x"
				elif(line2.x2 < line2.x1):
					right_turns = right_turns + 1
					self.turns.append("R")
				else:
					return False
##					print line1
##					print line2
##					sys.exit("Failed on turn detection -y")
			else:
				return False
##				print line1
##				print line2
##				sys.exit("Failed on turn detection (main)")

		# Compute the final turn
		line1 = self.lines[-1]
		line2 = self.lines[0]
		# +x (line 1)
		if(line1.x2 > line1.x1):
			# +y (line 2)
			if(line2.y2 > line2.y1):
				left_turns = left_turns + 1
				self.turns.append("L")
				# print "+x+y"
			elif(line2.y2 < line2.y1):
				right_turns = right_turns + 1
				self.turns.append("R")
			else:
				return False
##				print line1
##				print line2
##				sys.exit("Failed on turn detection +x")
		# -x (line 1)
		elif(line1.x1 > line1.x2):
			# -y (line 2)
			if(line2.y1 > line2.y2):
				left_turns = left_turns + 1
				self.turns.append("L")
				# print "-x-y"
			elif(line2.y1 < line2.y2):
				right_turns = right_turns + 1
				self.turns.append("R")
			else:
##				print line1
##				print line2
				return False
##				sys.exit("Failed on turn detection -x")
		# +y (line 1)
		elif(line1.y2 > line1.y1):
			# -x (line 2)
			if(line2.x1 > line2.x2):
				left_turns = left_turns + 1
				self.turns.append("L")
				# print "+y-x"
			elif(line2.x1 < line2.x2):
				right_turns = right_turns + 1
				self.turns.append("R")
			else:
				return False
##				print line1
##				print line2
##				sys.exit("Failed on turn detection +y")
		# -y (line 1)
		elif(line1.y1 > line1.y2):
			# +x (line 2)
			if(line2.x2 > line2.x1):
				left_turns = left_turns + 1
				self.turns.append("L")
				# print "-y+x"
			elif(line2.x2 < line2.x1):
				right_turns = right_turns + 1
				self.turns.append("R")
			else:
				return False
##				print line1
##				print line2
##				sys.exit("Failed on turn detection -y")
		else:
			return False
##			print line1
##			print line2
##			sys.exit("Failed on turn detection (main)")
		
		# print "R: " + str(right_turns)
		# print "L: " + str(left_turns)

		if(right_turns > left_turns):
			self.interior = "CW"
		elif(left_turns > right_turns):
			self.interior = "CCW"
		else:
			return False
##			sys.exit("This shape doesn't make sense or the turn detection didn't work")

		return True
	def splitBoundary(self):
		# If the boundary only has 4 lines (4 xy pairs) then it is a rectangle and we are done
		if(len(self.lines) == 4):
			return True
		if(len(self.lines) < 4):
			print time.clock()
			sys.exit("Reduced below 4 lines");
		a = 0
		if(self.interior == "CW"):
			# Find the first left turn and split
			while(self.turns[a] != "L"):
				a = a + 1
		elif(self.interior == "CCW"):
			try:
				# Find the first right turn and split
				while(self.turns[a] != "R"):
					a = a + 1
			except:
				for a in self.lines:
					print a
				
		# self.lines[a] is line before vertex
		if(self.lines[a].y1 != self.lines[a].y2): # If the line before the vertex isn't horizontal
			a = a + 1                         # Move to the line after the vertex which is
					
		minDistance = None;
		# Find the closest line we intersect
		for b in range(len(self.lines)):
			distance = self.lines[b].intersect(self.lines[a], self.lines[a-1], self.interior)
			if(minDistance == None):
				minDistance = distance
				if(distance != None):
					closestLine = b
			elif(distance != None) and (minDistance == distance) and (self.lines[b].y1 == self.lines[b].y2): # Only replace this if the intersecting line is horizontal, pushing it into the "two horizontal lines" case
				minDistance = distance
				closestLine = b
			elif(distance != None) and (minDistance > distance):
				minDistance = distance
				closestLine = b
		try: b = closestLine
		except:
		    print self.lines
		    print time.clock()
		    sys.Exit("Couldn't find closest line")
		
		# At this point the index of the closest line is in b
		if(self.lines[b].y1 == self.lines[b].y2): # Two horizontal lines
			linesBefore = self.lines[:a]
			newLine = Line(self.lines[a].x1, self.lines[a].y1,
				       self.lines[b].x2, self.lines[b].y2)
			linesAfter = self.lines[b+1:]

			linesBetween = self.lines[a+1:b]
			newLine2 = Line(self.lines[b].x1, self.lines[b].y1,
					self.lines[a].x2, self.lines[a].y2)

			self.lines = linesBefore
			self.lines.append(newLine)
			self.lines.extend(linesAfter)

			newLines = linesBetween
			newLines.append(newLine2)

			newBoundary = Boundary(self.layer, self.dt, newLines)
			newBoundary.determineInterior()
			boundary_obj_list.append(newBoundary)
			self.determineInterior()
		else: # Horizontal line extending to intersect vertical line
			if(a < b):
				linesBefore = self.lines[:a]
				extendedNewLine = Line(self.lines[a].x1, self.lines[a].y1,
						       self.lines[b].x1, self.lines[a].y1)
				splitIntersectedLine = Line(self.lines[b].x1, self.lines[a].y1,
							    self.lines[b].x2, self.lines[b].y2)
				linesAfter = self.lines[b+1:]
				
				linesBetween = self.lines[a+1:b]
				splitIntersectedLine2 = Line(self.lines[b].x1, self.lines[b].y1,
							    self.lines[b].x2, self.lines[a].y2)
				lineBack = Line(self.lines[b].x2, self.lines[a].y2,
						self.lines[a].x2, self.lines[a].y2)
				
				self.lines = linesBefore
				self.lines.append(extendedNewLine)
				self.lines.append(splitIntersectedLine)
				self.lines.extend(linesAfter)

				newLines = linesBetween
				newLines.append(splitIntersectedLine2)
				newLines.append(lineBack)
					
				newBoundary = Boundary(self.layer, self.dt, newLines)
				newBoundary.determineInterior()
				boundary_obj_list.append(newBoundary)
				self.determineInterior()
			else:
				linesBefore = self.lines[:b]
				splitIntersectedLine = Line(self.lines[b].x1, self.lines[b].y1,
							    self.lines[b].x1, self.lines[a].y1)
				extendedNewLine = Line(self.lines[b].x1, self.lines[a].y1,
						       self.lines[a].x2, self.lines[a].y2)
				linesAfter = self.lines[a+1:]
				
				linesBetween = self.lines[b+1:a]
				splitIntersectedLine2 = Line(self.lines[b].x1, self.lines[a].y1,
							    self.lines[b].x2, self.lines[b].y2)
				lineBack = Line(self.lines[a].x1, self.lines[a].y1,
						self.lines[b].x1, self.lines[a].y1)
				
				self.lines = linesBefore
				self.lines.append(splitIntersectedLine)
				self.lines.append(extendedNewLine)
				self.lines.extend(linesAfter)

				newLines = []
				newLines.append(splitIntersectedLine2)
				newLines.extend(linesBetween)
				newLines.append(lineBack)
					
				newBoundary = Boundary(layer, dt, newLines)
				newBoundary.determineInterior()
				boundary_obj_list.append(newBoundary)
				self.determineInterior()
		
		return False
	def __str__(self):
		return str(self.xy)
	
# Represents lines between points in a boundary element. Useful for creating horizontal cuts to edges.
class Line:
	def __init__(self, x1, y1, x2, y2):
		self.xy1 = [x1, y1]
		self.xy2 = [x2, y2]
		self.x1 = x1
		self.x2 = x2
		self.y1 = y1
		self.y2 = y2
	# Checks to see if the line intersects with the horizontal projection from point given (directional)
	# Returns the distance from the point to the intersection or None if they don't intersect
	def intersect(self, baseLine, prevLine, interior):
		# Determine the cut direction that is interior to the polygon
		cutDirection = "right"
		if (    ( (prevLine.y1 > prevLine.y2) and (interior == "CW")  )
		     or ( (prevLine.y1 < prevLine.y2) and (interior == "CCW") ) ):
			cutDirection = "left"

		# Check to see if the direction of the cut would be appropriate
		if (   ( (cutDirection == "right") and (self.x1 < baseLine.x1) )
		    or ( (cutDirection == "left")  and (self.x1 > baseLine.x1) ) ):
			return None
		
		y = baseLine.y1
		# Check to see if a horizontal cut can be made to the interior of the line segment
		if (  ( (self.y2 > self.y1)  and ((y > self.y2) or (y < self.y1)) ) # If line goes up
		   or ( (self.y2 < self.y1)  and ((y < self.y2) or (y > self.y1)) ) # If line goes down
		   or ( (self.y2 == self.y1) and (y != self.y1) ) ): # If line goes horizontally
			return None
		
		if (  ((baseLine.x1 == self.x1) and (y == self.y1))
		   or ((baseLine.x1 == self.x2) and (y == self.y2))
		   or ((baseLine.x2 == self.x1) and (y == self.y1)) 
		   or ((baseLine.x2 == self.x2) and (y == self.y2)) ): # Don't want to return the line we're on as a valid intersection
			return None
		
		distance = abs(baseLine.x1 - self.x1)
		if(abs(baseLine.x1 - self.x2) < distance):
			distance = abs(baseLine.x1 - self.x2)
		if(abs(baseLine.x2 - self.x1) < distance):
			distance = abs(baseLine.x2 - self.x1)
		if(abs(baseLine.x2 - self.x2) < distance):
			distance = abs(baseLine.x2 - self.x2)
		
		return distance
	def __str__(self):
		return str(self.xy1) + str(self.xy2)

# Need to import the regular expression Python library               
import re
import time
import sys
import cPickle

##start_time = time.clock()

# Create regular expressions to match boundary and path 
# elements of the *.gdt file
boundary = re.compile("b{\d+ [^\n]*}")
boundary_layer = re.compile("b{(\d+).*")
boundary_dt = re.compile(".*dt(\d+).*")
boundary_xy = re.compile(".*xy\(([ \d\.-]+) ([\d\.-]+)\)}")

path = re.compile("p{\d+ [^\n]*}")
path_layer = re.compile("p{(\d+).*")
path_dt = re.compile(".*dt(\d+) .*")
path_pt = re.compile(".*pt(\d+) .*")
path_w = re.compile(".*w([\d\.-]+) .*")
path_bx = re.compile(".*bx([\d\.-]+) .*")
path_ex = re.compile(".*ex([\d\.-]+) .*")
path_xy = re.compile(".*xy\(([ \d\.-]+) ([\d\.-]+)\)}")

stop = False;
area_table = dict()
# Read the gdt file contents into a file
f = open("core1f.gdt", "r")
file_contents = ""
for a in range(0,1000):
    file_contents += f.readline()
if(file_contents == ""):
    stop = True;
    f.close()

count = 1

while(not stop):

    # Regex the path and boundary elements out of the file
    boundary_str_list = boundary.findall(file_contents)
    path_str_list = path.findall(file_contents)

    # Initialize the object lists so we can start by appending onto an empty list
    boundary_obj_list = []
    path_obj_list = []

    broken_count = 0

    # Create the Boundary objects and put them all into a list
    for a in boundary_str_list:
            
            layer = int(boundary_layer.findall(a).pop())
            
            try:	dt = int(boundary_dt.findall(a).pop())
            except:	dt = None

            newBoundary = Boundary(layer, dt)

            xy_match = boundary_xy.match(a)
            xy_list = re.split(" ", xy_match.group(1))
            xy_list.append(xy_match.group(2))

            for b in xy_list:
                    newBoundary.xy.append(float(b))

            testCorners = True
            for a in range(len(newBoundary.xy)-2):
                    if(a%2 == 0):
                            if(newBoundary.xy[a] != newBoundary.xy[a+2]
                               and newBoundary.xy[a] != newBoundary.xy[a-2]):
                                    testCorners = False
                    else:
                            if(newBoundary.xy[a] != newBoundary.xy[a+2]
                               and newBoundary.xy[a] != newBoundary.xy[a-2]):
                                    testCorners = False
                            
            if(testCorners):
                    newBoundary.createLines()
                    if not newBoundary.determineInterior():
                            broken_count = broken_count + 1
                    else:
                            boundary_obj_list.append(newBoundary)
            else:
                    broken_count = broken_count + 1
            

##    print "Total:  " + str(len(boundary_obj_list) + broken_count)
##    print "Broken: " + str(broken_count)
##    print time.clock() - start_time

##    file_boundary_obj_list = open("/export/home1/scratch/brian/boundary_obj_list.obj", "w")
##    cPickle.dump(boundary_obj_list, file_boundary_obj_list)
##    file_boundary_obj_list.close()

    """
    print "Coordinate List:"
    print boundary_obj_list[0]
    print "Line List:"
    for a in boundary_obj_list[0].lines:
            print a
    print "Turn List:"
    for a in boundary_obj_list[0].turns:
            print a
    """

    i = 0
    while (i < len(boundary_obj_list)):
            # Split the boundary until it is a rectangle and splitBoundary() returns True
            while (not boundary_obj_list[i].splitBoundary()):
                    pass
            i = i + 1;
            
##    file_split_boundary_obj_list = open("/export/home1/scratch/brian/split_boundary_obj_list.obj", "w")
##    cPickle.dump(boundary_obj_list, file_split_boundary_obj_list)
##    file_split_boundary_obj_list.close()

    """
    print "-----------AFTER SPLIT-----------"
    for a in boundary_obj_list:
            for b in a.lines:
                    print b
            print "---------"
    """

    # Create the Path objects and put them all in a list
    for a in path_str_list:
            layer = int(path_layer.findall(a).pop())
            
            try:	dt = int(path_dt.findall(a).pop())
            except:	dt = None
            
            try:	pt = int(path_pt.findall(a).pop())
            except:	pt = None
            
            try:	w = float(path_w.findall(a).pop())
            except:	w = None
            
            try:	bx = float(path_bx.findall(a).pop())
            except:	bx = None
            
            try:	ex = float(path_ex.findall(a).pop())
            except:	ex = None
            
            newPath = Path(layer, dt, pt, w, bx, ex)

            xy_match = path_xy.match(a)
            xy_list = re.split(" ", xy_match.group(1))
            xy_list.append(xy_match.group(2))

            for b in xy_list:
                    newPath.xy.append(float(b))

            path_obj_list.append(newPath)

##    print time.clock() - start_time
##
##    file_path_obj_list = open("/export/home1/scratch/brian/path_obj_list.obj", "w")
##    cPickle.dump(path_obj_list, file_path_obj_list)
##    file_path_obj_list.close()
##
##    file_path_obj_list = open("/export/home1/scratch/brian/path_obj_list.obj", "r")
##    path_obj_list = cPickle.load(file_path_obj_list)
##    file_path_obj_list.close()
##
##    file_boundary_obj_list = open("/export/home1/scratch/brian/split_boundary_obj_list.obj", "r")
##    boundary_obj_list = cPickle.load(file_boundary_obj_list)
##    file_boundary_obj_list.close()

##    split = 4 # This will make (split)x(split) regions to divide the area up into

    total_area = 560*560
##    split_area = total_area/(split*split)

    # Compute the area in each layer
    for a in boundary_obj_list:
            dist_x1 = abs(a.lines[0].x1 - a.lines[0].x2)
            dist_x2 = abs(a.lines[1].x1 - a.lines[1].x2)
            if dist_x1 > dist_x2:
                    dist_x = dist_x1
            else:
                    dist_x = dist_x2
                    
            dist_y1 = abs(a.lines[0].y1 - a.lines[0].y2)
            dist_y2 = abs(a.lines[1].y1 - a.lines[1].y2)
            if dist_y1 > dist_y2:
                    dist_y = dist_y1
            else:
                    dist_y = dist_y2

            area = dist_x*dist_y
            
            if(a.layer not in area_table):
                    area_table[a.layer] = 0
                    
            area_table[a.layer] += area

    for a in path_obj_list:
            dist_x = abs(a.xy[0] - a.xy[2])
            dist_y = abs(a.xy[1] - a.xy[3])
            
            if dist_x > dist_y:
                    dist = dist_x
            else:
                    dist = dist_y

            area = dist*a.w
            
            if(a.layer not in area_table):
                    area_table[a.layer] = 0
                    
            area_table[a.layer] += area

    file_contents = ""
    for a in range(0,1000):
        file_contents += f.readline()
    if(file_contents == ""):
        stop = True;
        f.close()

    print "Iter: " + str(count)
    count += 1

# Convert that into a percentage
for a in area_table.items():
	print "Layer: " + str(a[0]) + "   " + str(a[1]/total_area*100) + "%"

print "Pickling area table"

file_area_table = open("area_table.obj", "w")
cPickle.dump(area_table, file_area_table)
file_area_table.close()

print "Pickled area table"

#!/usr/bin/python

"""
Reads in parsed GDT objects and determines the percentage area in each of the specified regions

4x4 example

4 8 12 16
3 7 11 15
2 6 10 14
1 5 9  13

13 14 15 16
9  10 11 12
5  6  7  8
1  2  3  4

First one is 0->560/split, 0->560/split
Second is 560/split->560/split*2, 0->560/split
Fifth is 0->560/split, 560/split->560/split*2
"""

import cPickle

file_path_obj_list = open("/export/home1/scratch/brian/path_obj_list.obj", "r")
path_obj_list = cPickle.load(file_path_obj_list)
file_path_obj_list.close()

file_boundary_obj_list = open("/export/home1/scratch/brian/split_boundary_obj_list.obj", "r")
boundary_obj_list = cPickle.load(file_boundary_obj_list)
file_boundary_obj_list.close()

split = 4 # This will make (split)x(split) regions to divide the area up into

total_area = 560*560
split_area = total_area/(split*split)

area_table = dict()
"""
for x in range(split):
	for y in range(split):
		for a in boundary_obj_list:
			min_x = 560/split*x
			max_x = 560/split*(x+1)
			x1 = a.lines[0].x1
			x2 = a.lines[0].x2
			
			if(x1 < min_x):
				x1 = min_x
			elif(x1 > max_x):
				x1 = max_x

			if(x2 < min_x):
				x2 = min_x
			elif(x2 > max_x):
				x2 = max_x
			
			dist_x1 = abs(x1 - x2)
			
			x1 = a.lines[1].x1
			x2 = a.lines[1].x2
			
			if(x1 < min_x):
				x1 = min_x
			elif(x1 > max_x):
				x1 = max_x

			if(x2 < min_x):
				x2 = min_x
			elif(x2 > max_x):
				x2 = max_x
				
			dist_x2 = abs(x1 - x2)
			
			if dist_x1 > dist_x2:
				dist_x = dist_x1
			else:
				dist_x = dist_x2
				
			min_y = 560/split*y
			max_y = 560/split*(y+1)
			y1 = a.lines[0].y1
			y2 = a.lines[0].y2
			
			if(y1 < min_y):
				y1 = min_y
			elif(y1 > max_y):
				y1 = max_y

			if(y2 < min_y):
				y2 = min_y
			elif(y2 > max_y):
				y2 = max_y
			
			dist_y1 = abs(y1 - y2)
			
			y1 = a.lines[1].y1
			y2 = a.lines[1].y2
			
			if(y1 < min_y):
				y1 = min_y
			elif(y1 > max_y):
				y1 = max_y

			if(y2 < min_y):
				y2 = min_y
			elif(y2 > max_y):
				y2 = max_y
				
			dist_y2 = abs(y1 - y2)
			
			if dist_y1 > dist_y2:
				dist_y = dist_y1
			else:
				dist_y = dist_y2

			area = dist_x*dist_y
			
			if(a.layer not in area_table):
				area_table[a.layer] = 0
				
			area_table[a.layer] += area
		print str(x) + ", " + str(y) + ":"
		for a in area_table.items():
			print "Layer: " + str(a[0]) + "   " + str(a[1]/split_area*100) + "%"
		area_table.clear()
"""
	
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

# Convert that into a percentage
for a in area_table.items():
	print "Layer: " + str(a[0]) + "   " + str(a[1]/total_area)*100 + "%"

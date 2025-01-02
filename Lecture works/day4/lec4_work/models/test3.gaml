/**
* Name: test1
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model test1

/* Insert your model definition here */

global {
	file shapefile_buildings <- file ("../includes/buildings.shp");
	file shapefile_roads <- file ("../includes/roads.shp");
	geometry shape <- envelope(shapefile_roads);
	
	graph road_network;
	
	map<road, float> new_weights;
	
	float step <- 10#s;
		
	init {
		create building from: shapefile_buildings with: (height: int(read("HEIGHT")));
		create road from: shapefile_roads;
		
		create inhabitant number: 1000 {
			location <- any_location_in(one_of(building)); 
		}
		
		road_network <- as_edge_graph(road);
	}
	
	reflex update_speed {
		new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
	}
}

species building {
	
	int height;
	
//	aspect default {
//		draw shape color: #gray;
//	}

	aspect threeD {
		draw shape color: #gray depth: height texture: ["../includes/roof.png", "../includes/texture5.jpg"];
		
	}
}

species road {
	
	float capacity <- 1 + shape.perimeter/30;
	int nb_drivers <- 0 update: length(inhabitant at_distance 1);
	float speed_rate <- 1.0 update: exp(-nb_drivers/capacity) min: 0.1;
	
	
	aspect default {
//		draw shape color: #black;
		draw (shape buffer (1 + 3 * (1 - speed_rate))) color: #red;
	}
}

species inhabitant skills: [moving] {
//species inhabitant{
	
	point target;
	rgb color <- rnd_color(255);
	float prob_leave <- 0.05;
	float speed <- 5 #km/#h;	
	
	reflex move when: target != nil {
		do goto target: target on: road_network move_weights: new_weights;
		if (location = target) {
			target <- nil;
		}
	}
	
	reflex leave when: (target = nil) and (flip(prob_leave)) {
		target <- any_location_in(one_of(building));
	}
	
//	aspect default {
//		draw circle(10) color: color;
//	}

	aspect threeD {
		draw pyramid(4) color: color;
		draw sphere(2) at: location + {0,0,3} color: color;
	}
	
}

experiment traffic type: gui {
	
	output {
		display map type: 3d {
			species building;
			species road;
			species inhabitant;
		}
	}
	
}

experiment traffic_3d type: gui {
	
	output {
		display map type: 3d axes: false background: #black {
			image "../includes/satelitte.png" refresh: false transparency: 0.2;
			species building aspect: threeD refresh: false;
			species inhabitant aspect: threeD;
		}
	}
	
}

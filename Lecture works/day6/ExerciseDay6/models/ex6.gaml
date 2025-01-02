/**
* Name: ex1
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model ex1

import "./Common Schelling Segregation.gaml"

/* Insert your model definition here */

global {
	
	shape_file nha20_shape_file <- shape_file("../includes/nha2.shp");
	geometry shape <- envelope(nha20_shape_file);
	
	int neighbours_distance <- 200 max: 1000; 

	
	init {
		create building from: nha20_shape_file;
		create people number: number_of_people {
			
//			color <- colors[rnd(number_of_groups - 1)];
			color <- colors at (rnd(number_of_groups - 1));
 		}	
	}
	
	
	action initialize_places{}
	action initialize_people{
		ask people {
			do chooseNewPlace;
		}
	}
	
	
}

species building {
	list<people> insidePeople -> people overlapping self.shape;

	rgb color <- #gray; 
//	update: people count (each.color = color);

	reflex changeColor {
		map<rgb, int> countColor;
		
		loop p over: insidePeople {
			countColor[p.color] <- countColor[p.color] + 1;
		}
	}
	
	aspect default {
		draw shape color: #gray border: #black;
	}
}

species people parent: base {
//	building curr_building;
	action chooseNewPlace {
		location <- any_location_in(any(building).shape);
	}
	
	list<people> my_neighbours -> people at_distance neighbours_distance;
	
	reflex schelling when: !is_happy {
		do chooseNewPlace;
	}
	
	aspect defaut {
		draw circle(5) color: color;
	}
}

experiment e parent: base_exp type: gui {
	parameter var: number_of_people init: 1000 min: 10 max: 5000;
	output {
		display main_display {
			species building;
			species people; 
//				draw shape color: color;
				
		}
	}
}
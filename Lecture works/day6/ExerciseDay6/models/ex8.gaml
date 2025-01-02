/**
* Name: ex8
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model ex8

/* Insert your model definition here */

global {
		
	shape_file buildings0_shape_file <- shape_file("../includes/buildings.shp");
	shape_file roads0_shape_file <- shape_file("../includes/roads.shp");

	float step <- 5#mn;
//	geometry shape <- envelope(square(500 #m));	
	geometry shape <- envelope(buildings0_shape_file + roads0_shape_file);	
	
	int number_of_people <- 100;
	int initInfectedNb <- 2;
	
	float proba_infection <- 0.05;
	float infect_distance <- 2#m;
	
	int numberInfectedAgents <- initInfectedNb
		update: people count each.isInfected;
	int numberNotInfectedAgents -> number_of_people - numberInfectedAgents;
	float infectedRate -> numberInfectedAgents / number_of_people;
	
	graph road_network;
	
	map<road, float> new_weights;
	
	init {
		
		create building from: buildings0_shape_file;
		create road from: roads0_shape_file;

		road_network <- as_edge_graph(road);
		
		create people number: number_of_people  {
//			location <- any_location_in(one_of(building));
//			location <- one_of(building).location;

			ask any(building where (length(each.inhabitant) < 2)){
				self.inhabitant << myself;
				myself.home <- self;
			}
			
			self.work <- any(building);
			
			
			location <- any_location_in(home);
			speed <- 2.0 #km/#h;
		}
		
		
		ask initInfectedNb among people {
			isInfected <- true;
		}
		
	}

	reflex update_speed {
		new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
	}
		
	reflex endSimulation when: numberInfectedAgents >= number_of_people {
		write "End of simulation";
		do pause;
	}
	
}

species building {
	int height;
	
	list<people> inhabitant;
	
	aspect default {
		draw shape color: #gray border: #black depth: height;
	}
}

species road {
	
	float capacity <- 1 + shape.perimeter/30;
	int nb_Walks <- 0 update: length(people at_distance 1);
	float speed_rate <- 1.0 update: exp(-nb_Walks/capacity) min: 0.1;
	
	aspect default {
//		draw shape color: #black;
		draw (shape buffer (1 + 3 * (1 - speed_rate))) color: #black;
	}
}

species people skills: [moving] {
	
	building home;
	building work;
	
	point target;
	
	float motivation <- 0.0;
	
	bool isInfected <- false;
	
	rgb color <- #green update: isInfected ? #red : #green;
	
	float speed <- 5.0 #km/#h;
	
	float prob_leave <- 0.05;	
	
//	reflex move {
//		do wander;		
//	}

	reflex move when: target != nil {
		do goto target: target on: road_network move_weights: new_weights;
		if (location = target) {
			target <- nil;
		}
	
	}
	
	reflex stay when: target = nil {
		if (flip(motivation)) {
//			target <- any_location_in(any(building));
			target <- (
				first(building overlapping self.shape) = home
				
			) ? any_location_in(work) : any_location_in(home);
			
			motivation <- 0.0;
		}
		else {
			motivation <- motivation + 0.01;
		}
	}
	
//	reflex leave when: (target = nil) and (flip(prob_leave)) {
//		target <- any_location_in(one_of(building));
//	}
	
	reflex infect when: isInfected {
		ask (people at_distance infect_distance) {
			if (proba_infection != nil) {
				isInfected <- true;
				
			}
		}
	}
	
	aspect default {
		draw circle(15) color: color;
	}
}

experiment e type: gui {
	parameter "Number of people" var: number_of_people init: 100 min: 10 max: 1000;
	
	output {
		monitor "Infected rate" value: infectedRate;
		display d {
			species building;
			species road;
			species people;
		}
		
		display chart {
			chart "Disease spreading" type: series {
				data "Infected" value: numberInfectedAgents color: #red;
				data "Not infected " value: numberNotInfectedAgents color: #green;
			}
		}
	}
}
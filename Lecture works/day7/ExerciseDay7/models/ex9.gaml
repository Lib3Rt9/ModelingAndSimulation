/**
* Name: Evacuation
* Based on the internal empty template. 
* Author: Baptiste Lesquoy
* Tags: 
*/


model Evacuation


global{
	

	shape_file shapefile_buildings  <- shape_file("../includes/Evacuation/includes/buildings.shp");
	shape_file shapefile_roads 		<- shape_file("../includes/Evacuation/includes/clean_roads.shp");
	shape_file shapefile_evacuation <- shape_file("../includes/Evacuation/includes/evacuation.shp");
	shape_file shapefile_river		<- shape_file("../includes/Evacuation/includes/RedRiver_scnr1.shp");

	
	
	geometry shape <- envelope(shapefile_roads);
	
	graph road_network;
	
	float step <- 10#s;
	
	int number_of_inhabitant <- 1000;
	
	// date
	date starting_date <- date([1980,1,2,6,0,0]);
//	date flooding_date <- date([1980,1,2,8,30,0]);
	date flooding_date; 	// ([year, month, day, hour, minute, seconds])
	float grow_rate <- 1 #m/#s;
	
	int nb_evacuated_ppl <- 0;
	
	map<road,float> new_weights;
	
//	building home;
//	building workplace;
	
	init {
		flooding_date <- date([1980,1,2,8,30,0]);
		
		create building from: shapefile_buildings with:[height::int(read("height"))];
		
		create road from: shapefile_roads;
		
		create inhabitant number: number_of_inhabitant{
			
			home <- one_of(building);
			workplace <- one_of(building - home);
//			workplaceDesk <- any_location_in(workplace);
			
       		location <- any_location_in(one_of(building));
      	}
		road_network <- as_edge_graph(road);
		
		create evacuation from:shapefile_evacuation;
		
		create red_river from:shapefile_river;
	}
	
	reflex update_speed {
		new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
	}
	
	
	reflex write_sim_info {
	
		write cycle;
		
		write time;  // time = cyle * step
		
		write current_date;
		
		write "----------";
	
	}
	
	reflex stop when: empty(inhabitant) {
		do pause;
	}
	
}



species building {
	int height;
	
	aspect default {
		draw shape color: #gray depth: height;
	}
}

species road {
	
	float capacity 		<- 1 + shape.perimeter/10;
	int nb_drivers 		<- 0 update: length(inhabitant at_distance 1);
	float speed_rate 	<- 1.0 update:  exp(-nb_drivers/capacity) min: 0.1;
	
	aspect default {
		draw (shape + 3 * speed_rate) color: #red;
	}
}


species inhabitant skills: [moving]{
	point target;
	rgb color 			<- rnd_color(255);
	float speed 		<- 5 #km/#h;

	building home;
	building workplace;
	building a;
	
	bool isEvacuating <- false;
	
	aspect default {
		draw circle(5) color: color;
	}
	
	
	reflex chooseLocation when: !isEvacuating 
		and (target = nil) 
		and (
			(current_date.hour = 7) 
			or 
			(current_date.hour = 19)
	) {
//		if (current_date.hour = 9)
		if (current_date.hour = 9)
		{
			target <- any_location_in(workplace);
		}
		else
		{
			target <- any_location_in(home);
		}
	}
	
	reflex evacuating when: (flooding_date <= current_date) and (!isEvacuating) {
		isEvacuating <- true;
		target <- any_location_in( evacuation closest_to self);
	}
	
	
	// if a target is defined we try to reach it via the road network
	reflex move when: target != nil {
		do goto target: target on: road_network move_weights:new_weights ;
		if (location distance_to target < 1#m) {
			location <- target;
			target <- nil;
		}		
	}
	
}

// Represents a point of evacuation
species evacuation{
	float distance <- 1.0 #m;
	
	int nb_evacuee <- 0 update:current_date > flooding_date ? inhabitant count (each.location = location) : 0;
	
	
	reflex evacuatingPeople {
		ask inhabitant at_distance distance {
			nb_evacuated_ppl <- nb_evacuated_ppl +1;
			do die;
		}
	}
	
	aspect default {
		draw triangle(50) color:#red;
	}
}

// Represents the red river
species red_river{
	
	geometry initial_shape <- shape;
//	float grow_rate <- 1 #m/#s update: grow_rate + 0.5;
//	float grow_rate <- 1 #m/#s;
	
	reflex expand when: (flooding_date <= current_date) and every(1#mn) {
		grow_rate <- grow_rate + 0.5;
		shape <- shape + grow_rate;
		
	}
	
//	reflex death when: (flooding_date <= current_date) {
	reflex death {
		bool isDestroyed <- false;
		
		ask inhabitant overlapping(self.shape) {
			do die;
		}
		
		ask road overlapping(self.shape) {
			isDestroyed <- true;
			do die;
		}
		
		if (isDestroyed) {
			road_network <- as_edge_graph(road);
			new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
		}
	}
	
	aspect default {
		draw shape color:#blue;
	}
}


experiment evacuation_exp type: gui {
	
	parameter "Number of inhabitant" var: number_of_inhabitant init: 1000 min: 100 max: 10000;
	parameter "Flood grow rate" var: grow_rate init: 0.5 min: 0.1 max: 1.0;
	
	float minimum_cycle_duration <- 0.05;
	
	
	output {
		monitor "Number people safe" value: nb_evacuated_ppl;
		monitor "Number people die" value: (
				1000 - nb_evacuated_ppl
			);
		
		display map {
			species red_river;
//			image "../includes/satellite.png" refresh: false transparency: 0.9;			
			species building ;
			species road ;
			species inhabitant ;
			species evacuation;
//			species red_river;
		}
		
		display stats {

//			chart "Evacuation status" type: series {
//				loop ev over:evacuation {
//					data ev.name value:ev.nb_evacuee style:dot;
//				}
//			}
			chart "people" type: series {
				data "Number saved" value: nb_evacuated_ppl
					color: #green;
				
				data "Number dead" value: number_of_inhabitant - length(inhabitant)
					color: #red;
				
				data "Total" value: number_of_inhabitant - length(inhabitant) + nb_evacuated_ppl 
					color: #black;
				
			}
			
		}
	}
}


/**
* Name: Evacuation
* Based on the internal empty template. 
* Author: Baptiste Lesquoy
* Tags: 
*/


model Evacuation


global{
	

	shape_file shapefile_buildings  <- shape_file("../includes/buildings.shp");
	shape_file shapefile_roads 		<- shape_file("../includes/clean_roads.shp");
	shape_file shapefile_evacuation <- shape_file("../includes/evacuation.shp");
	shape_file shapefile_river		<- shape_file("../includes/RedRiver_scnr1.shp");
	
	
	
	geometry shape <- envelope(shapefile_roads);
	
	graph road_network;
	
	float step <- 10#s;
	
	// date
	date starting_date <- date([1980,1,2,6,0,0]);
	
	
	map<road,float> new_weights;
	
	init {
		create building from: shapefile_buildings with:[height::int(read("height"))];
		
		create road from: shapefile_roads;
		
		create inhabitant number: 1000{
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
	
}



species building {
	int height;
	aspect default {
		draw shape color: #gray;
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

	aspect default {
		draw circle(5) color: color;
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
	
	aspect default {
		draw triangle(50) color:#red;
	}
}

// Represents the red river
species red_river{
	
	aspect default {
		draw shape color:#blue;
	}
}


experiment evacuation_exp type: gui {
	
	float minimum_cycle_duration <- 0.05;
	
	output {
		display map {
//			image "../includes/satellite.png" refresh: false transparency: 0.9;			
			species building ;
			species road ;
			species inhabitant ;
			species evacuation;
			species red_river;
		}
	}
}


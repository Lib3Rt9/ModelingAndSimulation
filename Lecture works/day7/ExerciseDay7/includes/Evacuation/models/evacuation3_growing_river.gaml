/**
* Name: Evacuation
* Based on the internal empty template. 
* Author: Baptiste Lesquoy
* Tags: 
*/


model Evacuation


global{
	
	//parameters
	int population_size <- 1000 parameter:"population size";
	date flooding_date <- date([1980,1,2,8,30,0]) parameter: "Flooding date";
	
	

	shape_file shapefile_buildings  <- shape_file("../includes/buildings.shp");
	shape_file shapefile_roads 		<- shape_file("../includes/clean_roads.shp");
	shape_file shapefile_evacuation <- shape_file("../includes/evacuation.shp");
	shape_file shapefile_river		<- shape_file("../includes/RedRiver_scnr1.shp");
	
	geometry shape <- envelope(shapefile_roads);
	
	graph road_network;
	
	float step <- 10#s;
	
	// date
	date starting_date <- date([1980,1,2,6,0,0]);
	float flooding_speed <- 1.0 parameter: "flooding speed" min:0.01 max:5.0;
	float flooding_duration <- 2#h parameter: "flooding duration" min:10#m max:1#week;
	
	
	map<road,float> new_weights;
	
	init {
		create building from: shapefile_buildings with:[height::int(read("height"))];
		
		create road from: shapefile_roads;
		
		create inhabitant number: population_size{
       		home <- any_location_in(one_of(building));
       		work <- any_location_in(one_of(building));
       		location <- home;
      	}
		road_network <- as_edge_graph(road);
		
		create evacuation from:shapefile_evacuation;
		
		create red_river from:shapefile_river;
	}
	
	reflex update_speed {
		new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
	}

	
	reflex write_sim_info {
		write current_date;
	}
	
	
	reflex all_evacuated when:current_date > flooding_date{
		//If at least one inhabitant is not located at an evacuation point, we continue
		loop i over:inhabitant{
			if ! i.is_safe {
				return;
			}
		}
		do pause;
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
	
	point home;
	point work;
	
	point target;
	rgb color 			<- rnd_color(255);
	float speed 		<- 5 #km/#h;
	bool is_safe		<- false;

	aspect default {
		draw circle(5) color: color;
	}
	
	
	reflex pick_target when:target = nil {
		
		//If we are after the start of the flooding we flee
		if (current_date > flooding_date){
			evacuation closest <- evacuation closest_to location;
			if closest != nil{
				target <- closest.location;				
			}			
		} 
		//else it's a normal day of work
		else{ 
			if (	current_date.hour#h + current_date.minute#minute >= 8#h 
				and current_date.hour#h + current_date.minute#minute <= 17#h
			){
				target <- work;
			}
			else{
				target <- home;
			}			
		}
	}
	
	
	// if a target is defined we try to reach it via the road network
	reflex move when: target != nil {
		do goto target: target on: road_network move_weights:new_weights ;
		if (location = target) {
			target <- nil;
		}	
	}
	
}

// Represents a point of evacuation
species evacuation{
	
	int nb_evacuee <- 0;
	
	aspect default {
		draw triangle(50) color:#red;
	}
	
	reflex save_people when:current_date > flooding_date{
		let safe <- inhabitant where (each.location = self.location);
		nb_evacuee <- length(safe);
		ask safe {
			is_safe <- true;
		}
	}
}

// Represents the red river
species red_river{
	
	aspect default {
		draw shape color:#blue;
	}
	
	int count_death <- 0;
	
	
	reflex flooding when:
		current_date > flooding_date 
			and current_date < flooding_date + flooding_duration{
		shape <- shape + flooding_speed;
		ask inhabitant overlapping self where ( ! each.is_safe) {
			myself.count_death <- myself.count_death + 1;
			do die;		
		}
		
	}
	
}


experiment evacuation_exp type: gui {
	
	float minimum_cycle_duration <- 0.05;
	
	output {
		display map {
			species building ;
			species road ;
			species inhabitant ;
			species evacuation;
			species red_river;
		}
		
	}
	

	
	
}


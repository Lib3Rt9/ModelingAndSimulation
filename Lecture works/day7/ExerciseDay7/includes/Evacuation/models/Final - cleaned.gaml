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
	
	int nb_ppl<-1000;
	string eva_strategy <- "closest_home";
	string news <- "vtv";
	float raise_level <- 5.0 min: 0.1 max: 10.0;
	
	
	
	
	
	list<inhabitant> flood_body;
	list<road> flood_road;
	int dead_count <-0;
	
	geometry shape <- envelope(shapefile_roads);
	
	graph road_network;
	
	float step <- 1#minute;
	
	// date
	date starting_date <- date([1980,1,2,6,0,0]);
	
	date flood_date <- date([1980,1,2,3,0,0]);
	
	
	
	map<road,float> new_weights;
	
	init {
		create building from: shapefile_buildings with:[height::int(read("height"))];
		
		create road from: shapefile_roads;
		
		create evacuation from:shapefile_evacuation;
		
		create inhabitant number: nb_ppl{
       		location <- any_location_in(one_of(building));
       		self.home <-location;
       		self.work_place <- any_location_in(one_of(building));
//       		self.evactuation_pick <- (evacuation agent_closest_to(self)).location;
//			write "loca "+ evacuation;
			if (eva_strategy = "closest_home"){
				self.evactuation_pick <- closest_to(evacuation, location).location;
			}
			if (eva_strategy = "closest_work"){
				self.evactuation_pick <- closest_to(evacuation, self.work_place).location;
			}
			if (eva_strategy = "randome"){
				self.evactuation_pick <- any_location_in(one_of(building));
			}
			
      	}
		road_network <- as_edge_graph(road);
		
		
		
		create red_river from:shapefile_river;
		
	
	}
	
	reflex flood when: current_date > flood_date and every(10#minute) and news ="heard"{
		
		ask one_of(inhabitant){
			self.alerted <- true;
		}
		}
	
	reflex update_speed {
		new_weights <- road as_map (each::each.shape.perimeter / each.speed_rate);
	}
	
	
	reflex write_sim_info {	
		write current_date;
	}
	
}



species building {
	int height;
	aspect default {
		draw shape color: #gray;
	}
}

species road {
	
	float capacity 		<- 1 + shape.perimeter/30;
	int nb_drivers 		<- 0 update: length(inhabitant at_distance 1);
	float speed_rate 	<- 1.0 update:  exp(-nb_drivers/capacity) min: 0.1;
	bool closed 		<- false;
	
	reflex closing_road when:flood_road contains self {
		speed_rate <- 9999999999.0;
		closed <- true;
	}
	
	aspect default {
		draw (shape + 3) color: #red;
	}
}


species inhabitant skills: [moving]{
	point target;
	rgb color 			<- rnd_color(255);
	float speed 		<- 5 #km/#h;
	point evactuation_pick; 
	bool evacuated <- false;
	
	
	bool alerted <- false;
	
	float freak_out <- 1.0 max:10.0 ;
	
	point home;
	point work_place;
	
	aspect default {
		draw circle(5) color: color;
	}


	reflex news when: current_date > flood_date {
		if (news = "vtv"){
			alerted <- true;
		}
		if (news = "heard"){
			ask agent_closest_to(self){
		 		alerted <- true;
		 	}
		}
	}
	
	reflex alive {
		if (flood_body contains self){
			dead_count <- dead_count+1;
			do die;
			
		}
	}
	reflex evac when: alerted {
		target <-evactuation_pick;
		freak_out <- freak_out*1.01;
		
	}
	// if a target is defined we try to reach it via the road network
	reflex move when: !evacuated and target != nil {
		
		new_weights <- road as_map (each::each.shape.perimeter / (each.speed_rate*freak_out));
		
		do goto target: target on: road_network move_weights:new_weights ;
		
		if (location distance_to target < 1#m) {
			location <- target;
			target <- nil;
			
		}		
		if (location distance_to evactuation_pick < 1#m) {
			evacuated <- true;
		}	
		
		
		
	}
	
}

// Represents a point of evacuation
species evacuation{
	
	aspect default {
		draw triangle(50) color:#yellow;
	}
}

// Represents the red river
species red_river{
	
	aspect default {
		draw shape color:#blue;
	}
	

	reflex flood_increase when: current_date > flood_date and every(1#minute){
		
		raise_level <- raise_level +0.1;
		shape <- shape +raise_level ;
		
		flood_body <-inhabitant overlapping (self) where (!each.evacuated);
		flood_road <-road overlapping (self) ;
		
	}
		
}



experiment evacuation_exp type: gui {
	
	parameter "Population" var: nb_ppl init: 1000
	min: 100 max: 5000 category: "Population";
	
	parameter "Flood Date" var: flood_date init: date([1980,1,2,3,0,0])
	min: date([1980,1,2,3,0,0]) max: date([1980,1,6,12,0,0]) category: "Flood Date";
	
	parameter "Evacuation point" category:"Evacuation point" var: eva_strategy <- "closest_home" among: ["closest_home","closest_work","random"];
	parameter "News" category:"News" var: news <- "vtv" among: ["vtv","heard"];
		
	parameter "Flood level" var: raise_level init: 5.0
	min: 0.1 max: 10.0 category: "Flood level";
	
	float minimum_cycle_duration <- 0.05;
	
	output {
		display map {
			species building ;
			species road ;
			species inhabitant aspect:default;
			species evacuation aspect: default;
			species red_river;
		}
		display graph {
			chart "evacuees" type: histogram y_range:[0,100] {
				data "% of evacuated people" value: (100 * (inhabitant count (each.evacuated) /length(inhabitant))) color:#green;
				data "% of fleeing people" value: (100 * (inhabitant count (! each.evacuated) /length(inhabitant))) color:#red ;
			}
		}
		display death {
			chart "deaths" type: series  y_range:[0,nb_ppl]{
				data "Number of dead people" value: (dead_count);
			}
		}
		display close_road {
			chart "road" type: series  y_range:[0,750]{
				data "% of closed roads" value:(road count (each.closed));
			}
		}
	
	}
}


/**
* Name: test1
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model test1

/* Insert your model definition here */

global {
	geometry shape <- square(3000#m);
	int grid_size <- 30;
	int max_carrying_capacity <- 10;
	
	float grow_rate <- 0.02;
	
	int nb_wolf <- 3;
	int nb_goat <- 10;
	
	float init_energy <- 100.0;
	
	float max_cabbage_eat <- 2.0;
	
	float reproduction_threshold <- 20.0;
	
	
	init {
		create wolf number: nb_wolf;
		create goat number: nb_goat;
	}
	
}

grid plot height: grid_size width: grid_size neighbors: 8 {
	
	float biomass <- 0.0;
//	float biomass;
	float carrying_capacity <- rnd(5.0);
//	float carrying_capacity;

	bool is_free <- true;
	
	init {
		carrying_capacity <- rnd(carrying_capacity);
		biomass <- rnd(carrying_capacity);
		color <- rgb(0, 255*biomass/max_carrying_capacity, 0);
	}
	
	rgb color <- rgb(0, 255*biomass/max_carrying_capacity, 0)
		update: rgb(0, 255*biomass/max_carrying_capacity, 0);
	
	reflex grow {
		if (carrying_capacity != 0) {
			biomass <- biomass * (1 + grow_rate *(1 - biomass/carrying_capacity));
		}
	}
	
	aspect plotCarryingCapacity {
		draw triangle(50) color: rgb(0, 255*biomass/max_carrying_capacity, 255*biomass/max_carrying_capacity);
	}

}


species animal {
	plot loc;
	float energy <- init_energy;
	
	
	init {
		loc <- one_of(plot where (each.is_free = true));
		
		location <- loc.location;
		loc.is_free <- false;
	}
	
	
	action move_to_cell(plot new_loc) {
		if (loc != nil) {
			loc.is_free <- true;
		}
		
		new_loc.is_free <- false;
		loc <- new_loc;
		location <- new_loc.location;
	}
	
	reflex move {
		plot next_loc <- one_of(loc.neighbors where (each.is_free = true));
		loc.is_free <- true;
		next_loc.is_free <- false;
		loc <- next_loc;
		location <- next_loc.location;

		
	}
	
	reflex ener_loss {
		energy <- energy -1;	
	}
	
	reflex reproduce when: energy >= reproduction_threshold {
		plot loc_for_child <- one_of(loc.neighbors where(each.is_free = true));
		
		if (loc_for_child != nil) {
			create species(self) number: 1 {
				do move_to_cell(loc_for_child);
				self.energy <- myself.energy / 2;
			}
			energy <- energy / 2;
		}
	}
	
	reflex death when: energy <= 0.0 {
		do die;
	}
	
	
	
}


//species wolf {
species wolf parent: animal {
	plot w_loc;
	
//	init {
//////		location <- one_of(plot).location;
////		w_loc <- one_of(plot where (each.is_free = true));
////		location <- w_loc.location;
////		w_loc.is_free <- false;	
//	}

	reflex move {
		plot next_loc <- nil;
		
		list<plot> neigh <- loc.neighbors where(!empty(goat inside each));
		
		if (empty(neigh)) {
			next_loc <- one_of(loc.neighbors where(each.is_free = true));
		}
		else {
			next_loc <- one_of(neigh);
			goat victim <- one_of(goat inside next_loc);
			
			energy <- energy + victim.energy;
			ask victim {
				write "" + self + " will die";
				do die;
			}
		}
		do move_to_cell(next_loc);
		
	}
	
	aspect _wolf {
		draw circle(40) color: #red;
		
	} 
}






species goat parent: animal {
//	plot loc;
//	init {
//// //		location <- one_of(plot).location;
////		loc <- one_of(plot where (each.is_free = true));
////		location <- loc.location;
////		loc.is_free <- false;	
//		
//		plot random_loc <- one_of(plot where (each.is_free = true));
//		do move_to_cell(random_loc);
//	}
	
	aspect _goat {
		draw square(50) color: #blue;
		
	}
	
	reflex eat_cabbage {
		float cab <- min([max_cabbage_eat, loc.biomass]);
		energy <- energy + cab;
		loc.biomass <- loc.biomass - cab;
	}
	
//	reflex move {
////		plot next_loc <- one_of(loc.neighbors where (each.is_free = true));
////		
////		loc.is_free <- true;
////		next_loc.is_free <- false;
////		
////		loc <- next_loc;
////		location <- next_loc.location;
//
//		plot next_loc <- one_of (loc.neighbors where(each.is_free = true));
//		do move_to_cell(next_loc);
//	}
	
//	action move_to_cell(plot new_loc) {
//		if (loc != nil) {
//			loc.is_free <- true;
//		}
//		
//		new_loc.is_free <- false;
//		loc <- new_loc;
//		location <- new_loc.location;
//	}
}


experiment cabbage type: gui {

	output {

		display carrying type: 3d {
			grid plot border: #white;
			species plot aspect: plotCarryingCapacity;
			species goat aspect: _goat;
			species wolf aspect: _wolf;
		}


	}
}
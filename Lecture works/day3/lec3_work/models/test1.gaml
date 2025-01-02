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
	
}

grid plot height: grid_size width: grid_size neighbors: 8 {
	
	float biomass <- 0.0;
//	float biomass;
	float carrying_capacity <- rnd(5.0);
//	float carrying_capacity;
	
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
		draw triangle(50) color: rgb(0, 0, 255*biomass/max_carrying_capacity);
	}

}


experiment cabbage type: gui {

	output {

		display carrying type: 3d {
			grid plot border: #white;
			species plot aspect: plotCarryingCapacity;
		}


	}
}
/**
* Name: test1
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model test1

/* Insert your model definition here */


global {
	/*
	 * Insert global definitions, variables and actions here
	 */
	 
	 init {
	 	write "Executed";
	 	create people number: 200;
	 	
	 }
	
}

species people {
	/*
	 * Define class (species of 
	 */
	 
	 rgb color;
	 int age <- 1 min: 1 max: 100 step: 1;

	reflex move {
		location <- any_location_in(world.shape);
	}
	 
	 init {
	 	if ( flip(0.5) ) {
	 		color <- #red;
	 	} else {
	 		color <- rgb(120, 120, 56);
	 	}
	 }
	 
	 aspect asp_circle {
	 	draw triangle(1.0) color: color border: #black;
	 }
}

species mon_espece {
	
}

experiment Schelling type: gui {
	
	output {
		display people_display {
			species people aspect: asp_circle;
			
		}
	}
	
}

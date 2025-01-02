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
	 
	 float rate_similar_wanted <- 1.0;
	 float neighbours_distance <- 10.0;
	 
	 int nb_happy_people <- 0 update: people count each .is_happy;
	 
	 
	 init {
	 	write "Executed";
	 	write nb_happy_people;
	 	create people number: 2000;
	 	
	 }
	
}

species people {
	/*
	 * Define class (species of 
	 */
	 
	 rgb color;
	 int age <- 1 min: 1 max: 100 step: 1;
	 
	 list<people> neighbours update: people at_distance neighbours_distance;
	 bool is_happy <- false;
	 
	 // behaviors and aspects


	reflex computing_similarity {
		float rate_similar <- 0.0;
		
		if ( empty(neighbours) ) {
			rate_similar <- 1.0;
		}
		else {
			int nb_neighbours <- length(neighbours);
			int nb_neighbours_sim <- neighbours count (each.color = color);
			
			rate_similar <- nb_neighbours_sim/nb_neighbours;
		}
		is_happy <- rate_similar >= rate_similar_wanted;

	}

	reflex move when: not is_happy{
		location <- any_location_in(world.shape);
	}
	
	// other reflex and aspect definitions
	 
	 init {
	 	if ( flip(0.5) ) {
	 		color <- #red;
	 	} else {
	 		color <- rgb(0, 255, 0);
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

experiment Schelling2 type: gui {
	parameter "nb of people" var: nb_happy_people;
	parameter "rate similar wanted" var: rate_similar_wanted min: 0.0 max: 1.0;
	parameter "neighbours distance" var: rate_similar_wanted step: 1.0;
	
	output {
		display people_display {
			species people aspect: asp_circle;
			
		}
	}
	
}

experiment main_xp type: gui {
	
	output {
		display chart {
			chart "evolution of the number of happy people" type: series {
				data "nb of happy people" value: nb_happy_people color: #blue;
			}
			
		}
	}
	
}

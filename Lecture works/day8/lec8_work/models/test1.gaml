/**
* Name: test1
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model ForestFire

/* Insert your model definition here */


global {
	int number_of_agents <- 100 min: 10 max: 100;
	
//	int timeout <- 10;
	
	float percentage_of_chance_to_propagate <- 0.4 min: 0.0 max: 1.0;
	float burning_time <- 10.0 min: 0.0 max: 1000.0;
	
	int number_of_fire_sources <- 10 min: 1 max: 25;
	
	init {
//		ask one_of(parcel)  {
		ask number_of_fire_sources among (parcel)  {
			color <- #red;
		}
	}
}

//grid parcel height: 50 width: 50 schedules: parcel select (each.color = #red) 
grid parcel height: 50 width: 50 schedules: parcel select (each.color = #red) 
{
	
	float timeout <- 10.0;
	rgb color <- #green;
	
	
	reflex burn when: color = #red and world.cycle >= timeout {
		color <- #black;
	}
	
	reflex r when: (color = #red) and flip(percentage_of_chance_to_propagate) {
//		if (color = #red) {
			
//			if (world.cycle >= timeout) {
//				color <- #black;
//			}
//			else 
//			{
			
	//			ask neighbors {
		ask one_of(neighbors) {
			if (color = #green) {
				timeout <- int(world.cycle) + burning_time; 
				color <- #red;
				
			}
		}
			
//			}
//		}
	}
	
}

experiment first {
	parameter "Number of agents" var: number_of_agents min: 10 max: 1000 step: 5;

}

experiment second {
	
	init {
//		create simulation with: [number_of_fire_sources::2];
//		create simulation with: [number_of_fire_sources::4, percentage_of_chance_to_propagate::0.2];
	}
	parameter "Percentage of chance to propagate" var: percentage_of_chance_to_propagate min: 0.0 max: 1.0 step: 0.05;
	parameter "Time to burn" var: burning_time min: 0.0 max: 1000.0;
	parameter "Number of fire source" var: number_of_fire_sources min: 1 max: 25;

	float minimum_cycle_duration <- 0.1;
	
	
	user_command "Add source" {
		ask simulations {
			ask one_of(parcel where (each.color = #green)) {
				color <- #red;
			}
			
		}
		do update_outputs;
	}
	
	
	
	output {
		monitor "Number of burning cells" value: parcel count (each.color = #red);
		
		display  fireSpread type: 3d {
//			grid parcel;
			
			light #ambient intensity: 256;
			
			species parcel {
//				draw shape color: #white border: #black;
				draw shape color: #purple;
				draw circle(color = #red ? 1.0 : 0.8) color: color;
			}
			
			graphics g {
				draw "HEllo" font: ("Cambria", 64, #italic) color: #yellow;
			}
		}
	}
}


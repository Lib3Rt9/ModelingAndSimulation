/**
* Name: ex3
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model ex3

/* Insert your model definition here */

global {
	int agentNumber <- 10;
	float speedConvergence <- 2.0;
	float threshold <- 0.0;
	
	init {
		create people number: agentNumber;
	}
}

species people {
	float opinion <- rnd(1.0);
	rgb c <- rnd_color(255);
	
	reflex beInfluenced {
		people other <- one_of(people - self);
		
		if (other != nil) {
			if (abs(opinion - other.opinion) > threshold) {
				float opinionT1 <- opinion;
				opinion <- opinion + speedConvergence * (other.opinion - opinion);
			
				other.opinion <- other.opinion + speedConvergence * (opinionT1 - other.opinion);
				
			}
		}
		
	}
}

experiment e3 type: gui{
	parameter "Number of agents" var: agentNumber min:1 max: 10;
	parameter "Convergence speed" var: speedConvergence min: 0.0 max: 2.0;
	parameter "Threshold" var: threshold min: 0.0 max: 1.0;
	
	output {
		display d3 {
			chart "chart 3" type: series {
				loop ag over: people {
					data ag.name value: ag.opinion color: ag.c;
				}
			}
		}
	}
}
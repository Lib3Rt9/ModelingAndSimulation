/**
* Name: ex5
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model ex5

/* Insert your model definition here */

global {
	int fieldSize <- 50;
	int diffusionSpeed <- 2;
	int neighborhoodSize <- 8;
	
	init {
		
	}
}

grid fireflyField width: fieldSize height: fieldSize neighbors: 8 {
	float durationOn <- 2.0;
	int switchOnEvery <- 2;
	bool isOn <- false;
	int timeStillOn <- 2;
	
	init {
//		reflex update {
//			
//		}
	}
}


experiment e5 {
	parameter "Field size" var: fieldSize min: 10 max: 100;
	output {
		display d5 {
			grid fireflyField border: #black;
		}
	}
}
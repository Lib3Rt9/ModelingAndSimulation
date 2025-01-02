/**
* Name: ex4
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model ex4

/* Insert your model definition here */

global torus: true {
	int gridSize <- 50;

	int nbInitRumor <- 3;
	
	
	init {
		loop ag over: (nbInitRumor among people) {
			ag.knowRumor <- true;
			ag.color <- #red;
		}
		
	}
}

grid people width: gridSize neighbors: 8 {
	bool knowRumor <- false;
	rgb color <- #white update: (knowRumor) ? #red : #white;
//	rgb color <- #white; // update: (knowRumor) ? #red : #white;
	
	reflex spread when: knowRumor {
		ask one_of(neighbors) {
			knowRumor <- true;
			color <- #red;
		}
	}
}

experiment e4 {
	parameter "Grid dimension" var: gridSize min: 10 max:100;
	
	output {
		display rumor type: 3d {
			grid people border: #black;
		}
	}
}
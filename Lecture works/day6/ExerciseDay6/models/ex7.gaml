/**
* Name: ex7
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model ex7

import "Common Schelling Segregation.gaml"



/* Insert your model definition here */

global {
	int grid_size <- 30;
	
	init {
		// Collect empty cells
        list<plot> empty_cells <- plot where (each.is_free);
        
		create people number: number_of_people {
			
			color <- colors[rnd(number_of_groups - 1)];
//			color <- colors at (rnd(number_of_groups - 1));

			list<plot> empty_cells <- plot where (each.is_free);

			// Find and occupy an empty cell
            if (!empty(empty_cells)) {
                plot my_cell <- one_of(empty_cells);
                location <- my_cell.location;
                my_cell.ppl <- self;
                my_cell.is_free <- false;
                remove my_cell from: empty_cells;
                
             }
		}
	}
	
	action initialize_places{}
	action initialize_people{}
}

grid plot height: grid_size width: grid_size neighbors: 8 {
	
		bool is_free <- true;
		
		people ppl; 
	
}

species people parent: base {
	
	plot my_cell;	
	
//	list<people> my_neighbours -> people at_distance neighbours_distance;
	
	reflex move_to_happy when: !is_happy {
		list<plot> free_cells <- plot where (each.is_free);
		
		if (!empty(free_cells)) {
			if (my_cell != nil) {
				my_cell.ppl <- nil;
				my_cell.is_free <- true;
			}
		}
		
		plot new_cell <- one_of(free_cells);
		location <- new_cell.location;
		new_cell.ppl <- self;
		new_cell.is_free <- false;
		my_cell <- new_cell;
		
		my_neighbours <- (people) at_distance neighbours_distance;
	}
	
	aspect plotPeople {
		draw square(1.5) color: color;
	}
}

experiment e type: gui {
	parameter "Number of people" var: number_of_people init: 100 min: 10 max: 1000;

	
	output {
		display d {
			grid plot border: #black;
			species people aspect: plotPeople;
		}
	}
}
/**
* Name: environment
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: based on test 6
*/



model Driftwood

global {
	
    // Define the dimensions of the environment
    int environment_width <- 100;
    int environment_height <- 100;
    
    // Fixed boundaries - adjusted for more realistic proportions
    int sea_width <- int(environment_width * 0.2);    	// 20% for deep water
    int beach_start <- int(environment_width * 0.65);  	// 65% for tidal zone
    
    // Height parameters for terrain
    float max_beach_height <- 5.0; 			// Maximum height at beach
    float sea_level <- 0.0;   				// Base sea level (0 meters)
    float beach_slope <- max_beach_height / (environment_width - sea_width);  	// Calculate slope

    // Day-Night Cycle parameters
    float day_time <- 0.0;        			// Current time of day (0-24)
    float hour_steps <- 20.0;     			// Number of steps per hour
	float time_speed <- 0.005;      			// Time progression speed
    float day_length <- hour_steps * 24;   	// Length of a full day in simulation steps
    float night_start <- 17.0;    			// Night starts at 17:00 (5 PM)
    float night_end <- 5.0;       			// Night ends at 5:00 (5 AM)
    
    // Tide parameters
    float tide_level <- 0.2;				// Current tide level
    float min_tide <- 0.15;       			// Low tide
    float max_tide <- 1.0;        			// High tide
    float tide_speed <- 0.0008;				// Speed of tide change
    float tide_base <- 0.15;       			// Base tide level (minimum water level)
    
    // Wave parameters
    float wave_amplitude <- 2.0;  			// Height of the wave
    float wave_frequency <- 0.5;  			// Frequency of the wave
    float wave_speed <- 0.2;      			// Speed of wave movement
    float simulation_time <- 0.0;  			// Time counter for wave movement
    float base_wave_level <- 1.0;  			// Parameter to keep waves above baseline
    
    // Wet sand parameters
    float wet_sand_duration <- 500.0;  		// How long the sand stays wet
    

	// Wood parameters
	int initial_wood_number <- 20;      	// Number of wood pieces at start
    float wood_spawn_rate <- 0.2;      		// Probability of spawning wood per step


	// Collector parameters
	int num_collectors <- 10;				// Number of collector(s)

	
	init {
	    create Driftwood number: initial_wood_number {
            // Place wood in the sea near the tidal zone
            float spawn_x <- float(rnd(sea_width - 5.0, sea_width));
//            write "Height range: 0 to " + (environment_height - 1);
            float spawn_y <- rnd(0.0, environment_height - 1.0);  // Subtract 1 to stay within bounds
            location <- {spawn_x, spawn_y};
//            write "Created wood at: (" + spawn_x + ", " + spawn_y + ")";
        }
        
        // Create collectors
//        create Collector number: num_collectors;
	}

	
	
    reflex update_time {
        simulation_time <- simulation_time + wave_speed;
    }
    
    // Day-Night Cycle mechanics
    reflex update_day_time {
	    day_time <- day_time + time_speed;
	    if (day_time >= 24.0) {
	        day_time <- 0.0;
	    }
	}
		
	// Tide cycle mechanics synchronized with day/night
	reflex update_tide {
	    // Determine tide direction based on time of day
	    // 		0-6: Rising to high tide
	    // 		6-12: Falling to low tide
	    // 		12-18: Rising to high tide
	    // 		18-24: Falling to low tide
	    
	    if ((day_time >= 0.0 and day_time < 6.0) or (day_time >= 12.0 and day_time < 18.0)) {
        	// Rising tide periods
	        tide_level <- tide_level + tide_speed;
	        
	        if (tide_level > tide_base + max_tide) {
	            tide_level <- tide_base + max_tide;
	        }
	    } else {
	        // Falling tide periods
	        tide_level <- tide_level - tide_speed;
	        
	        if (tide_level < tide_base + min_tide) {
	            tide_level <- tide_base + min_tide;
	        }
	    }
	}
	
	
	// Wood generation
    reflex generate_wood {
        if (flip(wood_spawn_rate)) {
            create Driftwood number: 1 {
                float spawn_x <- float(rnd(sea_width - 5.0, sea_width));
                float spawn_y <- rnd(0.0, environment_height - 1.0);
                location <- {spawn_x, spawn_y};
            }
        }
    }
    
    
}



// Define beach cells
grid Beach_Cell width: environment_width height: environment_height {
    rgb color <- rgb(255, 222, 173);				// Sandy color - background
    float height <- 0.0;  							// Height of the cell (meters)
    float wave_value <- 0.0;						// Sea need waves
    float wetness <- 0.0;							// Wet
    bool was_underwater <- false;
    rgb base_sand_color <- rgb(255, 222, 173);		// Sandy color - beach
    rgb sea_color <- rgb(0, 105, 148);				// Deep blue - the sea
    rgb shallow_water_color <- rgb(150, 200, 255);	// Light blue - tidal zone
    
    init {
    	// Calculate initial height based on distance from sea
        if (grid_x < sea_width) {
            height <- sea_level;
        } else {
            // Linear increase in height from sea to beach end
            float distance_from_sea <- float(grid_x - sea_width);
            height <- distance_from_sea * beach_slope;
        }
        
        // Calculate waves only once for initial setup
        float y_sin <- sin(wave_frequency * float(grid_y));
        float sec_y_sin <- sin(0.05 * float(grid_y));
        wave_value <- base_wave_level + (wave_amplitude * y_sin) + sec_y_sin;
        
        float adjusted_sea_width <- sea_width + wave_value;
        
        // Initial setup - only distinguish between sea and land
        if (grid_x < adjusted_sea_width) {
            color <- sea_color;
            was_underwater <- true;
        }
    }
    
    reflex update_cell {
        // Calculate wave effect
        float y_factor <- wave_frequency * float(grid_y) + simulation_time;
        wave_value <- base_wave_level + wave_amplitude * sin(y_factor) + sin(0.05 * float(grid_y) + simulation_time * 0.5);
        
        float adjusted_sea_width <- sea_width + wave_value;
        float adjusted_beach_start <- beach_start + wave_value;
        bool is_underwater <- false;
        
        // Zone checking
        if (grid_x < adjusted_sea_width) {
            color <- sea_color;
            is_underwater <- true;
        } else {
            float tide_zone <- adjusted_sea_width + (tide_level * (adjusted_beach_start - adjusted_sea_width));
            
            if (grid_x < tide_zone) {
                color <- shallow_water_color;
                is_underwater <- true;
            } else {
                if (was_underwater) {
                    wetness <- 1.0;
                }
                
                if (wetness > 0) {
                    // Wetness color calculation
                    float wet_factor <- wetness * 40;
                    color <- rgb(
                        255 - wet_factor, 
                        222 - (wet_factor * 0.75), 
                        173 - (wet_factor * 0.5)
                    );
                    wetness <- wetness - (1.0 / wet_sand_duration);
                } else {
                    color <- base_sand_color;
                }
            }
        }
        
        was_underwater <- is_underwater;
    }
}


species Driftwood {
    string size_category;
    float width;
    float height;
    rgb wood_color <- rgb(139,69,19);  			// Brown color for wood
    float rotation <- rnd(360.0);  				// Random initial rotation
    float rotation_speed <- rnd(0.2, 0.9);  	// Random rotation speed between 0.2 and 0.5 degrees per step
    
    bool is_collected <- false;
    bool in_pile <- false;
    
    init {
        // Randomly assign size class
        size_category <- one_of(["small", "medium", "large"]);
        switch size_category { 
            match "small" { 
                width <- 0.8; 
                height <- 0.4; 
            } 
            match "medium" { 
                width <- 1.2; 
                height <- 0.6; 
            } 
            match "large" { 
                width <- 1.6; 
                height <- 0.8; 
            } 
        }
    }
    
    aspect default {
        draw rectangle(width, height) color: wood_color rotate: rotation;
    }
    
    reflex rotate {
        rotation <- rotation + rotation_speed;
        if (rotation >= 360.0) { rotation <- 0.0; }
    }
    
    reflex move when: !is_collected and !in_pile {
        Beach_Cell current_cell <- Beach_Cell(location);
        float previous_tide <- tide_level; 					// Store previous tide level
        
        if (current_cell != nil) {
            // Only move if in water
            if (current_cell.color = current_cell.sea_color or current_cell.color = current_cell.shallow_water_color) {
				// Determine tide direction based on current time period
                bool is_tide_rising <- (day_time >= 0.0 and day_time < 6.0) or (day_time >= 12.0 and day_time < 18.0);
                
                float tide_movement <- 0.0;
                float size_factor;
                float wave_factor;
                                

                // Set movement factor based on wood size
                switch size_category { 
                    match "small" { 
                        size_factor <- is_tide_rising 
                            ? 0.90  	// Rising tide - 10% slower
                            : 0.15;  	// Falling tide - 85% slower
//                        write "Small wood " + name + " factor: " + size_factor;
						wave_factor <- is_tide_rising
                            ? 0.20   	// More wave influence during rising tide
                            : 0.15;  	// Less wave influence during falling tide
                    } 
                    match "medium" { 
                        size_factor <- is_tide_rising
                            ? 0.85  	// Rising tide - 15% slower
                            : 0.10;  	// Falling tide - 90% slower
//                        write "Medium wood " + name + " factor: " + size_factor;
						wave_factor <- is_tide_rising
                            ? 0.15    	// Medium wave influence during rising tide
                            : 0.10;  	// Less wave influence during falling tide
                    } 
                    match "large" { 
                        // Rising tide: 15% slower, Falling tide: 95% slower
                        size_factor <- is_tide_rising
                            ? 0.75  		// Rising tide - 20% slower
                            : 0.05;  		// Falling tide - 95% slower
//                        write "Large wood " + name + " factor: " + size_factor;
						wave_factor <- is_tide_rising
                            ? 0.10   	// Less wave influence during rising tide
                            : 0.05;  	// Minimal wave influence during falling tide
                    } 
                }
                
	            
                // Calculate base movement direction based on tide
                tide_movement <- is_tide_rising 
                    ? tide_speed * size_factor        // Move toward beach during rising tide
                    : -tide_speed * size_factor;      // Move toward sea during falling tide
                
                

                float wave_influence <- sin(simulation_time + location.y * wave_frequency) * wave_factor;
            	location <- location + {tide_movement + wave_influence, 0};
	                

            }
            // If no water, wood stays in place (simply don't move it)
        }
    }
            
}


species Collector skills: [moving] {
    bool has_pile <- false;
    point pile_location <- nil;
    bool carrying_wood <- false;
    rgb color <- #red;
    float speed <- rnd(5.0, 10.0);  		// Random speed between 5-10 km/h
    Driftwood targeted_wood <- nil;
    
    init {
        // Start collectors on the beach area
        location <- {rnd(beach_start, environment_width - 1), rnd(0, environment_height - 1)};
    }
    
    // Randomly change speed
    reflex update_speed {
        if (flip(0.01)) {  // 1% chance to change speed each step
            speed <- rnd(5.0, 10.0);
        }
    }
    
    // Wandering around
    reflex wander when: (targeted_wood = nil) and !carrying_wood {
        do wander amplitude: 120.0 speed: speed / 3.6;  			// Convert km/h to m/s
    }
    
    // Find the wood
    reflex target_wood when: !carrying_wood and targeted_wood = nil {
        list<Driftwood> available_wood <- Driftwood where (!each.is_collected);
        if (!empty(available_wood)) {
            targeted_wood <- available_wood closest_to self;
        }
    }
    
    reflex move_to_wood when: targeted_wood != nil and !carrying_wood {
        do goto target: targeted_wood speed: speed / 3.6;			// Convert km/h to m/s
        if (location distance_to targeted_wood < 1.0) {
            carrying_wood <- true;
            targeted_wood.is_collected <- true;
            if (!has_pile) {
                // Create new pile location on beach
                pile_location <- {rnd(beach_start + 5, environment_width - 5), rnd(5, environment_height - 5)};
                has_pile <- true;
            }
        }
    }
    
    reflex return_to_pile when: carrying_wood {
        do goto target: pile_location speed: speed / 3.6;			// Convert km/h to m/s
        if (location distance_to pile_location < 1.0) {
            carrying_wood <- false;
            create WoodPile {
                location <- myself.pile_location;
                wood_pieces <- myself.targeted_wood;
                owner <- myself;
            }
            ask targeted_wood {
                location <- myself.pile_location;
                in_pile <- true;
            }
            targeted_wood <- nil;
        }
    }
    
    aspect default {
        draw circle(0.5) color: color;
        if (carrying_wood) {
            draw triangle(2) color: #brown rotate: heading + 90;
        }
        
        // Display speed above collector
        draw string(speed with_precision 1) + " km/h" color: #black size: 8 at: {location.x, location.y - 2};
    }
}

species WoodPile {
    Collector owner;
    Driftwood wood_pieces;
    bool has_marker <- true;
    
    aspect default {
        if (has_marker) {
            // Draw pile marker (two stones)
            draw circle(0.5) color: #gray at: {location.x - 0.5, location.y};
            draw circle(0.5) color: #gray at: {location.x + 0.5, location.y};
        }
    }
}







experiment Driftwood_Simulation type: gui {
	// Wave
    parameter "Wave Amplitude" var: wave_amplitude min: 0.5 max: 5.0;
    parameter "Wave Base Level" var: base_wave_level min: 0.5 max: 2.0;
    parameter "Wave Frequency" var: wave_frequency min: 0.05 max: 1.0;
    parameter "Wave Speed" var: wave_speed min: 0.01 max: 1.0;
    
    // Wet sand
    parameter "Wet Sand Duration" var: wet_sand_duration min: 200.0 max: 1000.0;
    
    // Tide
    parameter "Tide Base Level" var: tide_base min: 0.05 max: 0.25;
    parameter "Minimum Tide Level" var: min_tide min: 0.0 max: 0.5;
    parameter "Maximum Tide Level" var: max_tide min: 0.8 max: 1.2;
    parameter "Tide Speed" var: tide_speed min: 0.0001 max: 0.005;
    
    // Time
    parameter "Time Speed" var: time_speed min: 0.001 max: 0.01;


	// Wood
	parameter "Initial Wood Number" var: initial_wood_number min: 5 max: 50;
    parameter "Wood Spawn Rate" var: wood_spawn_rate min: 0.1 max: 0.5;
    
    
    // Collector
    parameter "Number of Collectors" var: num_collectors min: 5 max: 20;
    
    
    output {
        display main_display {
            grid Beach_Cell;
            species Driftwood;
            species Collector;
            species WoodPile;
            
            
            // Time and tide information
	        graphics "Info Display" {
	            // Calculate hours and minutes
			    int display_hours <- int(day_time);
			    int display_minutes <- int((day_time - display_hours) * 60);
			    
			    // Add leading zeros
			    string hours <- display_hours < 10 ? "0" + string(display_hours) : string(display_hours);
			    string minutes <- display_minutes < 10 ? "0" + string(display_minutes) : string(display_minutes);
			    
			    draw "Time: " + hours + ":" + minutes at: {5, 70} color: #black font: font("Default", 10, #bold);
			    draw "Tide Level: " + (round(tide_level * 100) / 100) at: {5, 75} color: #black font: font("Default", 10, #bold);
	            
	            string tide_status <- "";
	            string tide_direction <- "";
	            float mid_tide <- (min_tide + max_tide) / 2;
	            
	            // Determine tide direction
			    if ((day_time >= 0.0 and day_time < 6.0) or (day_time >= 12.0 and day_time < 18.0)) {
			        tide_direction <- "Rising";
			    } else {
			        tide_direction <- "Falling";
			    }
			    
			    draw "Tide Trend: " + tide_status + " " + tide_direction at: {5, 80} color: #black font: font("Default", 10, #bold);
	            
	            // Determine tide height status
			    if (tide_level > mid_tide + (max_tide - mid_tide) * 0.3) {
			        tide_status <- "High Tide";
			    } else if (tide_level < mid_tide - (mid_tide - min_tide) * 0.3) {
			        tide_status <- "Low Tide";
			    } else {
			        tide_status <- "Mid Tide";
			    }
			    
			    draw "Tide Status: " + tide_status at: {5, 85} color: #black font: font("Default", 10, #bold);
			    
			    // Height information for mouse hover
                point mouse_loc <- #user_location;
				    if (mouse_loc != nil) {
				        // Convert mouse location to grid coordinates
				        point grid_loc <- {int(mouse_loc.x * environment_width / world.shape.width), 
				                          int(mouse_loc.y * environment_height / world.shape.height)};
				        
				        // Check if the location is within grid bounds
				        if (grid_loc.x >= 0 and grid_loc.x < environment_width and 
				            grid_loc.y >= 0 and grid_loc.y < environment_height) {
				            
				            Beach_Cell cell <- Beach_Cell[int(grid_loc.x), int(grid_loc.y)];
				            if (cell != nil) {
				                draw "Height: " + (round(cell.height * 100) / 100) + "m" 
				                    at: {5, 90} color: #black font: font("Default", 10, #bold);
				            }
				        }
				    }
	        }
	        
        }
        
	    // Monitors to track values
		monitor "Current Time" value: (int(day_time) < 10 ? "0" : "") + string(int(day_time)) + ":" + 
		    (int((day_time - int(day_time)) * 60) < 10 ? "0" : "") + string(int((day_time - int(day_time)) * 60));
     	monitor "Average Height" value: mean(Beach_Cell collect each.height);
	    monitor "Tide Level" value: round(tide_level * 100) / 100;
	    monitor "Day/Night" value: (day_time >= night_start or day_time < night_end) ? "Night" : "Day";
    }

}

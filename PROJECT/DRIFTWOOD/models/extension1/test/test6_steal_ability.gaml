/**
* Name: Exension 1
* 					Reduce speed in water
* 					Stealing ability
* Author: Lib3Rt9
* 
*/



model Driftwood

global {
	
    // Define the dimensions of the environment
    int environment_width <- 100;
    int environment_height <- 100;
    
    // Fixed boundaries - adjusted for more realistic proportions
    int sea_width <- int(environment_width * 0.2);    		// 20% for deep water
    int beach_start <- int(environment_width * 0.65);  		// 65% for tidal zone
    
    // Height parameters for terrain
    float max_beach_height <- 5.0; 							// Maximum height at beach
    float sea_level <- 0.0;   								// Base sea level (0 meters)
    float beach_slope <- max_beach_height / (environment_width - sea_width);  	// Calculate slope

    // Day-Night Cycle parameters
    float day_time <- 0.0;        							// Current time of day (0-24)
    float hour_steps <- 20.0;     							// Number of steps per hour
	float time_speed <- 0.005;      						// Time progression speed
    float day_length <- hour_steps * 24;   					// Length of a full day in simulation steps
    float night_start <- 17.0;    							// Night starts at 17:00 (5 PM)
    float night_end <- 5.0;       							// Night ends at 5:00 (5 AM)
    
    // Tide parameters
    float tide_level <- 0.2;								// Current tide level
    float min_tide <- 0.15;       							// Low tide
    float max_tide <- 1.0;        							// High tide
    float tide_speed <- 0.0008;								// Speed of tide change
    float tide_base <- 0.15;       							// Base tide level (minimum water level)
    
    // Wave parameters
    float wave_amplitude <- 1.0;  							// Height of the wave
    float wave_frequency <- 0.5;  							// Frequency of the wave
    float wave_speed <- 1.0;      							// Speed of wave movement
    float simulation_time <- 0.0;  							// Time counter for wave movement
    float base_wave_level <- 1.0;  							// Parameter to keep waves above baseline
    
    // Wet sand parameters
    float wet_sand_duration <- 1000.0;  					// How long the sand stays wet
    

	// Wood parameters
	int initial_wood_number <- 20;      					// Number of wood pieces at start
    float wood_spawn_rate <- 0.02;      					// Probability of spawning wood per step

	// Spatial optimization
	float spatial_step <- 1.0;      						// Minimum distance for movement
	
	// Collector parameters
	int num_collectors <- 5;								// Number of collector(s)
    float min_greed <- 0.3;        							// Minimum chance to continue collecting
    float max_greed <- 0.8;        							// Maximum chance to continue collecting
	float collector_fov <- 100.0;          					// Field of view in degrees
    float collector_view_distance <- 10.0;  				// View distance in meters
    
    float initial_steal_chance <- 0.1;    					// Initial 10% steal chance
	float steal_chance_increase <- 0.01;   					// 1% increase per successful theft
	float max_steal_chance <- 0.2;        					// Maximum 20% steal chance
    
    
    //////
    int cleanup_interval <- 100;  							// Cleanup every 100 cycles
    bool debug_mode <- true;      							// Enable debug messages
    //////
    
	//////////////
	bool simulation_ended <- false;
	//////////////
	
	
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
        create Collector number: num_collectors;
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
    
    
    
    // Cleanup dead or invalid objects
    reflex cleanup_objects when: every(cleanup_interval) {
        // Clean up invalid wood piles
        ask WoodPile where (each.pile_value <= 0 or each.owner = nil or dead(each.owner)) {
            if (debug_mode) { write "Cleaning up invalid wood pile"; }
            do die;
        }
        
        // Clean up invalid driftwood
        ask Driftwood where (each.location = nil) {
            if (debug_mode) { write "Cleaning up invalid driftwood"; }
            do die;
        }
        
        // Reset stuck collectors
        ask Collector where (each.speed <= 0) {
            if (debug_mode) { write "Resetting stuck collector"; }
            speed <- rnd(0.0, 8.0);  // Changed from each.speed to just speed
        }
    }
    
    // Stop the simulation when the value of a wood pile reaches 100
    reflex check_end_condition {
	    if (simulation_ended) { return; }
	    
	    list<WoodPile> winning_piles <- WoodPile where (
	        each != nil and                				   	// Check pile exists
    		!dead(each) and                 				// Make sure pile is not dead
	        each.pile_value >= 20 and         				// Check value threshold
	        each.wood_pieces != nil and       				// Ensure wood pieces exist
	        !dead(each.wood_pieces)           				// Make sure wood pieces are not dead
	    );
	    
	    if (!empty(winning_piles)) {
	        simulation_ended <- true;
	        do pause;
	        
	        write "\n=== SIMULATION ENDED ===";
	        write "Time: " + day_time;
	        write "Winning pile(s):";
	        
	        loop pile over: winning_piles {
	            write "- Owner: " + pile.owner + " | Value: " + pile.pile_value;
	        }
	        write "=====================\n";
	    }
	    
	    // Add safety checks for critical conditions
	    if (cycle > 0 and empty(Collector)) {
	        write "WARNING: No collectors left in simulation!";
	        do pause;
	    }
	    
	    if (cycle > 0 and empty(Driftwood) and wood_spawn_rate <= 0) {
	        write "WARNING: No wood pieces and spawn rate is 0!";
	        do pause;
	    }
	}
    
}	// GLOBAL END
//////////////////////////////////////////


// Environment - beach cells
grid Beach_Cell width: environment_width height: environment_height {
    rgb color <- rgb(255, 222, 173);						// Sandy color - background
    
    float height <- 0.0;  									// Height of the cell (meters)
    
    float wave_value <- 0.0;								// Sea need waves
    
    float wetness <- 0.0;									// Wet
    bool was_underwater <- false;
    
    rgb base_sand_color <- rgb(255, 222, 173);				// Sandy color - beach
    rgb sea_color <- rgb(0, 105, 148);						// Deep blue - the sea
    rgb shallow_water_color <- rgb(150, 200, 255);			// Light blue - tidal zone
    
    float get_water_depth {
        if (	color = sea_color 
        	or 
        		color = shallow_water_color
        ) {
        	float base_water_level <- tide_level * max_beach_height; 	// Convert tide level to actual height
        	float depth <- base_water_level - height;  		// Water level $ - $ terrain height
        	
            return max(0.0, depth);							// No negative depth
        }
        
        return 0.0; // No water
    }
    
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
    
    reflex update_cell when: every(2 #cycles) {
	    // Quick check if update needed
        if (grid_x > beach_start and !was_underwater) { return; }
	    
	    // Calculate wave effect
	    float y_factor <- wave_frequency * float(grid_y) + simulation_time;
//	    wave_value <- base_wave_level 
//	    					+ wave_amplitude 
//	    					* sin(y_factor) 
//	    					+ sin(0.05 * float(grid_y) 
//	    					+ simulation_time * 0.5
//	    				);
		wave_value <- base_wave_level 
							+ wave_amplitude 
							* sin(simulation_time 
								* 0.5 
								+ grid_y 
								* 0.1
							);
	    
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



// Driftwood species
species Driftwood {
    string size_category;
    float width;											// wood width
    float height;											// wood height
    int value;												// wood weight
    
    rgb wood_color <- rgb(139,69,19);  						// Brown color for wood
    
    float rotation <- rnd(360.0);  							// Random initial rotation
    float rotation_speed <- rnd(0.2, 0.9);  				// Random rotation speed between 0.2 and 0.9 degrees per step
    
    bool is_collected <- false;								// wood status
    bool in_pile <- false;									// wood status
    
    init {
        // Randomly assign size class
        size_category <- one_of(["small", "medium", "large"]);
        switch size_category { 
            match "small" { 
                width <- 0.8; 
                height <- 0.4; 
                value <- 1;
            } 
            match "medium" { 
                width <- 1.2; 
                height <- 0.6; 
                value <- 3;
            } 
            match "large" { 
                width <- 1.6; 
                height <- 0.8;
                value <- 5;
            } 
        }
    }
    
    aspect default {
        // Only draw wood that is not collected
        if (!is_collected) {
	        draw rectangle(width, height) color: wood_color rotate: rotation;
	        
        } else {
            // Only draw if it's in a pile (on the beach)
            if (in_pile) {
                draw rectangle(width, height) color: wood_color rotate: rotation;
            }
        }
    }
    
    reflex rotate when: !is_collected {
        rotation <- rotation + rotation_speed;
        if (rotation >= 360.0) { rotation <- 0.0; }
    }
    
    reflex move when: !is_collected and !in_pile {
        Beach_Cell current_cell <- Beach_Cell(location);
        
        if (current_cell != nil) {
            // Only move if in water
            if (current_cell.color = current_cell.sea_color or current_cell.color = current_cell.shallow_water_color) {
				// Determine tide direction based on current time period
                bool is_tide_rising <- (day_time >= 0.0 and day_time < 6.0) or (day_time >= 12.0 and day_time < 18.0);
                
                float tide_movement <- 0.0;
                float size_factor;
//                float wave_factor;
                                

                // Set movement factor based on wood size
                switch size_category { 
                    match "small" { 
                        size_factor <- is_tide_rising 
                            ? 60.0  						// Rising tide
                            : 30.0;  						// Falling tide
                    } 
                    match "medium" { 
                        size_factor <- is_tide_rising
                            ? 50.0  						// Rising tide
                            : 20.0;  						// Falling tide
                    } 
                    match "large" { 
                        size_factor <- is_tide_rising
                            ? 40.0  						// Rising tide
                            : 10.0;  						// Falling tide
                    } 
                }
                
	            
                // Calculate base movement direction based on tide
                tide_movement <- is_tide_rising 
                    ? tide_speed * size_factor        		// Tide rising - move toward beach
                    : -tide_speed * size_factor;      		// Tide falling - move toward sea
                
                
				float wave_factor <- size_category = "small" ? 0.020 : (size_category = "medium" ? 0.015 : 0.010);
                float wave_influence <- sin(simulation_time + location.y * wave_frequency) * wave_factor;
            	location <- location + {tide_movement + wave_influence, 0};
	                

            }
        }
    }
            // If no water, wood stays in place (simply don't move it)
            
}


// Collector species
species Collector skills: [moving] {
    bool has_pile <- false;
    point pile_location <- nil;								// For a random location on beach
    
    rgb color <- #red;										// General color
    rgb owner_color <- #blue;								// Pile owner color
    
    float speed <- rnd(0.0, 8.0);  							// Speed random from 0.0 to 8.0 km/h
    float acceleration <- 0.1;                   			// Gradual speed change
    float max_speed_change <- 2.0;              			// Max speed change allowed
    float wander_speed_factor <- 0.5;           			// Slower speed while wandering
    
    Driftwood targeted_wood <- nil;							// Of course need target
    
    list<Driftwood> carried_wood <- [];						// List of carried wood
    int current_carried_value <- 0;							// Each wood piece has value
    int max_carrying_value <- 10;							// Not exceed 10
    float greed <- rnd(min_greed, max_greed);     			// Individual greed factor - chance to continue collecting
    
    float max_water_depth <- max_beach_height;  			// Max possible water depth
    float water_speed_reduction <- 0.7;         			// Max speed reduction in deepest water (70%)
    
    // for stealing
    float fov <- collector_fov;								// Field of view
    float view_distance <- collector_view_distance;			// View distance
	
	map<point,bool> fov_cache;								// Cache for FOV calculations
    int cache_duration <- 5;  								// Cache duration in cycles
    int last_cache_update <- 0;
    
    bool is_stealing <- false;           					// Current stealing state
    WoodPile target_pile <- nil;         					// Target pile for stealing

	float steal_chance <- initial_steal_chance;  			// Individual steal chance starts at 10%
	int successful_steals <- 0;                  			// Track successful steals


    init {
	    // Start collectors on the beach area
	    location <- {rnd(beach_start, environment_width - 1), rnd(0, environment_height - 1)};
	    
	    // Initialize pile location right away
	    pile_location <- {
	        rnd(beach_start + 5, environment_width - 5),
	        rnd(5, environment_height - 5)
	    };
	}
    
    
    // Randomly change speed
    reflex update_speed {
        if (flip(0.5)) {  								// 50% chance to change speed each step
            speed <- rnd(0.0, 8.0);
        }
        
        // Speed reduction based on carried wood value
        if (!empty(carried_wood)) {
            // Reduction factor: more value = more reduction, 1 point = 10% reduce
            float wood_reduction_factor <- 1.0 - ( current_carried_value 
            										/ max_carrying_value
            										);
            wood_reduction_factor <- max(0.2, wood_reduction_factor);	// Min speed = 20% original speed
            
            speed <- speed * wood_reduction_factor;
        }
        
        
        Beach_Cell current_cell <- Beach_Cell(location);
        
        // Speed reduction based on water depth 
        if (current_cell != nil) {
            float water_depth <- current_cell.get_water_depth();
            
            if (water_depth > 0) {
                // Reduction factor: deeper = slower
                float depth_factor <- min(1.0, water_depth / max_water_depth);
                float water_reduction_factor <- 1.0 - (depth_factor 
                										* water_speed_reduction
                										);
                speed <- speed * water_reduction_factor;
                
                speed <- max(speed, 0.5);  				// Min speed = 0.5 km/h in water
            }
        }
    }
    
    // Wandering around
    reflex wander when: (targeted_wood = nil) and empty(carried_wood) {
        do wander amplitude: 60.0 speed: speed / 3.6;  			// Convert km/h to m/s
    }
    
    // Field of view calculations
    bool is_in_fov(point target_loc) {
        // If target location is nil, it's not in FOV
        if (target_loc = nil) { return false; }
        
        // Quick distance check first (most efficient rejection)
        float distance <- location distance_to target_loc;
        if (distance > view_distance) { 
            fov_cache[target_loc] <- false;
            last_cache_update <- cycle;
            return false; 
        }
        
        // Check cache if available and not too old
        if (fov_cache contains_key target_loc and cycle - last_cache_update < cache_duration) {
            return fov_cache[target_loc];
        }
        
        // Calculate angle to target relative to agent's heading
        float dx <- target_loc.x - location.x;
        float dy <- target_loc.y - location.y;
        float angle_to_target <- atan2(dy, dx) * (180/#pi);  // Convert to degrees
        
        // Normalize angles to 0-360 range
        float normalized_heading <- float(heading mod 360);
        if (normalized_heading < 0) { normalized_heading <- normalized_heading + 360; }
        
        angle_to_target <- float(angle_to_target mod 360);
        if (angle_to_target < 0) { angle_to_target <- angle_to_target + 360; }
        
        // Calculate angular difference
        float angle_diff <- abs(normalized_heading - angle_to_target);
        if (angle_diff > 180) { angle_diff <- 360 - angle_diff; }
        
        // Check if target is within FOV
        bool is_visible <- angle_diff <= fov/2;
        
        // Update cache
        fov_cache[target_loc] <- is_visible;
        last_cache_update <- cycle;
        
        return is_visible;
    }
	  
    // Clear cache periodically
    reflex clear_fov_cache when: every(cache_duration) {
        fov_cache <- [];
    }
    
    // See the wood in FoV only
    list<Driftwood> get_visible_wood(list<Driftwood> wood_pieces) {
        return wood_pieces where (is_in_fov(each.location));
    }
    
    // Find the wood
    reflex target_wood when: empty(carried_wood) and targeted_wood = nil and every(3 #cycles) {  // Added every(3)
//    reflex target_wood when: empty(carried_wood) and targeted_wood = nil and every(3 #cycles) {
//        list<Driftwood> available_wood <- Driftwood 
//            where (
//                !each.is_collected 
//            and
//                !each.in_pile
//            and
//                current_carried_value + each.value <= max_carrying_value
//            );
//        
//        // Filter wood by FOV
//        available_wood <- available_wood where (is_in_fov(each.location));
//        
//        if (!empty(available_wood)) {
//            targeted_wood <- available_wood closest_to self;
//        }
//    }
        list<Driftwood> nearby_wood <- Driftwood at_distance view_distance  // Use spatial query instead of where
            where (!each.is_collected and !each.in_pile);
        
        if (!empty(nearby_wood)) {
            targeted_wood <- nearby_wood closest_to self;
        }
    }
    
    // Check if the target wood is available
    reflex check_targeted_wood when: targeted_wood != nil {
	    if (targeted_wood.is_collected or (current_carried_value + targeted_wood.value > max_carrying_value)) {
        	targeted_wood <- nil;  // Reset target
            
            // Immediately look for new wood
            list<Driftwood> available_wood <- Driftwood 
	            where (
	                !each.is_collected 
	            and 
	                !each.in_pile
	            and
	                current_carried_value + each.value <= max_carrying_value
	            );
            
            if (!empty(available_wood)) {
                targeted_wood <- available_wood closest_to self;
            }
        }
    }
    
    // Move to wood
    reflex move_to_wood when: targeted_wood != nil {
        // Safety timeout - prevent infinite pursuit
        if (location distance_to targeted_wood > 50.0) {
            targeted_wood <- nil;
            return;
        }
        
        // Check for valid speed
        if (speed <= 0) {
            speed <- rnd(0.0, 8.0);
        }
        
        if (dead(targeted_wood) or targeted_wood = nil) {
	        targeted_wood <- nil;
	        return;
	    }
        
        if (targeted_wood.is_collected) {
            // If targeted wood was collected by another collector, immediately find new target
            targeted_wood <- nil;
            return;
        }
    
        // Only move if distance significant
        if (location distance_to targeted_wood > spatial_step) {
            do goto target: targeted_wood speed: speed / 3.6;
        }
        
        if (location distance_to targeted_wood < 1.0) {
            // Collect the wood piece
            carried_wood <- carried_wood + targeted_wood;
            current_carried_value <- current_carried_value + targeted_wood.value;
            targeted_wood.is_collected <- true;
            
            // Create pile location if don't have one yet
            if (!has_pile) {
                pile_location <- {
                        rnd(beach_start + 5, environment_width - 5),
                        rnd(5, environment_height - 5)
                };
                has_pile <- true;
            }
            
            // Decision to continue collecting or return to pile
            bool continue_collecting <- flip(greed * (1 - (current_carried_value / max_carrying_value)));
            
            if (!continue_collecting) {
                targeted_wood <- nil;
                return;
            }
            
            // Look for next wood if decided to continue
            list<Driftwood> available_wood <- Driftwood 
                where (
                    !each.is_collected 
                and 
                    !each.in_pile
                and
                    current_carried_value + each.value <= max_carrying_value
                );
                
            if (!empty(available_wood)) {
                targeted_wood <- available_wood closest_to self;
            } else {
                targeted_wood <- nil;
            }
        }
    }
    
    // Take wood to pile
    reflex return_to_pile when: (!empty(carried_wood) and (
        current_carried_value = max_carrying_value or  		// At max capacity
        targeted_wood = nil  								// Decided to return or no more wood available
    )) {
    	// Check if pile_location is nil and create one if needed
	    if (pile_location = nil) {
	        pile_location <- {
	            rnd(beach_start + 5, environment_width - 5),
	            rnd(5, environment_height - 5)
	        };
	    }
	    
        do goto target: pile_location speed: speed / 3.6;
    
	    if (location distance_to pile_location < 1.0) {
	        loop wood over: carried_wood {
	            create WoodPile {
	                location <- myself.pile_location;
	                wood_pieces <- wood;
	                owner <- myself;
	            }
	            ask wood {
	                location <- myself.pile_location;
	                in_pile <- true;
	            }
	        }
	        carried_wood <- [];
	        current_carried_value <- 0;
	        targeted_wood <- nil;
	        
	        if (!has_pile) {
	            color <- owner_color;
	        }
	        has_pile <- true;
	    }
	}
    
    // Check if a pile is being observed
    bool is_pile_observed(WoodPile pile) {
        Collector owner <- pile.owner;
        if (owner = nil) { return false; }
        
        // Check if both pile and potential thief (self) are within owner's FOV
        return owner.is_in_fov(pile.location) and owner.is_in_fov(self.location) and 
               (owner.location distance_to pile.location <= owner.view_distance);
    }
    
    // Find stealable piles
    list<WoodPile> get_stealable_piles {
        return WoodPile where (
            each.owner != self and           				// Not own pile
            !is_pile_observed(each) and      				// Not being observed
            each.pile_value > 0 and          				// Has wood to steal
            is_in_fov(each.location)         				// Within FOV
        );
    }
    // Attempt stealing when conditions are right
    reflex consider_stealing when: empty(carried_wood) and !is_stealing and every(5 #cycles) {
	    if (flip(steal_chance)) {
	        list<WoodPile> potential_targets <-get_stealable_piles();
	        
	        if (!empty(potential_targets)) {
	            target_pile <- potential_targets with_max_of(each.pile_value);
	            is_stealing <- true;
	        }
	    }
	}
    
    // Move to target pile for stealing
	reflex move_to_steal when: is_stealing and target_pile != nil {
	    // Validate target pile still exists
	    if (dead(target_pile) or target_pile = nil) {
	        is_stealing <- false;
	        target_pile <- nil;
	        return;
	    }
	    
	    // Validate owner still exists
	    if (target_pile.owner = nil or dead(target_pile.owner)) {
	        is_stealing <- false;
	        target_pile <- nil;
	        return;
	    }
	    
	    // Check if pile still has value
	    if (target_pile.pile_value <= 0) {
	        is_stealing <- false;
	        target_pile <- nil;
	        return;
	    }
	    
	    if (target_pile.owner.is_in_fov(target_pile.location)) {
	        // Cancel stealing if pile becomes observed by owner
	        is_stealing <- false;
	        target_pile <- nil;
	        return;
	    }
	    
	    do goto target: target_pile.location speed: speed / 3.6;
	    
	    if (location distance_to target_pile.location < 1.0) {
	        // Attempt to steal wood
	        list<Driftwood> stealable_wood <- Driftwood where (
	            each.location = target_pile.location and
	            each.in_pile and
	            !dead(each) and
	            current_carried_value + each.value <= max_carrying_value
	        );
	        
	        if (!empty(stealable_wood)) {
	            // Can steal multiple pieces up to carrying capacity
	            loop while: (!empty(stealable_wood) and current_carried_value < max_carrying_value) {
	                Driftwood stolen_wood <- stealable_wood first_with (current_carried_value + each.value <= max_carrying_value);
	                if (stolen_wood != nil and !dead(stolen_wood)) {
	                    stolen_wood.in_pile <- false;
	                    carried_wood <- carried_wood + stolen_wood;
	                    current_carried_value <- current_carried_value + stolen_wood.value;
	                    stealable_wood >- stolen_wood;
	                    
	                    // Increase steal chance after successful theft
	                    steal_chance <- min(max_steal_chance, steal_chance + steal_chance_increase);
	                    successful_steals <- successful_steals + 1;
	                }
	            }
	            
	            // Reset stealing state
	            is_stealing <- false;
	            target_pile <- nil;
	        }
	    }
	}
    
    
    
    aspect default {
        draw circle(0.5) color: color;
        if (!empty(carried_wood)) {
            draw triangle(2) color: #brown rotate: heading + 90;
        }
        
        // Add crown for pile owners
        if (has_pile) {
            draw triangle(1) color: #blue at: {location.x, location.y - 1} rotate: 180;
        }
        
        // Visualize FOV
        point p1 <- {
            location.x + view_distance * cos(heading - fov/2),
            location.y + view_distance * sin(heading - fov/2)
        };
        point p2 <- {
            location.x + view_distance * cos(heading + fov/2),
            location.y + view_distance * sin(heading + fov/2)
        };
        
        draw polyline([location, p1]) color: rgb(200,200,200,200);
        draw polyline([location, p2]) color: rgb(200,200,200,200);
        // Draw FOV area as a fan shape
        list<point> fan_vertices <- [location];
        int segments <- 20;  								// Number of segments to make the fan smooth
        loop i from: 0 to: segments {
            float ratio <- i / segments;
            float current_angle <- heading - fov/2 + ratio * fov;
            point vertex <- {
                location.x + view_distance * cos(current_angle),
                location.y + view_distance * sin(current_angle)
            };
            fan_vertices <- fan_vertices + vertex;
        }
        draw polygon(fan_vertices) color: rgb(200,100,100,50);
        
        // Show water effect and other info
        Beach_Cell current_cell <- Beach_Cell(location);
        string water_info <- "";
        
        if (current_cell != nil) {
            float depth <- current_cell.get_water_depth();
            if (depth > 0) {
                water_info <- " [Depth: " + (depth with_precision 2) + "]";
            }
        }
        
        // Display info above collector
        draw string(speed with_precision 1) + " km/h" 
		    + " [" + current_carried_value + "/" + max_carrying_value + "]"
		    + " Steal:" + (int(steal_chance * 100)) + "%"
		    + water_info
		    color: #black size: 8 at: {location.x, location.y - 2};
    }
}


/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
// WoodPile - owned by collector
species WoodPile {
    Collector owner;
    Driftwood wood_pieces;
    bool has_marker <- true;
//    int pile_value <- 0 update: length( Driftwood 
//    								where (each.location = location)
//    							) * wood_pieces.value;
    int pile_value <- 0;
	
    float creation_time <- time;              				// When pile was created
    int times_stolen_from <- 0;             				// Count of successful thefts
    float last_theft_time <- -1.0;         				   	// Time of last theft
    float stability_score <- 1.0;
    
    // Count all wood pieces at this location
    reflex update_pile_value {
	    if (location = nil or dead(self)) { return; }
	    
//	    list<Driftwood> woods_in_pile <- Driftwood where (
//	        each != nil and 
//	        !dead(each) and
//	        each.location = location and 
//	        each.in_pile and
//	        each.is_collected  // Add this check to ensure wood is actually collected
//	    );
//	    
//	    if (!empty(woods_in_pile)) {
//	        pile_value <- sum(woods_in_pile collect (each.value));
//	    } else {
//	        pile_value <- 0;
//	    }
	    
	    list<Driftwood> woods_in_pile <- Driftwood at_distance 1.0  // Use spatial query
            where (each.in_pile and each.is_collected);
        
        pile_value <- sum(woods_in_pile collect (each.value));
	}
    
    // Calculate pile stability based on theft history
    float calculate_stability {
        if (times_stolen_from = 0) { return 1.0; }
        
        float time_factor <- (time - creation_time) / 1000;  // Normalize time
        float theft_rate <- times_stolen_from / time_factor;
        return max(0.0, 1.0 - theft_rate) with_precision 2;
    }
    
    // Calculate only every 10 cycles
    reflex update_stability when: every(10 #cycles) {
        stability_score <- calculate_stability();
    }
    
    // Track when wood is stolen
    reflex update_theft_tracking {
        int current_wood_count <- length(Driftwood where (each.location = location and each.in_pile));
        if (current_wood_count < pile_value) {
            if (time - last_theft_time > 10) {  // Minimum time between theft counts
                times_stolen_from <- times_stolen_from + 1;
                last_theft_time <- time;
            }
            pile_value <- current_wood_count;
        }
    }
    
    aspect default {
	    if (has_marker) {
	        // Draw pile marker (two stones)
	        draw circle(0.5) color: #black at: {location.x - 0.5, location.y};
	        draw circle(0.5) color: #black at: {location.x + 0.5, location.y};
	        
	        // Clear previous text by drawing a white background
	        draw rectangle(3, 1) color: #white at: {location.x, location.y - 1};
	        
	        // Show pile value and stability with background
	        draw string(pile_value) + " [" + (stability_score with_precision 2) + "]" 
	            color: #black 
	            size: 8 
	            at: {location.x, location.y - 1};
	            
	        // Stability visualization circle
	        int red_component <- int(255 * (1-stability_score));
	        int green_component <- int(255 * stability_score);
	        draw circle(1.0) border: rgb(red_component, green_component, 0) 
	                        color: rgb(red_component, green_component, 0, 100);
	    }
	}
    
}





// EXPERIMENT TIME
/////////////////////////////////
experiment Driftwood_Simulation type: gui {
	// Wave
    parameter "Wave Amplitude" var: wave_amplitude min: 0.5 max: 5.0;
    parameter "Wave Base Level" var: base_wave_level min: 0.5 max: 2.0;
    parameter "Wave Frequency" var: wave_frequency min: 0.1 max: 1.9;
    parameter "Wave Speed" var: wave_speed min: 0.1 max: 1.9;
    
    // Wet sand
    parameter "Wet Sand Duration" var: wet_sand_duration min: 200.0 max: 1800.0;
    
    // Tide
    parameter "Tide Base Level" var: tide_base min: 0.05 max: 0.25;
    parameter "Minimum Tide Level" var: min_tide min: 0.0 max: 0.5;
    parameter "Maximum Tide Level" var: max_tide min: 0.8 max: 1.25;
    parameter "Tide Speed" var: tide_speed min: 0.0001 max: 0.0015;
    
    // Time
    parameter "Time Speed" var: time_speed min: 0.001 max: 0.01;


	// Wood
	parameter "Initial Wood Number" var: initial_wood_number min: 5 max: 50;
    parameter "Wood Spawn Rate" var: wood_spawn_rate min: 0.01 max: 0.11;
    
    
    // Collector
    parameter "Number of Collectors" var: num_collectors min: 2 max: 10;
	parameter "Minimum Greed" var: min_greed min: 0.0 max: 1.0;
    parameter "Maximum Greed" var: max_greed min: 0.0 max: 1.0;
    parameter "Initial Steal Chance" var: initial_steal_chance min: 0.0 max: 0.5;
	parameter "Max Steal Chance" var: max_steal_chance min: 0.1 max: 0.9;
	parameter "Steal Chance Increase" var: steal_chance_increase min: 0.001 max: 0.05;
    
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
		monitor "Current Time" value: (int(day_time) < 10 ? "0" : "") 
										+ string(int(day_time)) + ":" 
										+ (int((day_time - int(day_time)) * 60) < 10 ? "0" : "") 
										+ string(int((day_time - int(day_time)) * 60));
	    monitor "Day/Night" value: (day_time >= night_start or day_time < night_end) ? "Night" : "Day";
     	
     	monitor "Average Height" value: mean(Beach_Cell collect each.height);
	    monitor "Tide Level" value: round(tide_level * 100) / 100;
	   
	    monitor "Highest Pile Value" value: empty(WoodPile) ? 0 : max(WoodPile collect each.pile_value);
	    monitor "Average Pile Stability" value: empty(WoodPile) ? 0 : (mean(WoodPile collect (
	    												min(1.0, 
	    												max(0.0, each.stability_score)))) 
	    												with_precision 2);
        
        monitor "Total Thefts" value: sum(WoodPile collect each.times_stolen_from);
        
        monitor "Active Collectors" value: length(Collector);
		monitor "Active Wood Pieces" value: length(Driftwood);
		monitor "Active Piles" value: length(WoodPile);
		
		monitor "Current Cycle" value: cycle;
    }

}




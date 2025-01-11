/**
* Name: Exension 3
* 					based on test 5
* 					Group and perturbation
* Author: Lib3Rt9
* 
*/



model Driftwood

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
global {
	
	// ENVIRONMENT		/////////////////////////////////////////////////////////////////////////
    
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
	float time_speed <- 0.003;      						// Time progression speed
    float day_length <- hour_steps * 24;   					// Length of a full day in simulation steps
    float night_start <- 17.0;    							// Night starts at 17:00 (5 PM)
    float night_end <- 5.0;       							// Night ends at 5:00 (5 AM)
    
    // Tide parameters
    float tide_level <- 0.2;								// Current tide level
    float min_tide <- 0.15;       							// Low tide
    float max_tide <- 1.0;        							// High tide
    float tide_speed <- 0.0005;								// Speed of tide change
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
	
	
	// EXTENSION 1 		/////////////////////////////////////////////////////////////////////////
	
	// Collector parameters
	int num_collectors <- 8;								// Number of collector(s)
    float min_greed <- 0.3;        							// Minimum chance to continue collecting
    float max_greed <- 0.8;        							// Maximum chance to continue collecting
	
	float collector_fov <- 100.0;          					// Field of view in degrees
    float collector_view_distance <- 10.0;  				// View distance in meters
    
    float initial_steal_chance <- 0.3;    					// Initial 30% steal chance
	float steal_chance_increase <- 0.02;   					// 2% increase per successful theft
	float max_steal_chance <- 0.5;        					// Maximum 50% steal chance
    
    float system_stability <- 0.0 
    			update: calculate_system_stability();
    
    // EXTENSION 2 		/////////////////////////////////////////////////////////////////////////
    
    // External Authority parameters
    bool enable_authority <- true;                          // Toggle authority presence
    int num_authorities <- 2;                              	// Number of authority agents
    
    float authority_fov <- 120.0;                          	// Authority field of view
    float authority_view_distance <- 15.0;                  // Authority view range
    float authority_speed <- 1.5;                          	// Authority movement speed
    
    float patrol_interval <- 100.0;                         // Time between patrol route changes
    int fine_amount <- 3;                              		// Reduction in steal chance when caught
    
    // Authority patrol points
    list<point> patrol_points <- [];                       	// List of patrol waypoints
    int num_patrol_points <- 5;                            	// Number of patrol points to generate
    
    string authority_type <- "patrol"
    			among: ["patrol", "stationary"];
    
    // Active pursuit mode
    float thief_detection_radius <- 20.0;          			// Radius to detect potential thieves
    bool authority_actively_pursues <- true;       			// Enable active pursuit of suspicious behavior
	int active_pursuits <- 0								// Number of persueing 
				update: Authority count (each.is_pursuing);
	
	bool enable_cameras <- true;							// Stationary patrol
	int num_cameras <- 2;    								// Number of cameras
    float camera_detection_radius <- 20.0;
	
	int total_catches <- 0;  								// Track total catches across all authorities
    
    
    // EXTENSION 3 		/////////////////////////////////////////////////////////////////////////
    
    // Group Formation
    int current_group_id <- 0 
    			update: empty(Collector where each.is_group_leader) ? 0 : 
                              max(Collector 
                              		where each.is_group_leader 
                              			collect each.group_id
                              ) + 1;
    int min_group_size <- 2;                                // Minimum collectors in a group
    int max_group_size <- 4;                                // Maximum collectors in a group
    
    float group_formation_chance <- 0.3;                    // Chance to try forming a group
    float group_breakup_chance <- 0.1;                      // Chance for a group to dissolve
    float group_cohesion_radius <- 5.0;                     // How close group members stay
    float cooperation_bonus <- 0.2;                         // Bonus to carrying capacity when in group
    
    // Group performance
    float group_stability_index <- 0.0 update: calculate_group_stability();
	float system_resilience <- 0.0 update: calculate_system_resilience();
	float perturbation_level <- 0.0 update: calculate_perturbation_level();
    float current_group_efficiency  <- 0.0 update: calculate_current_group_efficiency();
	
    // Perturbation
    float system_perturbation <- 0.0;              			// Current perturbation level
//    bool apply_perturbation <- false;              			// Toggle for perturbation testing
    bool apply_perturbation <- true;              			// Toggle for perturbation testing
    
    int perturbation_interval <- 500;              			// Cycles between perturbations
    float perturbation_strength <- 0.2;            			// Strength of perturbations
    bool perturbation_active <- false;             			// Tracks if in perturbation state
    
	    
    int perturbation_start_time <- 0;						// When perturbation started
    int perturbation_recovery_time <- 500;    				// Time until recovery
    
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    //////
    int cleanup_interval <- 100;  							// Cleanup every 100 cycles
    bool debug_mode <- true;      							// Enable debug messages
    //////
    
	//////////////
	int win_value <- 30;									// Required number for pile to win
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
        
        // Create more spread out patrol points
        patrol_points <- [];
        int patrol_margin <- 10;
        float beach_section <- (environment_height - 2 * patrol_margin) / num_patrol_points;
        
        loop i from: 0 to: num_patrol_points - 1 {
            float y_pos <- patrol_margin + (i * beach_section) + rnd(-5.0, 5.0);
            point patrol_point <- {
                rnd(beach_start + 5, environment_width - 5),
                min(environment_height - patrol_margin, max(patrol_margin, y_pos))
            };
            patrol_points <- patrol_points + patrol_point;
        }
        
        // Create authority agents if enabled
        if (enable_authority) {
            create Authority number: num_authorities;
            
            // Add security cameras if enabled
	        if (enable_cameras) {
	            create SecurityCamera number: num_cameras {
	                location <- {
	                    rnd(beach_start + 5, environment_width - 5),
	                    rnd(5, environment_height - 5)
	                };
	            }
	        }
        }
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
        
    // Normalize
	float normalize(float value, float min_val, float max_val) {
	    return (value - min_val) / (max_val - min_val);
	}
	
    // System stability
    float calculate_system_stability {
//	    // Skip early cycles to avoid unstable initial values
//	    if (cycle < 50) { return 0.6; }  // Initial baseline stability
	    
	    // Calculate theft impact
	    float theft_impact <- empty(WoodPile) ? 0 : 
	        sum(WoodPile collect each.times_stolen_from) / 
	        max(1, length(WoodPile));  // Normalize by number of piles
	        
	    // Calculate enforcement effectiveness with time scaling
	    float catch_ratio <- total_catches / 
	        max(1, sum(Collector collect each.successful_steals));
	    float enforcement_score <- catch_ratio * (min(1.0, cycle/500));  // Gradual effectiveness
	    
	    // Calculate prevention score with diminishing returns on theft impact
	    float prevention_score <- exp(-theft_impact/10);  // Exponential decay for theft impact
	    
	    // Combine scores with dynamic weights
	    float time_weight <- min(0.8, cycle/1000);  // Weight increases over time

	    // Add group stability factor
	    float group_factor <- empty(Collector where each.in_group) ? 0.0 :
	        mean(Collector where each.in_group collect each.collection_efficiency);
	    
	    // Adjust final calculation
	    float stability_score <- (prevention_score * (1-time_weight) * 0.4) + 
	                           (enforcement_score * time_weight * 0.4) +
	                           (group_factor * 0.2);  // Add 20% weight for group stability
	    
	    return max(0.0, min(1.0, stability_score)) with_precision 2;
	}

	// Calculate perturbation level    
    float calculate_perturbation_level {
	    // If perturbation is not active, return 0
	    if (!perturbation_active) { return 0.0; }
	    
	    float elapsed_time <- float(cycle - perturbation_start_time);
	    float recovery_progress <- min(1.0, elapsed_time / perturbation_recovery_time);
	    
	    // Calculate remaining perturbation strength based on recovery progress
	    float current_level <- perturbation_strength * (1.0 - recovery_progress);
	    
	    return current_level with_precision 2;
	}
    
    // Apply system perturbation
    reflex apply_system_perturbation when: apply_perturbation and every(perturbation_interval) {
	    write "Applying system perturbation...";
	    perturbation_active <- true;
	    perturbation_start_time <- cycle;
	    system_perturbation <- perturbation_strength;
	    
	    // Affect all collectors
	    ask Collector {
	        // Reduce effectiveness temporarily
	        max_carrying_value <- max(1, int(max_carrying_value * (1.0 - perturbation_strength)));
	        speed <- speed * (1.0 - perturbation_strength);
	        steal_chance <- steal_chance * (1.0 - perturbation_strength);
	        
	        do drop_excess_wood;
	        
	        // Drop excess wood if capacity reduced
	        if (current_carried_value > max_carrying_value) {
                list<Driftwood> pieces_to_drop <- [];
                
                // Keep dropping pieces until within capacity
                loop while: (current_carried_value > max_carrying_value) and !empty(carried_wood) {
                    Driftwood piece_to_drop <- last(carried_wood);
                    pieces_to_drop <+ piece_to_drop;
                    carried_wood >- piece_to_drop;
                    current_carried_value <- current_carried_value - piece_to_drop.value;
                }
                
                // Process dropped pieces
                ask pieces_to_drop {
                    is_collected <- false;
                    in_pile <- false;
                    location <- myself.location;
                    self.rotation <- rnd(360.0);  // Reset rotation
                    self.rotation_speed <- rnd(0.2, 0.9);  // Reset rotation speed
                }
                
                // Create warning message
                create WarningMessage {
                    location <- myself.location;
                    text <- "Wood dropped: " + length(pieces_to_drop);
                }
            }
	    }
	    
	    // Show warning message
	    create WarningMessage {
	        location <- {world.shape.width/2, world.shape.height/2};
	        text <- "System Perturbation Applied!";
	        duration <- 100;
	    }
	}

    // Recovery from pertubation
	reflex recover_from_perturbation when: perturbation_active and 
	    (cycle - perturbation_start_time >= perturbation_recovery_time) {
	    
	    write "Recovering from perturbation...";
	    perturbation_active <- false;
	    system_perturbation <- 0.0;  							// Reset perturbation level
	    
	    // Restore collector values
	    ask Collector {
	        max_carrying_value <- max(1, 10); 					// Reset to default
	        speed <- rnd(0.0, 8.0);
	        steal_chance <- initial_steal_chance;
	        
	        // Apply group bonus if in group
	        if (in_group) {
	            max_carrying_value <- max(1, int(max_carrying_value * (1 + cooperation_bonus)));
	        }
	    }
	        
	        // Create recovery message
		    create WarningMessage {
		        location <- {world.shape.width/2, world.shape.height/2};
		        text <- "System Recovered";
		        duration <- 50;
		    }
	    }

    // System resilience calculation 
	float calculate_system_resilience {
	    if (perturbation_active) {
	        // Calculate group vs solo performance directly
	        float group_performance <- empty(Collector where each.in_group) ? 0.0 :
	            mean(Collector where each.in_group collect each.collection_efficiency);
	        float solo_performance <- empty(Collector where !each.in_group) ? 0.0 :
	            mean(Collector where !each.in_group collect each.collection_efficiency);
	            
	        // Normalize performances
	        float norm_group <- normalize(group_performance, 0.0, 1.0);
	        float norm_solo <- normalize(solo_performance, 0.0, 1.0);
	        
	        return max(0.0, min(1.0, (norm_group / max(0.001, norm_solo)))) 
	            with_precision 2;
	    } else {
	        // During normal operation, measure recovery potential
	        return min(1.0, (group_stability_index * 0.7 + system_stability * 0.3)) 
	            with_precision 2;
	    }
	}
    
    // Group stability
    float calculate_group_stability {
	    if (empty(Collector where each.in_group)) { return 0.0; }
	    
	    // Calculate stability based on group persistence and efficiency
	    float avg_group_lifetime <- mean(Collector where each.in_group collect (cycle - each.group_id));
	    float normalized_lifetime <- min(1.0, avg_group_lifetime / 1000);  // Normalize to max 1.0
	    
	    // Calculate group efficiency directly from collectors
	    float group_efficiency <- mean(Collector where each.in_group collect each.collection_efficiency);
	    
	    // Calculate theft resistance
	    float group_theft_resistance <- empty(WoodPile) ? 1.0 : 
	        mean(WoodPile where (each.owner != nil and each.owner.in_group) 
	            collect (1.0 - (each.times_stolen_from / max(1, cycle))));
	            
	    // Weighted combination of factors
	    return (normalized_lifetime * 0.4 + group_efficiency * 0.3 + group_theft_resistance * 0.3) 
	        with_precision 2;
	}
	
	// Group efficiency
	float calculate_current_group_efficiency {
	    list<Collector> grouped_collectors <- Collector where (each.in_group);
	    if (empty(grouped_collectors)) { return 0.0; }
	    
	    float avg_collection_rate <- mean(grouped_collectors collect each.collection_efficiency);
	    float carrying_capacity <- mean(grouped_collectors collect (each.max_carrying_value));
	    
	    // Normalize values
	    float norm_collection <- normalize(avg_collection_rate, 0.0, 1.0);
	    float norm_capacity <- normalize(carrying_capacity, 10.0, 20.0);  // Base capacity is 10, max with bonus is ~20
	    
	    return max(0.0, min(1.0, (norm_collection * 0.7 + norm_capacity * 0.3))) with_precision 2;
	}
    
    
    // Cleanup dead or invalid objects
    reflex cleanup_objects when: every(cleanup_interval) {
        // Clean up invalid wood piles
        list<WoodPile> invalid_piles <- WoodPile where (
            (each.pile_value <= 0) or 
            (each.owner = nil) or 
            dead(each.owner) or 
            (each.location = nil)
        );
        
        ask invalid_piles {
            if (debug_mode) { write "Cleaning up invalid wood pile"; }
            do die;
        }
        
        // Clean up invalid driftwood
        list<Driftwood> invalid_wood <- Driftwood where (
            (each.location = nil) or 
            (each.in_pile and empty(WoodPile at_distance 1.0))
        );
        
        ask invalid_wood {
            if (debug_mode) { write "Cleaning up invalid driftwood"; }
            do die;
        }
        
        // Reset stuck collectors
        list<Collector> stuck_collectors <- Collector where (each.speed <= 0);
        ask stuck_collectors {
            if (debug_mode) { write "Resetting stuck collector"; }
            speed <- rnd(0.0, 8.0);
            
            // Reset stuck stealing states
            if (is_stealing and target_pile = nil) {
                is_stealing <- false;
            }
        }
    }
    
    // Stop the simulation when the value of a wood pile reaches 100
    reflex check_end_condition {
	    if (simulation_ended) { return; }
	    
	    list<WoodPile> winning_piles <- WoodPile where (
	        each != nil and                				   	// Check pile exists
    		!dead(each) and                 				// Make sure pile is not dead
	        each.pile_value >= win_value and         		// Check value threshold
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
    
}
// GLOBAL END
//////////////////////////////////////////


/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
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
	    wave_value <- base_wave_level 
	    					+ wave_amplitude 
	    					* sin(y_factor) 
	    					+ sin(0.05 * float(grid_y) 
	    					+ simulation_time * 0.5
	    				);
//		wave_value <- base_wave_level 
//							+ wave_amplitude 
//							* sin(simulation_time 
//								* 0.5 
//								+ grid_y 
//								* 0.1
//							);
	    
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


/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
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


/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
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

	float start_stealing_time <- time update: is_stealing ? start_stealing_time : time;
    float stealing_timeout <- 100.0;
    
    
    // Group
    int group_id <- -1;         							// Unique group id
    bool in_group <- false;
    list<Collector> group_members <- [];
    Collector group_leader <- nil;
    rgb group_color <- nil;
    
    // Group behavior attributes
    float group_role_chance <- 0.5;                         // Chance to be leader vs follower
    bool is_group_leader <- false;
    point group_gathering_point <- nil;
    
	int wood_collected_count <- 0;              			// Track individual collection count
//    float collection_efficiency <- 0.0          			// Individual efficiency metric
//        update: cycle = 0 ? 0.0 : wood_collected_count / cycle;
    float collection_efficiency <- 0.0 
    			update: cycle = 0 ? 0.0 : 					// Individual efficiency metric
    				(wood_collected_count / max(1, cycle)) 
    				* (in_group ? (1 + cooperation_bonus) : 1.0);
	
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
        if (!empty(carried_wood) and max_carrying_value > 0) {
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
	    if (distance > view_distance) { return false; }
	    
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
	    return angle_diff <= fov/2;
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

        list<Driftwood> nearby_wood <- Driftwood at_distance view_distance  // Use spatial query instead of where
            where (!each.is_collected and !each.in_pile);
        
        if (!empty(nearby_wood)) {
            targeted_wood <- nearby_wood closest_to self;
        }
    }
    
    // Check if the target wood is available
    reflex check_targeted_wood when: targeted_wood != nil {
	    
	    if (targeted_wood.is_collected or (current_carried_value + targeted_wood.value 
	    																	> max_carrying_value
	    )) {
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
        	
            // Check if can collect without exceeding capacity
            if (current_carried_value + targeted_wood.value <= max_carrying_value) {
	            // Collect the wood piece
	            carried_wood <- carried_wood + targeted_wood;
	            current_carried_value <- current_carried_value + targeted_wood.value;
	            targeted_wood.is_collected <- true;
            } else {
                targeted_wood <- nil;  								// Cannot collect, reset target
                return;
            }
            
            
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
	reflex return_to_pile when: (!empty(carried_wood) 
		and (current_carried_value >= max_carrying_value        // At max capacity 
	    or targeted_wood = nil                              	// Decided to return or no more wood available
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
	        // Find existing pile or create new one
	        WoodPile existing_pile <- first(WoodPile where (
	            each.owner = self and 
	            each.location distance_to pile_location < 1.0
	        ));
	        
	        if (existing_pile = nil) {
	            // Create new pile if none exists
	            create WoodPile {
	                location <- myself.pile_location;
	                owner <- myself;
	                // Add first wood piece
	                wood_pieces <- first(myself.carried_wood);
	                ask first(myself.carried_wood) {
	                    location <- myself.location;
	                    in_pile <- true;
	                }
	            }
	            // Remove first wood piece from carried_wood
	            carried_wood <- carried_wood - first(carried_wood);
	        }
	        
	        // Add remaining wood to existing pile
	        if (existing_pile != nil) {
	            ask existing_pile {
	                ask myself.carried_wood {
	                    location <- myself.location;
	                    in_pile <- true;
	                }
	                tracked_wood_pieces <- tracked_wood_pieces + myself.carried_wood;
	                pile_value <- sum(tracked_wood_pieces collect (each.value));
	            }
	        }
	
	        // Update collection metrics
	        wood_collected_count <- wood_collected_count + length(carried_wood);
	        
	        
	        // Reset collector state
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
        
        // Check if pile owner and potential thief are in same group's FOV
	    if (owner.in_group) {
	        loop group_member over: owner.group_members {
	            if (group_member != nil and !dead(group_member)) {
	            	
	                // Check if both pile and thief are within this group member's FOV
	                if (group_member.is_in_fov(pile.location) and 
	                    group_member.is_in_fov(self.location) and 
	                    (group_member.location distance_to pile.location <= group_member.view_distance)) {
	                   
	                    return true;  						// Pile is being watched by a group member
	                }
	            }
	        }
	    }
        
        // Check if both pile and potential thief (self) are within owner's FOV
        return owner.is_in_fov(pile.location) and 
        		owner.is_in_fov(self.location) and 
               	(owner.location distance_to pile.location <= owner.view_distance);
    }
    
    // Find stealable piles
    list<WoodPile> get_stealable_piles {
        return WoodPile where (
            each.owner != self and           				// Not own pile
            !is_pile_observed(each) and      				// Not being observed
            each.pile_value > 0 and          				// Has wood to steal
            is_in_fov(each.location) and       				// Within FOV
            (each.owner = nil or             				// Owner exists and
         		(each.owner.group_id != self.group_id or  	// Not in same group
          		!each.owner.in_group)          				// Or not in any group
        	)
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
        // Timeout mechanism
        if (time - start_stealing_time > stealing_timeout) {
            is_stealing <- false;
            target_pile <- nil;
            return;
        }
        
        // Validate target pile still exists and has value
        if (dead(target_pile) or target_pile = nil or target_pile.pile_value <= 0) {
            is_stealing <- false;
            target_pile <- nil;
            return;
        }
        
        // Cancel if pile becomes observed
        if (target_pile.owner != nil and !dead(target_pile.owner) and 
            target_pile.owner.is_in_fov(target_pile.location)) {
            is_stealing <- false;
            target_pile <- nil;
            return;
        }
        
        do goto target: target_pile.location speed: speed / 3.6;
        
        // Attempt stealing only when close enough
        if (location distance_to target_pile.location < 1.0) {
            list<Driftwood> stealable_wood <- Driftwood at_distance 1.0
                where (each.in_pile and !dead(each) and 
                    current_carried_value + each.value <= max_carrying_value);
                    
            if (!empty(stealable_wood)) {
                Driftwood stolen_wood <- stealable_wood first_with (
                    !dead(each) and current_carried_value + each.value <= max_carrying_value
                );
                
                if (stolen_wood != nil) {
                    stolen_wood.in_pile <- false;
                    carried_wood <- carried_wood + stolen_wood;
                    current_carried_value <- current_carried_value + stolen_wood.value;
                    
                    // Update statistics
                    steal_chance <- min(max_steal_chance, steal_chance + steal_chance_increase);
                    successful_steals <- successful_steals + 1;
                }
            }
            
            // Reset stealing state
            is_stealing <- false;
            target_pile <- nil;
        }
    }
    
    
    // Group Formation behavior
    reflex consider_forming_group 
    			when: !in_group 
    			and flip(group_formation_chance) 
    			and every(50 #cycles) 
    {
        list<Collector> potential_members <- Collector at_distance view_distance 
        														where (!each.in_group);
        
        if (length(potential_members) >= min_group_size - 1) {
            // Initialize group
            list<Collector> new_group <- [self];
            is_group_leader <- true;
            group_color <- rgb(rnd(0,255), rnd(0,255), rnd(0,255));
            group_id <- current_group_id;
            
            // Add random members up to max size
            loop times: min(max_group_size - 1, length(potential_members)) {
                Collector new_member <- one_of(potential_members where (!each.in_group));
                if (new_member != nil) {
                    new_group <- new_group + new_member;
                    potential_members <- potential_members - new_member;
                }
            }
            
            // Calculate group bonus based on number of members
        	int group_size_bonus <- length(new_group);
            
            // Formally create group
            ask new_group {
                in_group <- true;
                group_members <- new_group;
                group_leader <- myself;
                self.group_color <- myself.group_color;
                self.group_id <- myself.group_id;

				// Bonus
                max_carrying_value <- int(max_carrying_value * (1 + cooperation_bonus) + group_size_bonus);
                speed <- speed + 1.0;
            }
            
            write "Group " + group_id + " formed with " + length(new_group) + " members." ;
        }
    }
    
    // Group cohesion behavior
    reflex maintain_group_cohesion when: in_group and !is_group_leader {
        if (group_leader != nil and !dead(group_leader)) {
            if (location distance_to group_leader.location > group_cohesion_radius) {
                do goto target: group_leader.location speed: speed / 3.6;
            }
        } else {
            // Leader is gone, dissolve group
            do leave_group;
        }
    }
    
    // Group leadership behavior
    reflex lead_group when: is_group_leader {
        if (empty(group_members where (each != self))) {
            // No more members, dissolve group
            do leave_group;
        } else {
            // Share information about wood locations
            list<Driftwood> visible_wood <- get_visible_wood(Driftwood where (!each.is_collected));
            if (!empty(visible_wood) and !empty(group_members)) {
                loop member over: group_members where (each != self) {
                    if (member.targeted_wood = nil) {
                        member.targeted_wood <- one_of(visible_wood);
                    }
                }
            }
        }
    }
    
    // Leave group
    action leave_group {
    	int group_size <- length(group_members);
    	
        if (is_group_leader) {
            ask group_members where (each != self) {
                in_group <- false;
                group_members <- [];
                group_leader <- nil;
                group_color <- nil;
                group_id <- -1;
                
                // Calculate new capacity
	            float base_capacity <- max_carrying_value / (1 + cooperation_bonus);
	            max_carrying_value <- max(1, int(base_capacity - min(base_capacity - 1, group_size)));
                speed <- speed - 1.0;
                
                do drop_excess_wood;
            }
        }
        in_group <- false;
        group_members <- [];
        group_leader <- nil;
        is_group_leader <- false;
        group_color <- nil;
        group_id <- -1;
        
        // Calculate new capacity
	    float base_capacity <- max_carrying_value / (1 + cooperation_bonus);
	    max_carrying_value <- max(1, int(base_capacity - min(base_capacity - 1, group_size)));
        speed <- speed - 1.0;
        
        do drop_excess_wood;
    }
    
    // Random group dissolution
    reflex consider_group_breakup when: in_group and flip(group_breakup_chance) and every(100 #cycles) {
        do leave_group;
    }
    
    // Adjust size
    reflex adapt_group_size when: is_group_leader and every(100 #cycles) {
	    float current_efficiency <- collection_efficiency;
	    
	    // If group performing well, try to recruit more members
	    if (current_efficiency > mean(Collector where (!each.in_group) collect each.collection_efficiency)) {
	        int potential_recruits <- length(Collector where (!each.in_group));
	        if (potential_recruits > 0 and length(group_members) < max_group_size) {
	            Collector new_member <- one_of(Collector where (!each.in_group));
	            if (new_member != nil) {
	                ask new_member {
	                    in_group <- true;
	                    group_members <- myself.group_members + self;
	                    group_leader <- myself;
	                    group_color <- myself.group_color;
	                    group_id <- myself.group_id;
	                    max_carrying_value <- int(max_carrying_value * (1 + cooperation_bonus));
	                }
	                group_members <- group_members + new_member;
	            }
	        }
	    }
	    // If group performing poorly, consider reducing size
	    else if (length(group_members) > min_group_size) {
	        Collector member_to_remove <- one_of(group_members where (each != self));
	        if (member_to_remove != nil) {
	            ask member_to_remove {
	                do leave_group;
	            }
	        }
	    }
	}
    
    // Drop excess wood
    action drop_excess_wood {
	    if (current_carried_value > max_carrying_value) {
	        list<Driftwood> pieces_to_drop <- [];
	        
	        // Keep dropping pieces until within capacity
	        loop while: (current_carried_value > max_carrying_value) and !empty(carried_wood) {
	            Driftwood piece_to_drop <- last(carried_wood);
	            pieces_to_drop <+ piece_to_drop;
	            carried_wood >- piece_to_drop;
	            current_carried_value <- current_carried_value - piece_to_drop.value;
	        }
	        
	        // Process dropped pieces
	        ask pieces_to_drop {
	            is_collected <- false;
	            in_pile <- false;
	            location <- myself.location;
	            self.rotation <- rnd(360.0);  					// Reset rotation
	            self.rotation_speed <- rnd(0.2, 0.9);  			// Reset rotation speed
	        }
	        
	        // Create warning message
	        create WarningMessage {
	            location <- myself.location;
	            text <- "Wood dropped: " + length(pieces_to_drop);
	            duration <- 50;
	        }
	    }
	}
	
    aspect default {
        // Base collector visualization
        draw circle(0.5) color: in_group ? group_color : color;
        
        // Carried wood
        if (!empty(carried_wood)) {
            draw triangle(2) color: #brown rotate: heading + 90;
        }
        
        // Group leader crown
        if (is_group_leader) {
            draw triangle(1.5) color: #cyan at: {location.x, location.y - 1.5} rotate: 180;
        }
        
        // Pile owners crown
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
                water_info <- " [D" + string(depth with_precision 2) + "]";
            }
        }
 
        if (in_group) {
	        loop pile over: WoodPile where (each.owner in group_members) {
	            if (is_in_fov(pile.location) and 
	                location distance_to pile.location <= view_distance) {
	                draw line([location, pile.location]) 
	                    color: rgb(0, 255, 0, 50)  // Green line with transparency
	                    width: 1;
	            }
	        }
	    }
        
        string group_info <- "";
        if in_group {
            if is_group_leader {
                group_info <- " [L" + group_id + "]";
            } else {
                group_info <- " [M" + group_id + "]";
            }
        }

        
        // Display info above collector
        draw "[V" + string(speed with_precision 1) + "]" 
		    + " [C" + current_carried_value + "/" + max_carrying_value + "]"
		    + " [S" + int(steal_chance * 100) + "]"
		    + group_info
		    + water_info
		    color: #black size: 8 at: {location.x, location.y - 2};
    }
}

/////////////////////////////////////////////////////////////////
// WoodPile - owned by Collector
species WoodPile {
    Collector owner;
    Driftwood wood_pieces;
    bool has_marker <- true;

    int pile_value <- 0;
	
    float creation_time <- time;              				// When pile was created
    int times_stolen_from <- 0;             				// Count of successful thefts
    float last_theft_time <- -1.0;         				   	// Time of last theft
    float stability_score <- 1.0;
    
    list<Driftwood> tracked_wood_pieces <- [];
    bool is_updating <- false;
    
    // Count all wood pieces at this location
    reflex update_pile_value when: every(5 #cycles) {
	    if (location = nil or dead(self)) { return; }
        if (is_updating) { return; }
        
        is_updating <- true;
            
        // Get current wood pieces
        list<Driftwood> current_wood_pieces <- Driftwood at_distance 1.0
            where (each.in_pile and each.is_collected and !dead(each));
        
        // Check if the wood pieces have actually changed
        bool wood_changed <- false;
        if (length(current_wood_pieces) != length(tracked_wood_pieces)) {
            wood_changed <- true;
        } else {
            // Check if any pieces are different
            loop wood over: current_wood_pieces {
                if !(tracked_wood_pieces contains wood) {
                    wood_changed <- true;
                    break;
                }
            }
        }
        
        // Only update if there's an actual change
        if (wood_changed) {
            tracked_wood_pieces <- current_wood_pieces;
            int new_value <- sum(tracked_wood_pieces collect (each.value));
            
            // Verify the new value is reasonable
            if (new_value >= 0 and new_value <= 100) {  // Assuming 100 is a reasonable maximum
                pile_value <- new_value;
            }
        }
        
        is_updating <- false;

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
    reflex update_theft_tracking when: every(10 #cycles) {
        if (dead(self) or location = nil) { return; }
        
        int current_wood_count <- length(Driftwood at_distance 1.0 
            where (each.in_pile and !dead(each)));
            
        if (current_wood_count < pile_value) {
            if (time - last_theft_time > 20.0) {  // Increased minimum time between theft counts
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


/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
// Authority species
species Authority skills: [moving] {
    point current_patrol_point <- nil;
    list<Collector> observed_thieves <- [];
    
    rgb color <- #darkgreen;
    
    bool is_pursuing <- false;
    Collector pursuit_target <- nil;
    
    init {
        // Start at a random patrol point
        location <- one_of(patrol_points);
        current_patrol_point <- one_of(patrol_points);
    }
    
    
    // FOV calculations
    bool is_in_authority_fov(point target_loc) {
        if (target_loc = nil) { return false; }
        
        float distance <- location distance_to target_loc;
        if (distance > authority_view_distance) { return false; }
        
        // Calculate angle to target
        float dx <- target_loc.x - location.x;
        float dy <- target_loc.y - location.y;
        float angle_to_target <- atan2(dy, dx) * (180/#pi);
        
        // Normalize angles
        float normalized_heading <- float(heading mod 360);
        if (normalized_heading < 0) { normalized_heading <- normalized_heading + 360; }
        
        angle_to_target <- float(angle_to_target mod 360);
        if (angle_to_target < 0) { angle_to_target <- angle_to_target + 360; }
        
        float angle_diff <- abs(normalized_heading - angle_to_target);
        if (angle_diff > 180) { angle_diff <- 360 - angle_diff; }
        
        return angle_diff <= authority_fov/2;
    }
    
    // Check for thieves in view
    reflex observe_collectors {
        observed_thieves <- [];
        list<Collector> nearby_collectors <- Collector at_distance authority_view_distance;
        
        loop collector over: nearby_collectors {
            if (collector != nil and !dead(collector)) {
                if (is_in_authority_fov(collector.location)) {
                    if (collector.is_stealing) {
                        observed_thieves <- observed_thieves + collector;
                        
                        // Instead of punishing here, initiate pursuit
                        pursuit_target <- collector;
                        is_pursuing <- true;
                    }
                }
            }
        }
    }
    
    // Patrol movement
    reflex patrol when: !is_pursuing and current_patrol_point != nil {
        
        switch authority_type {								// Type of Authority
	        match "patrol" {
	            do goto target: current_patrol_point speed: authority_speed;
	            
	            if (location distance_to current_patrol_point < 1.0) {
	            	
	            	// Choose closest point to current suspicious activity
	                if (!empty(WoodPile)) {
	                    list<point> prioritized_points <- patrol_points 
	                    						sort_by (each 
	                    							distance_to (WoodPile 
	                    								closest_to self
	                    							).location
	                    						);
	                    current_patrol_point <- prioritized_points first_with (each != location);
	                
	                } else {
	                	
	                    current_patrol_point <- one_of(patrol_points - current_patrol_point);
	                }
	            }
	        }
	        match "stationary" {
	            // Rotate in place for better coverage
	            heading <- heading + 2.0;
	        }
	    }
    }
    
    // Change patrol route periodically
    reflex change_patrol when: every(patrol_interval) {
        current_patrol_point <- one_of(patrol_points - current_patrol_point);
    }
  
    // Enhanced thief detection
    reflex detect_thieves {
        // Look for collectors who are stealing or near piles that aren't theirs
        list<Collector> suspicious_collectors <- Collector at_distance thief_detection_radius;
        list<WoodPile> nearby_piles <- WoodPile at_distance thief_detection_radius;
        
        loop collector over: suspicious_collectors {
            if (collector.is_stealing) {
                write "-" + self+ " detected stealing behavior!";
                pursuit_target <- collector;
                is_pursuing <- true;
                break;
            }
            // Check if collector is suspiciously close to someone else's pile
            loop pile over: nearby_piles {
                if (pile.owner != collector and 
                    (collector.location distance_to pile.location) < 3.0) {
                    write "Authority detected suspicious behavior near pile " + pile.location+ "!";
                    pursuit_target <- collector;
                    is_pursuing <- true;
                    break;
                }
            }
        }
    }
    
    // Active pursuit behavior
    reflex pursue when: is_pursuing {
        // First verify pursuit target still exists and is valid
        if (pursuit_target = nil or dead(pursuit_target)) {
            is_pursuing <- false;
            pursuit_target <- nil;
            return;
        }
        
        float dist <- location distance_to pursuit_target;
        int authority_fine <- fine_amount; 					// Store locally
        
        if (dist < 2.0) {  // Caught the target
            write "-" + self + " caught thief " + pursuit_target + " at location " + pursuit_target.location;
            
            // Apply punishment
            ask pursuit_target {
                steal_chance <- max(0.0, steal_chance - (authority_fine * 0.01));
                is_stealing <- false;
                target_pile <- nil;
                color <- #red;
                
                // Reduce wood pile value if collector has one
                if (has_pile) {
                    list<WoodPile> collector_piles <- WoodPile where (each.owner = self);
                    ask collector_piles {
                        // Remove some wood pieces
                        int wood_to_remove <- min(authority_fine, pile_value);
                        list<Driftwood> nearby_wood <- Driftwood at_distance 1.0 where (each.in_pile);
                        
                        loop times: wood_to_remove { 
                            if (!empty(nearby_wood)) {
                                ask first(nearby_wood) {
                                    do die;
                                }
                                nearby_wood <- nearby_wood - first(nearby_wood);
                            }
                        }
                        pile_value <- pile_value - wood_to_remove;
                    }
                }
            }
            
            // Update global catch counter
            ask world { total_catches <- total_catches + 1; }
            
            // Create warning message
            create WarningMessage {
                location <- myself.pursuit_target.location;
                text <- "Thief Caught!";
                duration <- 100;
            }
            
            // Reset pursuit
            is_pursuing <- false;
            pursuit_target <- nil;
        } 
        else if (dist > thief_detection_radius * 1.5) {  	// Target too far
            is_pursuing <- false;
            pursuit_target <- nil;
        }
        else {  // Continue pursuit
            do goto target: pursuit_target speed: authority_speed * 1.5;
        }
    }
    
    
    aspect default {

        rgb authority_color <- authority_type = "patrol" ? #darkgreen : #purple;
        draw circle(1.5) color: is_pursuing ? #red : color;
        
        // FOV visualization
        list<point> fov_points <- [location];
        int segments <- 20;
        float start_angle <- heading - authority_fov/2;
        float angle_step <- authority_fov/segments;
        
        loop i from: 0 to: segments {
            float current_angle <- start_angle + angle_step * i;
            point vertex <- {
                location.x + authority_view_distance * cos(current_angle),
                location.y + authority_view_distance * sin(current_angle)
            };
            fov_points <- fov_points + vertex;
        }
        
        draw polygon(fov_points) color: is_pursuing ? rgb(255,0,0,50) : rgb(0,100,0,50);
        
        // Detection radius
        draw circle(thief_detection_radius) color: rgb(0,0,255,10);
        
        // Pursuit line
        if (is_pursuing and pursuit_target != nil) {
            draw line([location, pursuit_target.location]) color: #red;
        }
        
        // Draw heading direction
        point direction_point <- {
            location.x + 3 * cos(heading),
            location.y + 3 * sin(heading)
        };
        draw line([location, direction_point]) color: #black;
    }
    
}

/////////////////////////////////////////////////////////////////
// Stationary patrol - owned by Authority
species SecurityCamera {
    float detection_radius <- camera_detection_radius;
    
    float rotation <- 0.0;  								// Add rotation angle
    float rotation_speed <- 2.5;  							// Degrees per step
    float view_angle <- 120.0;  							// Camera's view angle
    
    
    reflex rotate {
        rotation <- rotation + rotation_speed;
        if (rotation >= 360.0) { rotation <- 0.0; }
    }
    
    reflex detect_thieves when: enable_cameras {
        list<Collector> detected <- Collector at_distance detection_radius;
        ask detected {
            if (self.is_stealing) {
            	write "-" + myself + " caught thief " + self + " at location " + location;
            	
            	// Apply severe punishment
                self.steal_chance <- max(0.0, self.steal_chance - (fine_amount*0.01 - 0.01));
                self.is_stealing <- false;
                self.target_pile <- nil;
                self.color <- #red;
                
                // Reduce wood pile value if collector has one
			    if (self.has_pile) {
                    list<WoodPile> collector_piles <- WoodPile where (each.owner = self);
                    ask collector_piles {
                        // Remove some wood pieces
                        int wood_to_remove <- min(fine_amount, pile_value);
                        list<Driftwood> nearby_wood <- Driftwood at_distance 1.0 where (each.in_pile);
                        
                        loop times: wood_to_remove { 
                            if (!empty(nearby_wood)) {
                                ask first(nearby_wood) {
                                    do die;
                                }
                                nearby_wood <- nearby_wood - first(nearby_wood);
                            }
                        }
                        pile_value <- pile_value - wood_to_remove;
                    }
                }
                
                // Update global catch counter
                ask world { total_catches <- total_catches + 1; }
                
                // Create warning message
                create WarningMessage {
                    location <- myself.location;
                    text <- "Camera caught thief!";
                }
            }
        }
    }
    
    aspect default {
        
        draw circle(1.0) color: #gray;						// Camera body
        draw triangle(2.0) color: #darkgray 				// Camera direction
        					rotate: rotation;
        
        // Camera FOV visualization
        list<point> fov_points <- [location];
        int segments <- 20;
        float start_angle <- rotation - view_angle/2;
        float angle_step <- view_angle/segments;
        
        loop i from: 0 to: segments {
            float current_angle <- start_angle + angle_step * i;
            point vertex <- {
                location.x + detection_radius * cos(current_angle),
                location.y + detection_radius * sin(current_angle)
            };
            fov_points <- fov_points + vertex;
        }
        
        draw polygon(fov_points) color: rgb(100,100,100,30); 
        
        draw circle(detection_radius) 						// Detection radius
        					color: rgb(100,100,100,50);
    }
}
    
    
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
// WarningMessage - helper
species WarningMessage skills: [moving] {
    string text;
    int duration <- 50;
    float fade <- 1.0;
    
    init {
        location <- location + {0, -2};  // Offset above the position
    }
    
    reflex fade_out {
        fade <- fade - (1/duration);
        if (fade <= 0) { do die; }
        location <- location + {0, -0.05};  // Float upward
    }
    
    aspect default {
        draw text color: rgb(255, 0, 0, int(255 * fade)) size: 12 * fade;
    }
}



/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
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
	
	
	// Authority
    parameter "Enable Authority" var: enable_authority;
    parameter "Number of Authorities" var: num_authorities min: 1 max: 5;
    parameter "Authority View Distance" var: authority_view_distance min: 10.0 max: 30.0;
    
    // Authority types
    parameter "Authority Type" var: authority_type among: ["patrol", "stationary"];
    parameter "Enable Security Cameras" var: enable_cameras;
    parameter "Number of Cameras" var: num_cameras min: 1 max: 8;
    parameter "Camera Detection Radius" var: camera_detection_radius min: 10.0 max: 30.0;
    
    // Penalty
    parameter "Fine Amount" var: fine_amount min: 1 max: 10;
    parameter "Authority Detection Radius" var: thief_detection_radius min: 20.0 max: 60.0;
    parameter "Authority Active Pursuit" var: authority_actively_pursues;
    
    // Group Formation
    parameter "Min Group Size" var: min_group_size min: 2 max: 5;
    parameter "Max Group Size" var: max_group_size min: 3 max: 8;
    parameter "Group Formation Chance" var: group_formation_chance min: 0.1 max: 0.5;
    parameter "Group Breakup Chance" var: group_breakup_chance min: 0.05 max: 0.2;
    parameter "Cooperation Bonus" var: cooperation_bonus min: 0.1 max: 0.5;
    
    // Perturbation
    parameter "Apply Perturbations" var: apply_perturbation;
	parameter "Perturbation Strength" var: perturbation_strength min: 0.1 max: 0.5;
	parameter "Perturbation Interval" var: perturbation_interval min: 100 max: 1000;
    
    output {
        display main_display {
            grid Beach_Cell;
            
            species Driftwood;
            
            species Collector;
            species WoodPile;
            
            species Authority;
            species SecurityCamera;
            species WarningMessage;
            
            
            // Time and tide information
	        graphics "Info Display" {
	            // Calculate hours and minutes
			    int display_hours <- int(day_time);
			    int display_minutes <- int((day_time - display_hours) * 60);
			    
			    // Add leading zeros
			    string hours <- display_hours < 10 ? "0" + string(display_hours) : string(display_hours);
			    string minutes <- display_minutes < 10 ? "0" + string(display_minutes) : string(display_minutes);
			    
			    // Time
			    draw "Time: " + hours + ":" + minutes at: {2, 5} color: #orange font: font("Default", 10, #bold);
			    
			    // Notes
			    draw "Speed: V km/h (1) " at: {2, 15} color: #orange font: font("Default", 10, #bold);
			    draw "Capacity: C / max (2)" at: {2, 20} color: #orange font: font("Default", 10, #bold);
			    draw "Steal: S % (3)" at: {2, 25} color: #orange font: font("Default", 10, #bold);
			    draw "Group: L - M (4)" at: {2, 30} color: #orange font: font("Default", 10, #bold);
			    draw "Depth: D meter (5)" at: {2, 35} color: #orange font: font("Default", 10, #bold);

			    // Tide
			    draw "Tide Level: " + (round(tide_level * 100) / 100) at: {2, 80} color: #orange font: font("Default", 10, #bold);
	            
	            string tide_status <- "";
	            string tide_direction <- "";
	            float mid_tide <- (min_tide + max_tide) / 2;
	            
	            // Determine tide direction
			    if ((day_time >= 0.0 and day_time < 6.0) or (day_time >= 12.0 and day_time < 18.0)) {
			        tide_direction <- "Rising";
			    } else {
			        tide_direction <- "Falling";
			    }
			    
			    draw "Tide Trend: " + tide_status + " " + tide_direction at: {2, 85} color: #orange font: font("Default", 10, #bold);
	            
	            // Determine tide height status
			    if (tide_level > mid_tide + (max_tide - mid_tide) * 0.3) {
			        tide_status <- "High Tide";
			    } else if (tide_level < mid_tide - (mid_tide - min_tide) * 0.3) {
			        tide_status <- "Low Tide";
			    } else {
			        tide_status <- "Mid Tide";
			    }
			    
			    draw "Tide Status: " + tide_status at: {2, 90} color: #orange font: font("Default", 10, #bold);
			    
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
				                    at: {2, 95} color: #orange font: font("Default", 10, #bold);
				            }
				        }
				    }
	        }
	        
        }
        
	    // Monitors to track values
		// Cycle
		monitor "Current Cycle" value: cycle;
		
		// Time
		monitor "Current Time" value: (int(day_time) < 10 ? "0" : "") 
										+ string(int(day_time)) + ":" 
										+ (int((day_time - int(day_time)) * 60) < 10 ? "0" : "") 
										+ string(int((day_time - int(day_time)) * 60));
	    monitor "Day/Night" value: (day_time >= night_start or day_time < night_end) ? "Night" : "Day";
     	
     	// Terrain
     	monitor "Average Height" value: mean(Beach_Cell collect each.height);
	    monitor "Tide Level" value: round(tide_level * 100) / 100;
	   
	   // Wood pile
	    monitor "Highest Pile Value" value: empty(WoodPile) ? 0 : max(WoodPile collect each.pile_value);
	    monitor "Average Pile Stability" value: empty(WoodPile) ? 0 : (mean(WoodPile collect (
	    												min(1.0, 
	    												max(0.0, each.stability_score)))) 
	    												with_precision 2);

		// Collector        
        monitor "Active Collectors" value: length(Collector);
		monitor "Active Wood Pieces" value: length(Driftwood);
		monitor "Active Piles" value: length(WoodPile);
        
        // Theft
        monitor "Total Thefts" value: sum(WoodPile collect each.times_stolen_from);
        
        // Authority
        monitor "Active Authorities" value: length(Authority);
		monitor "Active Pursuits" value: active_pursuits;
		monitor "Total Catches" value: total_catches;
		
		// System Stability
		monitor "System Stability" value: system_stability;
		
		// Group Statistics
        monitor "Number of Groups" value: length(Collector where each.is_group_leader);
        monitor "Grouped Collectors" value: length(Collector where each.in_group);
        monitor "Average Group Size" value: empty(Collector where each.is_group_leader) ? 0 : 
                                          		mean(Collector where each.is_group_leader 
                                          							collect length(each.group_members)
                                          );
        
        // Perturbation
		monitor "Perturbation Strength" value: perturbation_strength with_precision 2 ;
		                                                  
        
        // Security and Enforcement Analysis (consistent with Extension 2)
		display "Security Analysis" {
		    chart "Security Overview" type: series position: {0, 0} size: {1.0, 0.5} {
		        data "Group Defense Rate" 
		            value: empty(WoodPile where (each.owner != nil and each.owner.in_group)) ? 0 :
		                mean(WoodPile where (each.owner != nil and each.owner.in_group) 
		                    collect (1.0 - (each.times_stolen_from / max(1, cycle)))) * 100 
		            style: line color: #green;
		        data "Enforcement Rate" 
		            value: total_catches / max(1, total_catches + sum(Collector collect each.successful_steals)) * 100 
		            style: line color: #blue;
		        data "System Stability" value: system_stability * 100 style: line color: #purple;
		        data "Theft Rate" 
		            value: empty(Collector) ? 0 : mean(Collector collect each.steal_chance) * 100 
		            style: line color: #red;
		    }
		    
		    chart "Resource Security" type: pie position: {0, 0.5} size: {1.0, 0.5} {
		        data "Secured Resources" 
		            value: sum(WoodPile where (each.times_stolen_from = 0) collect each.pile_value) 
		            color: #green;
		        data "At-Risk Resources" 
		            value: sum(WoodPile where (each.times_stolen_from > 0) collect each.pile_value) 
		            color: #orange;
		        data "Uncollected Resources" 
		            value: sum(Driftwood where (!each.is_collected) collect each.value) 
		            color: #gray;
		    }
		}
		
		// Resource and Group Management (combining elements from Extensions 1 & 2)
		display "Resource Management" {
		    chart "Resource Distribution" type: series position: {0, 0} size: {1.0, 0.5} {
		        data "Group Resources" 
		            value: sum((Collector where each.in_group) collect each.current_carried_value) 
		            style: line color: #blue;
		        data "Individual Resources" 
		            value: sum((Collector where !each.in_group) collect each.current_carried_value) 
		            style: line color: #red;
		        data "Average Pile Value" 
		            value: empty(WoodPile) ? 0 : mean(WoodPile collect each.pile_value) 
		            style: line color: #green;
		    }
		    
		    chart "Group Statistics" type: pie position: {0, 0.5} size: {1.0, 0.5} {
		        data "Grouped Collectors" 
		            value: length(Collector where each.in_group) 
		            color: #blue;
		        data "Solo Collectors" 
		            value: length(Collector where !each.in_group) 
		            color: #red;
		        data "Active Groups" 
		            value: length(Collector where each.is_group_leader) 
		            color: #green;
		    }
		}
		
		// System Performance and Perturbation (unique to Extension 3)
		display "System Performance" {
		    chart "Performance Metrics" type: series position: {0, 0} size: {1.0, 0.5} {
		        data "Group Efficiency" value: current_group_efficiency * 100 style: line color: #blue;
		        data "System Resilience" value: system_resilience * 100 style: line color: #green;
		        data "Perturbation Level" value: perturbation_level * 100 style: line color: #red;
		        data "Recovery Rate" value: (1 - perturbation_level) * 100 style: line color: #purple;
		    }
		    
		    chart "Stability" type: series position: {0, 0.5} size: {1.0, 0.5} {
//		        data "Average Group Size" 
//			        value: empty(Collector where each.is_group_leader) ? 0 : 
//			            mean(Collector where each.is_group_leader collect length(each.group_members)) 
//			        style: line color: #blue;
//			    data "Group Protection Rate" 
//			        value: empty(WoodPile where (each.owner != nil and each.owner.in_group)) ? 0 :
//			            (1 - mean(WoodPile where (each.owner != nil and each.owner.in_group) 
//			                collect (each.times_stolen_from / max(1, cycle)))) * 100 
//			        style: line color: #red;
		        data "System Stability" value: system_stability * 100 style: line color: #green;
		    }
		}
    }

}




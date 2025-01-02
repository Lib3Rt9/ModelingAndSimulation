model Driftwood

global {
    // Define the dimensions of the environment
    int environment_width <- 100;
    int environment_height <- 50;
    
    // Fixed boundaries - adjusted for more realistic proportions
    int sea_width <- int(environment_width * 0.25);    // 40% for deeper water
    int beach_start <- int(environment_width * 0.65);  // 30% for tidal zone
    
    // Height parameters
    float max_beach_height <- 5.0; // Maximum height at beach
    float base_sea_level <- 0.0;   // Base sea level (0 meters)
    

    // Wave parameters
    float wave_amplitude <- 2.0;  	// Height of the wave
    float wave_frequency <- 0.5;  	// Frequency of the wave
    float wave_speed <- 0.5;      	// Speed of wave movement
    float simulation_time <- 0.0;  	// Time counter for wave movement
    float base_wave_level <- 1.0;  	// Parameter to keep waves above baseline
    
    // Tide parameters
    float tide_level <- 0.5;		// Start at middle level
    float tide_speed <- 0.01;		// Slower tide changes
    float max_tide <- 1.0;			// Max tide
    float min_tide <- 0.2;        	// New parameter for minimum tide level
    bool tide_rising <- true;
    
    // Wet sand parameters
    float wet_sand_duration <- 200.0;  // How long the sand stays wet
    
    reflex update_time {
        simulation_time <- simulation_time + wave_speed;
    }
    
    // Tide cycle mechanics
    reflex update_tide {
        if (tide_rising) {
            tide_level <- tide_level + tide_speed;
            if (tide_level >= max_tide) {
                tide_rising <- false;
            }
        } else {
            tide_level <- tide_level - tide_speed;
            if (tide_level <= min_tide) {
                tide_rising <- true;
            }
        }
    }
}

// Define beach cells
grid Beach_Cell width: environment_width height: environment_height {
    rgb color <- rgb(255, 222, 173);
    float wave_value <- 0.0;
    float wetness <- 0.0;
    bool was_underwater <- false;
    rgb base_sand_color <- rgb(255, 222, 173);
    rgb sea_color <- rgb(0, 105, 148);
    rgb shallow_water_color <- rgb(150, 200, 255);
    
    init {
        // Calculate waves only once for initial setup
        float y_sin <- sin(wave_frequency * float(grid_y));
        float sec_y_sin <- sin(0.05 * float(grid_y));
        wave_value <- base_wave_level + (wave_amplitude * y_sin) + sec_y_sin;
        
        float adjusted_sea_width <- sea_width + wave_value;
        
        // Simpler initial setup - only distinguish between sea and land
        if (grid_x < adjusted_sea_width) {
            color <- sea_color;
            was_underwater <- true;
        }
    }
    
    reflex update_cell {
        // Optimize wave calculations
        float y_factor <- wave_frequency * float(grid_y) + simulation_time;
        wave_value <- base_wave_level + wave_amplitude * sin(y_factor) + sin(0.05 * float(grid_y) + simulation_time * 0.5);
        
        float adjusted_sea_width <- sea_width + wave_value;
        float adjusted_beach_start <- beach_start + wave_value;
        bool is_underwater <- false;
        
        // Simplified zone checking
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
                    // Simplified wetness color calculation
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

experiment Driftwood_Simulation type: gui {
    parameter "Wave Amplitude" var: wave_amplitude min: 0.5 max: 5.0;
    parameter "Wave Base Level" var: base_wave_level min: 0.5 max: 3.0;
    parameter "Wave Frequency" var: wave_frequency min: 0.05 max: 1.0;
    parameter "Wave Speed" var: wave_speed min: 0.01 max: 1.0;
    parameter "Wet Sand Duration" var: wet_sand_duration min: 10.0 max: 500.0;
    parameter "Minimum Tide Level" var: min_tide min: 0.0 max: 1.0;
    parameter "Maximum Tide Level" var: max_tide min: 1.0 max: 1.5;
    
    output {
        display main_display {
            grid Beach_Cell;
        }
    }
}

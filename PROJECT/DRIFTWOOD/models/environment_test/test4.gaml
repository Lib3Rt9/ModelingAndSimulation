model Driftwood

global {
    // Define the dimensions of the environment
    int environment_width <- 100;
    int environment_height <- 50;
    
    // Fixed boundaries - adjusted for more realistic proportions
    int sea_width <- int(environment_width * 0.4);    // 40% for deeper water
    int beach_start <- int(environment_width * 0.7);  // 30% for tidal zone
    
    // Wave parameters
    float wave_amplitude <- 5.0;  // Height of the wave
    float wave_frequency <- 0.1;  // Frequency of the wave
    float wave_speed <- 0.1;      // Speed of wave movement
    float simulation_time <- 0.0;  // Time counter for wave movement
    
    // Tide parameters
    float tide_level <- 0.0;
    float tide_speed <- 0.01;
    float max_tide <- 1.0;
    bool tide_rising <- true;
    
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
            if (tide_level <= 0) {
                tide_rising <- true;
            }
        }
    }
}

// Define beach cells
grid Beach_Cell width: environment_width height: environment_height {
    rgb color <- rgb(255, 222, 173); // Default sandy color
    float wave_value <- 0.0;
    
    reflex update_cell {
        // Calculate primary wave
        wave_value <- wave_amplitude * sin(wave_frequency * float(grid_y) + simulation_time);
        
        // Calculate secondary wave
        float secondary_wave <- 2.0 * sin(0.05 * float(grid_y) + simulation_time * 0.5);
        wave_value <- wave_value + secondary_wave;
        
        float adjusted_sea_width <- sea_width + wave_value;
        float adjusted_beach_start <- beach_start + wave_value;
        
        if (grid_x < adjusted_sea_width) {
            // Permanent sea zone
            color <- rgb(0, 105, 148);  // Deep blue for sea
        } else if (grid_x >= adjusted_beach_start) {
            // Permanent beach zone
            color <- rgb(255, 222, 173);  // Sandy color
        } else {
            // Tidal zone - changes with tide
            float tide_zone <- adjusted_sea_width + (tide_level * (adjusted_beach_start - adjusted_sea_width));
            if (grid_x < tide_zone) {
                color <- rgb(150, 200, 255);  // Light blue for shallow water
            } else {
                color <- rgb(255, 222, 173);  // Sandy color
            }
        }
    }
}

experiment Driftwood_Simulation type: gui {
    parameter "Wave Amplitude" var: wave_amplitude min: 1.0 max: 10.0;
    parameter "Wave Frequency" var: wave_frequency min: 0.05 max: 0.5;
    parameter "Wave Speed" var: wave_speed min: 0.01 max: 0.5;
    
    output {
        display main_display {
            grid Beach_Cell;
        }
    }
}
model BeachWithTides

global {
    int environment_width <- 100;
    int environment_height <- 100;
    float tide_level <- 0.0 min: 0.0 max: 1.0;
    float tide_speed <- 0.005;  // Slower tide for more realistic movement
    bool tide_rising <- true;
    float line_update_probability <- 0.05;  // Reduced for smoother animation
    
    // Enhanced beach parameters
    float beach_start <- 0.65;  // Beach starts at 65% of width
    float low_tide_position <- 0.25;  // Low tide at 25% of width
    float high_tide_position <- 0.6;  // High tide at 60% of width
    
    // Simplified curve parameters
    int curve_segments <- 10;  // Reduced number of segments
    float base_amplitude <- 3.0;  // Reduced amplitude
    float wave_frequency <- 0.15;  // Slightly increased frequency for fewer but visible curves
    
    geometry shape <- rectangle(environment_width, environment_height);
    
    init {
        create low_tide_line number: 1 {
            shape <- self.generate_natural_tide_curve(low_tide_position);
        }
        
        create high_tide_line number: 1 {
            shape <- self.generate_natural_tide_curve(high_tide_position);
        }
        
        create beach_border number: 1 {
            shape <- self.generate_natural_beach_line(beach_start);
        }
    }
    
    reflex update_tide {
        if tide_rising {
            tide_level <- tide_level + tide_speed;
            if tide_level >= 1.0 { 
                tide_rising <- false;
                tide_level <- 1.0;  // Ensure we don't exceed 1.0
            }
        } else {
            tide_level <- tide_level - tide_speed;
            if tide_level <= 0.0 { 
                tide_rising <- true;
                tide_level <- 0.0;  // Ensure we don't go below 0.0
            }
        }
        
        // Gradual line morphing
        if flip(line_update_probability) {
            ask low_tide_line + high_tide_line {
                do natural_morph();
            }
        }
    }
}

species beach_border {
    action generate_natural_beach_line(float x_position) type: geometry {
        list<point> points;
        float base_x <- world.environment_width * x_position;
        float amplitude <- world.base_amplitude * 0.75;  // Slightly less variation for beach
        
        loop i from: 0 to: world.curve_segments {
            float y <- (i / world.curve_segments) * world.environment_height;
            // Add natural variation using sine wave
            float x <- base_x + (amplitude * sin(y * world.wave_frequency * 2 * #pi)) + (rnd(-1.0, 1.0));
            points <- points + point(x, y);
        }
        
        return polyline(points);
    }
    
    aspect default {
        draw shape color: #sandybrown width: 2.0;
    }
}

species base_tide_line {
    list<point> control_points;
    float base_x;
    
    action generate_natural_tide_curve(float x_position) type: geometry {
        control_points <- [];
        base_x <- world.environment_width * x_position;
        float amplitude <- world.base_amplitude;
        
        loop i from: 0 to: world.curve_segments {
            float y <- (i / world.curve_segments) * world.environment_height;
            // Create natural wave-like pattern
            float wave_offset <- amplitude * sin(y * world.wave_frequency * 2 * #pi);
            float random_offset <- rnd(-amplitude * 0.3, amplitude * 0.3);
            float x <- base_x + wave_offset + random_offset;
            control_points <- control_points + point(x, y);
        }
        
        return polyline(control_points);
    }
    
    action natural_morph {
        // Regenerate the curve while maintaining its curved nature
        float morph_amplitude <- world.base_amplitude;
        list<point> new_points;
        
        loop i from: 0 to: world.curve_segments {
            float y <- (i / world.curve_segments) * world.environment_height;
            // Base wave pattern
            float wave_offset <- morph_amplitude * sin(y * world.wave_frequency * 2 * #pi + (cycle * 0.05));
            // Secondary wave for more complexity
            float secondary_wave <- (morph_amplitude * 0.5) * sin(y * world.wave_frequency * 4 * #pi + (cycle * 0.03));
            // Small random variation
            float random_offset <- rnd(-0.5, 0.5);
            
            float x <- base_x + wave_offset + secondary_wave + random_offset;
            new_points <- new_points + point(x, y);
        }
        
        // Simplified smoothing with fewer intermediate points
        list<point> smoothed_points <- [];
        loop i from: 0 to: length(new_points) - 2 {
            point p1 <- new_points[i];
            point p2 <- new_points[i + 1];
            smoothed_points <- smoothed_points + p1;
            // Add only one midpoint between points
            if (i < length(new_points) - 2) {
                point mid <- point((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
                smoothed_points <- smoothed_points + mid;
            }
        }
        smoothed_points <- smoothed_points + last(new_points);
        control_points <- smoothed_points;
        shape <- polyline(smoothed_points);
    }
}

species low_tide_line parent: base_tide_line {
    aspect default {
        draw shape color: rgb(65, 105, 225) width: 2.0;
    }
}

species high_tide_line parent: base_tide_line {
    aspect default {
        // Enhanced dashed line visualization
        loop i from: 0 to: length(shape.points) - 2 {
            point p1 <- shape.points[i];
            point p2 <- shape.points[i + 1];
            float segment_length <- p1 distance_to p2;
            int num_dashes <- int(segment_length / 1.5);  // More frequent dashes
            
            loop j from: 0 to: num_dashes - 1 {
                float t1 <- j / num_dashes;
                float t2 <- min(1.0, (j + 0.5) / num_dashes);
                point dash_start <- point(
                    p1.x + t1 * (p2.x - p1.x),
                    p1.y + t1 * (p2.y - p1.y)
                );
                point dash_end <- point(
                    p1.x + t2 * (p2.x - p1.x),
                    p1.y + t2 * (p2.y - p1.y)
                );
                draw line([dash_start, dash_end]) color: rgb(65, 105, 225) width: 1.5;
            }
        }
    }
}

grid environment_cell width: 100 height: 100 {
    float transparency <- 1.0;
    rgb color <- compute_cell_color();
    
    rgb compute_cell_color {
        point cell_center <- location;
        float x_pos <- cell_center.x / world.environment_width;
        
        // Get reference points for tide lines
        point current_pos <- cell_center;
        point beach_pos <- nil;
        point low_pos <- nil;
        point high_pos <- nil;
        
        // Safely get nearest points if agents exist
        if (!empty(beach_border)) {
            list<point> beach_points <- (first(beach_border).shape closest_points_with current_pos);
            if (!empty(beach_points)) { beach_pos <- first(beach_points); }
        }
        
        if (!empty(low_tide_line)) {
            list<point> low_points <- (first(low_tide_line).shape closest_points_with current_pos);
            if (!empty(low_points)) { low_pos <- first(low_points); }
        }
        
        if (!empty(high_tide_line)) {
            list<point> high_points <- (first(high_tide_line).shape closest_points_with current_pos);
            if (!empty(high_points)) { high_pos <- first(high_points); }
        }
        
        // Initial setup - use basic positions if agents aren't ready
        if (beach_pos = nil or low_pos = nil or high_pos = nil) {
        
            if (x_pos >= beach_start) {
                transparency <- 1.0;
                return rgb(238, 214, 175); // Sand color
            }
            if (x_pos <= low_tide_position) {
                transparency <- 0.7;
                return rgb(65, 105, 225); // Deep blue
            }
            float tide_influence <- world.tide_level;
            transparency <- 0.6;  // More opaque water
            return blend(rgb(30, 80, 225), rgb(238, 214, 175), 1 - tide_influence);
        }
        
        // Use actual curved lines once agents are initialized
        if (cell_center.x > beach_pos.x) {
            transparency <- 1.0;
            return rgb(238, 214, 175); // Sand color
        }
        
        if (cell_center.x < low_pos.x - 2) {
            transparency <- 0.7;
            return rgb(65, 105, 225); // Deep blue
        }
        
        float tide_range <- high_pos.x - low_pos.x;
        float relative_pos <- (cell_center.x - low_pos.x) / tide_range;
        float tide_influence <- 1 - (relative_pos - world.tide_level);
        tide_influence <- max(0.0, min(1.0, tide_influence));
        
        transparency <- 0.7 + (0.3 * (1 - tide_influence));
        
        // Enhanced water color blending
        rgb water_color <- rgb(30, 80, 225);  // Darker blue
        if (relative_pos < 0.3) {  // Deeper water area
            water_color <- rgb(20, 60, 200);  // Even darker blue
        }
        
        float blend_factor <- 1 - tide_influence;
        // Make water more visible in tidal zone
        if (blend_factor > 0.3) {
            blend_factor <- 0.3 + (0.7 * (blend_factor - 0.3) / 0.7);
        }
        
        return blend(
            water_color,
            rgb(238, 214, 175), // Sand color
            blend_factor
        );
    }
    
    reflex update_color {
        color <- compute_cell_color();
    }
}

experiment beach_simulation type: gui {
    parameter "Wave Frequency" var: wave_frequency min: 0.05 max: 0.2 step: 0.01;
    parameter "Tide Speed" var: tide_speed min: 0.001 max: 0.01 step: 0.001;
    
    output {
        display main_display {
            grid environment_cell transparency: 0.7;
            species beach_border;
            species low_tide_line;
            species high_tide_line;
        }
    }
}
model DriftwoodCollection

global {
    int environment_width <- 100;
    int environment_height <- 100;
    float tide_level <- 0.0 min: 0.0 max: 1.0;
    float tide_speed <- 0.01;
    bool tide_rising <- true;
    
    geometry shape <- rectangle(environment_width, environment_height);
    
    init {
        create beach_border number: 1 {
            shape <- self.generate_random_curve();
        }
        
        create tide_line number: 1 {
            shape <- self.generate_high_tide_curve();
        }
    }
    
    reflex update_tide {
        if tide_rising {
            tide_level <- tide_level + tide_speed;
            if tide_level >= 1.0 { tide_rising <- false; }
        } else {
            tide_level <- tide_level - tide_speed;
            if tide_level <= 0.0 { tide_rising <- true; }
        }
    }
}

species beach_border {
    action generate_random_curve type: geometry {
        list<point> curve_points;
        int segments <- 10;
        float amplitude <- 5.0;
        
        // Create vertical curve at x = 25% of width
        float base_x <- world.environment_width * 0.25;
        
        loop i from: 0 to: segments {
            float y <- (i / segments) * world.environment_height;
            // Random fluctuation in x-coordinate
            float x <- base_x + (rnd(-amplitude, amplitude));
            curve_points <- curve_points + point(x, y);
        }
        
        return polyline(curve_points);
    }
    
    aspect default {
        draw shape color: #blue width: 2.0;
    }
}

species tide_line {
    action generate_high_tide_curve type: geometry {
        list<point> curve_points;
        int segments <- 10;
        float amplitude <- 3.0;
        
        // Create vertical curve at x = 75% of width
        float base_x <- world.environment_width * 0.75;
        
        loop i from: 0 to: segments {
            float y <- (i / segments) * world.environment_height;
            // Random fluctuation in x-coordinate
            float x <- base_x + (rnd(-amplitude, amplitude));
            curve_points <- curve_points + point(x, y);
        }
        
        return polyline(curve_points);
    }
    
    aspect default {
        loop i from: 0 to: length(shape.points) - 2 {
            point p1 <- shape.points[i];
            point p2 <- shape.points[i + 1];
            float segment_length <- p1 distance_to p2;
            int num_dashes <- int(segment_length / 2);
            
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
                draw line([dash_start, dash_end]) color: #blue width: 1.0;
            }
        }
    }
}

grid environment_cell width: 100 height: 100 {
    float transparency <- 1.0;
    rgb color <- compute_cell_color();
    
    rgb compute_cell_color {
        point cell_center <- location;
        
        // Permanent sea (left of low tide line)
        if cell_center.x < world.environment_width * 0.25 {
            transparency <- 0.7;
            return rgb(65, 105, 225); // Deep blue
        }
        
        // Permanent beach (right of high tide line)
        if cell_center.x > world.environment_width * 0.75 {
            transparency <- 1.0;
            return rgb(238, 214, 175); // Sand color
        }
        
        // Tidal zone
        float tide_influence <- world.tide_level * 
            (1 - ((cell_center.x - world.environment_width * 0.25) / 
            (world.environment_width * 0.5)));
            
        transparency <- 0.7 + (0.3 * (1 - tide_influence));
        return blend(#blue, #sandybrown, tide_influence);
    }
    
    reflex update_color {
        color <- compute_cell_color();
    }
}

experiment driftwood_simulation type: gui {
    output {
        display main_display {
            grid environment_cell transparency: 0.7;
            species beach_border;
            species tide_line;
        }
    }
}
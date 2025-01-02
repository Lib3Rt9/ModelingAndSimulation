model DriftwoodBeach

global {
    int environment_width <- 100;
    int environment_height <- 100;
    float tide_level <- 0.0 min: 0.0 max: 1.0;
    float tide_speed <- 0.01;
    bool tide_rising <- true;
    float line_update_probability <- 0.1;
    
    // Define fixed boundaries for beach and water
    float beach_start <- 0.6; // Beach starts at 60% of width
    float low_tide_position <- 0.3; // Low tide at 30% of width
    float high_tide_position <- 0.55; // High tide at 55% of width
    
    geometry shape <- rectangle(environment_width, environment_height);
    
    init {
        create low_tide_line number: 1 {
            shape <- self.generate_tide_curve(low_tide_position);
        }
        
        create high_tide_line number: 1 {
            shape <- self.generate_tide_curve(high_tide_position);
        }
        
        // Create permanent beach border
        create beach_border number: 1 {
            shape <- self.generate_beach_line(beach_start);
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
        
        // Randomly update tide lines within their bounds
        if flip(line_update_probability) {
            ask low_tide_line {
                do morph_line();
            }
            ask high_tide_line {
                do morph_line();
            }
        }
    }
}

species beach_border {
    action generate_beach_line(float x_position) type: geometry {
        list<point> points;
        float base_x <- world.environment_width * x_position;
        float amplitude <- 2.0;
        int segments <- 10;
        
        loop i from: 0 to: segments {
            float y <- (i / segments) * world.environment_height;
            float x <- base_x + (rnd(-amplitude, amplitude));
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
    
    action generate_tide_curve(float x_position) type: geometry {
        control_points <- [];
        base_x <- world.environment_width * x_position;
        float amplitude <- 3.0;
        int segments <- 10;
        
        loop i from: 0 to: segments {
            float y <- (i / segments) * world.environment_height;
            float x <- base_x + (rnd(-amplitude, amplitude));
            control_points <- control_points + point(x, y);
        }
        
        return polyline(control_points);
    }
    
    action morph_line {
        float morph_amplitude <- 1.5;
        loop i from: 0 to: length(control_points) - 1 {
            point p <- control_points[i];
            // Modify x coordinate within bounds
            float new_x <- p.x + rnd(-morph_amplitude, morph_amplitude);
            // Keep within reasonable bounds of base position
            new_x <- min(base_x + 5, max(base_x - 5, new_x));
            control_points[i] <- point(new_x, p.y);
        }
        shape <- polyline(control_points);
    }
}

species low_tide_line parent: base_tide_line {
    aspect default {
        draw shape color: rgb(65, 105, 225) width: 2.0;
    }
}

species high_tide_line parent: base_tide_line {
    aspect default {
        // Dashed line for high tide mark
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
                draw line([dash_start, dash_end]) color: rgb(65, 105, 225) width: 1.0;
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
        
        // Permanent beach area (never touched by water)
        if x_pos >= beach_start {
            transparency <- 1.0;
            return rgb(238, 214, 175); // Sand color
        }
        
        // Permanent water area
        if x_pos <= low_tide_position - 0.05 {
            transparency <- 0.7;
            return rgb(65, 105, 225); // Deep blue
        }
        
        // Tidal zone
        if x_pos <= high_tide_position {
            float tide_influence <- world.tide_level * 
                (1 - ((x_pos - low_tide_position) / 
                (high_tide_position - low_tide_position)));
            
            transparency <- 0.7 + (0.3 * (1 - tide_influence));
            
            // Mix between water and sand color based on tide
            return blend(rgb(65, 105, 225), rgb(238, 214, 175), 1 - tide_influence);
        }
        
        // Default to beach
        transparency <- 1.0;
        return rgb(238, 214, 175);
    }
    
    reflex update_color {
        color <- compute_cell_color();
    }
}

experiment beach_simulation type: gui {
    output {
        display main_display {
            grid environment_cell transparency: 0.7;
            species beach_border;
            species low_tide_line;
            species high_tide_line;
        }
    }
}
model driftwood

global {
    int grid_size <- 50;
    float step <- 1 #minutes;
    int nb_collectors <- 20;
    float wood_spawn_rate <- 0.01;
    float observation_range <- 5.0;
    
    init {
        create collector number: nb_collectors {
            location <- any_location_in(world.shape);
        }
        create wood_pile number: 10 {
            location <- any_location_in(world.shape);
            has_owner <- false;
            wood_amount <- rnd(1, 5);
        }
    }
    
    reflex spawn_wood when: flip(wood_spawn_rate) {
        create wood_pile {
            location <- any_location_in(world.shape);
            has_owner <- false;
            wood_amount <- rnd(1, 5);
        }
    }
}

grid environment_grid width: grid_size height: grid_size {
    rgb color <- #white;
}

species collector skills: [moving] {
    float base_speed <- 0.5;  // Reduced base speed for smoother movement
    point target_point <- nil;
    bool has_pile <- false;
    wood_pile my_pile <- nil;
    int carrying_capacity <- rnd(3, 7);
    float wander_angle <- 0.0;
    
    reflex wander when: my_pile = nil {
        // Update wander angle gradually
        wander_angle <- wander_angle + rnd(-45.0, 45.0);
        
        // Calculate target point based on wander angle
        if (target_point = nil) {
            float angle <- wander_angle;
            point new_point <- location + {cos(angle) * base_speed, sin(angle) * base_speed};
            
            // Check if new point is within bounds
            if (new_point.x < 0 or new_point.x > world.shape.width or 
                new_point.y < 0 or new_point.y > world.shape.height) {
                wander_angle <- wander_angle + 180.0; // Turn around if hitting boundary
                new_point <- location;
            }
            target_point <- new_point;
        }
        
        // Move towards target point
        do goto target: target_point speed: base_speed;
        
        // Reset target when reached
        if (location distance_to target_point < base_speed) {
            target_point <- nil;
        }
    }
    
    reflex find_wood when: !has_pile {
        list<wood_pile> visible_piles <- wood_pile at_distance observation_range where (!each.has_owner);
        if (length(visible_piles) > 0) {
            wood_pile target <- visible_piles with_min_of (each distance_to self);
            if (target != nil) {
                do goto target: target speed: base_speed;
                if (location distance_to target < 1.0) {
                    do claim_pile(target);
                }
            }
        }
    }
    
    reflex check_pile when: has_pile {
        list<collector> nearby_collectors <- collector at_distance observation_range;
        list<wood_pile> visible_piles <- wood_pile at_distance observation_range;
        
        loop pile over: visible_piles {
            if (pile.has_owner and pile != my_pile) {
                list<collector> owners <- collector where (each.my_pile = pile);
                if (empty(owners)) {
                    bool any_owner_watching <- false;
                    loop potential_owner over: nearby_collectors {
                        if (potential_owner.my_pile = pile) {
                            any_owner_watching <- true;
                            break;
                        }
                    }
                    if (!any_owner_watching) {
                        do steal_wood(pile);
                    }
                }
            }
        }
    }
    
    action claim_pile(wood_pile pile) {
        if (!pile.has_owner) {
            has_pile <- true;
            my_pile <- pile;
            pile.has_owner <- true;
        }
    }
    
    action steal_wood(wood_pile pile) {
        if (pile.wood_amount > 0) {
            int amount_to_steal <- min([carrying_capacity, pile.wood_amount]);
            pile.wood_amount <- pile.wood_amount - amount_to_steal;
            if (pile.wood_amount <= 0) {
                ask pile { do die; }
            }
        }
    }
    
    aspect base {
        draw circle(1) color: has_pile ? #blue : #red;
        if (has_pile and my_pile != nil) {
            draw line([location, my_pile.location]) color: #black;
        }
    }
}

species wood_pile {
    bool has_owner <- false;
    int wood_amount <- 0;
    
    aspect base {
        draw square(1) color: has_owner ? #green : #brown;
    }
}

experiment driftwood_simulation type: gui {
    parameter "Number of collectors" var: nb_collectors min: 5 max: 50;
    parameter "Wood spawn rate" var: wood_spawn_rate min: 0.0 max: 0.1;
    parameter "Observation range" var: observation_range min: 1.0 max: 10.0;
    
    output {
        display main_display {
            grid environment_grid;
            species collector aspect: base;
            species wood_pile aspect: base;
        }
        
        monitor "Total Wood Piles" value: length(wood_pile);
        monitor "Owned Piles" value: length(wood_pile where each.has_owner);
        monitor "Unowned Piles" value: length(wood_pile where !each.has_owner);
    }
}
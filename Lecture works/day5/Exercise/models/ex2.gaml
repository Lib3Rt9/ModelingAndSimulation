/**
* Name: ex2
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model ex2

/* Insert your model definition here */

global {
	init {
		list<int> beauList <- [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 9];
		write(beauList);
		write("There is " + length(beauList) + " elements in this list");
		write("");
		
		write("The first element of 'beauList' is: " + beauList[0]);
//		write("The first element of 'beauList' is: " + first(beauList));
		write("");
		
		write("Reverse: " + reverse(beauList));
		write("Last: " + last(beauList));
		write("");
		
		write("Ascending sorted: " + beauList sort_by (each));
		write("Ascending sorted: " + sort_by (beauList, each));
		write("Descending sorted: " + beauList sort_by (-each));
		write("Descending sorted: " + reverse(sort_by (beauList, each)));
		write("");
		
		write("List elements greater/equals to 5: " + beauList where (each >= 5));
		write("");
		
		list<int> asc <- sort_by(beauList where (each < 5), each);
		list<int> desc <- reverse(sort_by(beauList where (each >= 5), each));
		list<int> total <- asc + desc;
		
		write(beauList accumulate(each*10));
		write("");
		
		write((beauList where (each > 5)));
		write((beauList where (each > 5)) accumulate(each^2));
		write( ( beauList accumulate(each^2) where (each > 5) ) );
		write("");
		write("");
		write("");
		
		
		
		// CREATE PEOPLE
		create people number: 10;
		write(people);
		
		write("Energy greater than 5: " + people where (each.energy>5));
		write("3 random people: " + 3 among people );
		write("People with max energy: " + people with_max_of each.energy);
		write("People with min energy: " + people with_min_of each.energy);
		write("People with max money: " + people with_max_of each.money);
		write("People with min money: " + people with_min_of each.money);
		write("");
		
		write(" People with max value of energy: " + people max_of each.energy);
		write(" People with min value of energy: " + people min_of each.energy);
		write(" People with max value of money: " + people max_of each.money);
		write(" People with min value of money: " + people min_of each.money);
		write("");
		
		write("All energy value: " + people accumulate (each.energy));
		write("");
		
		write("Sort by energy: " + people sort_by each.energy);
		write("Sort by money: " + people sort_by each.money);
		write("");
		
		write("List - 3 < energy < 6: " + people where(each.energy > 3) where(each.energy < 6));
		write("List - 3 < energy < 6: " + people where(each.energy > 3 and each.energy < 6));
		write("");
		
		write("Lowest energy, greater than 2: " + people where (each.energy > 2) with_min_of each.money);
		write(
			first(sort_by(people where (each.energy > 2 ), each.money))
		);
		write("");
		
		write("Sort money: " + sort_by(people accumulate each.money, -each) );
		write("Check - money > 9: " + !empty(people where (each.money > 9)) );
		write("");
		write("");
		write("");
		
		map<string, float> myMap <- map<string, float>(["ab"::2.0, "dv"::1.0, "fwe"::100.2]);
		
		write("All map values: " + myMap.values);
		write("");
		
		write("Pairs: " + myMap.pairs where(first(each.key = "a")));
		write("");
		 
		write("Prev question - map of name and energy: " + people collect ((each.name)::(each.energy)) );
		write("");
		
		write("Map associating name of people, with list of its 3 coordinates: "
			+ people collect (
				(
					each.name
				)::(
					[
						each.location.x, 
						each.location.y, 
						each.location.z
					]
				)
			)
		);
		write("");
	}
}

species people {
	float energy <- rnd(10.0);
	float money <- rnd(10.0);
	
	
	reflex talk {
		write("" + self + " - energy: " + energy);
	}
	
}

experiment e2 {
	output {
			
	}
}
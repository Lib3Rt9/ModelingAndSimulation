/**
* Name: ex1
* Based on the internal empty template. 
* Author: Lib3Rt9
* Tags: 
*/


model ex1

/* Insert your model definition here */

global {
	list<int> lvalues <- [];
	int N <- 10;
	
	reflex generate {
		create people number: N;
		loop times: N {
//			lvalues <+ rnd(1000);
			lvalues << rnd(1000);
		}
	}
	
}

species people
//	schedules: shuffle(people) {
	schedules: (people sort_by each.money)
{
		
//	int money;
	int money <- 0;
	
	reflex gettingRich {
		int max <- max(lvalues);
		money <- money + max;
//		money << max; 			// not work

//		remove max fomr: lvalues;
		lvalues << max;
		
		write(name + " - " + money);
	}
	
}

experiment e1 type: gui {
	
	output {
		display d1 {
			chart "chart 1" type: series {
				data "Different in max-min money"
//					value: max(people where (each.money > 0)) - min(people where each.money);
					
					value: (people max_of each.money) - (people min_of each.money);
			}
		}	
	}	
}
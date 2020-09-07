#include<iostream>
#include<string>
#include<algorithm>

/*
Red_3D for YaCoding #0: FizzBuzz

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
*/

//stores number and name
struct element {
	std::string name = "";
	unsigned int div = 0;
};

//populates an array (for the mode thing)
element* populate(unsigned short mode, unsigned int* out_size) {
	
	//mah variables
	element* elements;
	std::string input;
	unsigned int size=0, j=0, itmp=0;
	std::string stmp;

	switch (mode) {
	case 0:
		//just good old FizzBuzz
		elements = new element[2];
		*out_size = 2;

		elements[0].name = "Fizz";
		elements[0].div = 3;
		elements[1].name = "Buzz";
		elements[1].div = 5;

		return elements;
	case 1:
		//extra mode
		elements = new element[6];
		*out_size = 6;

		elements[0].name = "Fizz";
		elements[0].div = 3;
		elements[1].name = "Buzz";
		elements[1].div = 5;
		elements[2].name = "Fuzz";
		elements[2].div = 7;
		elements[3].name = "Bizz";
		elements[3].div = 11;
		elements[4].name = "Vizz";
		elements[4].div = 17;
		elements[5].name = "Vuzz";
		elements[5].div = 32;

		return elements;
	default:
		//custom mode
		std::cout << "\n[fizz3 buzz5]...\n";

		//get input and prepare the array
		std::cin.ignore();
		std::getline(std::cin, input);
		size = std::count(input.begin(), input.end(), ' ');
		*out_size = size;
		elements = new element[size + 1];

		//for every char
		for (unsigned int i = 0; i < input.length(); i++) {
			if (input[i] == ' ') {
				//if there is a space we must do all this crap
				if (itmp == 0) {
					//we can not devide by 0 lol
					exit(102);
				}
				elements[j].name = stmp;
				elements[j].div = itmp;
				stmp = "";
				itmp = 0;
				j++;
			}
			else if(input[i] >= '0' && input[i] <= '9') {
				//else if it is a numer we do this
				itmp *= 10;
				itmp += input[i] - '0';
			}
			else {
				//do this if it is a string
				stmp += input[i];
			}
		}

		//if there is something left in ma variables (almost always the last element)
		if (itmp != 0) {
			elements[j].name = stmp;
			elements[j].div = itmp;
			*out_size = *out_size += 1;
		}
		std::cout << "\n\n";
		return elements;
	}
	//if we get here there must be an error
	exit(101);
}

int main() {

	unsigned short mode;
	unsigned int max, size = 0;
	unsigned int* size_p = &size;
	std::string output;

	std::cout << "\n\n\n------------- Red_3D YaCoding #0 FizzBuzz -------------\n\nmode [0]base, [1]extra, [2]custom: ";
	std::cin >> mode;
	std::cout << "\n\ndisplay up to: ";
	std::cin >> max;

	element* elements = populate(mode, size_p);

	//for every number up to max
	for (unsigned int i = 1; i <= max; i++) {
		//for all the divisors
		for (unsigned int j = 0; j < *size_p; j++) {
			//check if divisable and append to string
			if (i % elements[j].div == 0) {
				output += elements[j].name;
			}
		}
		//if the string is empty, set it to the number and print to console
		if (output.empty())output = std::to_string(i);
		std::cout << output << std::endl;
		output = "";
	}

	system("pause");
	return 0;
}

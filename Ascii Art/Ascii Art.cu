#include<vector>
#include<fstream>
#include<stdio.h>
#include<iostream>
#include<filesystem>
#include"Reds_var_defs.hpp"

#include<cuda_runtime.h>
#include<device_launch_parameters.h>

#define fread(a, size) read((char*)&a, size)
#define threads 256

__global__ void process_image(u64 size, u16 char_amount, char* chars, float* density_map, u8 *img, char *output) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;

	if (tid < size) {
		//red, green, blue, average
		u8 r, g, b, a;
		r = img[tid * 3];
		g = img[tid * 3 + 1];
		b = img[tid * 3 + 2];
		a = (r+g+b)/3;

		float min = INFINITY;
		char out;

		float density = (float)a/255;
		for (uint i = 0; i < char_amount; i++) {
			if (abs(density - density_map[chars[i] - 32]) < min) {
				min = abs(density - density_map[chars[i] - 32]);
				out = chars[i];
			}
		}
		output[tid] = out;
	}
	return;
}

int main() {

	//	/-------------\
	//	| device info |
	//	\-------------/
	int dev_ammount;
	cudaDeviceProp dev;
	std::string uuid;
	cudaGetDeviceCount(&dev_ammount);

	std::cout << "----------------------------------------------\n";
	for (int i = 0; i < dev_ammount; i++) {
		cudaGetDeviceProperties(&dev, i);
		std::cout << "id:" << i << '\n';
		std::cout << " - name:         " << dev.name << '\n';
		std::cout << " - gpu clock:    " << dev.clockRate / 1000 << "mhz\n";
		std::cout << " - memory clock: " << dev.memoryClockRate / 1000 << "mhz\n";
		std::cout << " - Compute:      " << dev.major << '.' << dev.minor << '\n';
		std::cout << " - tpb           " << dev.maxThreadsPerBlock << '\n';
	}
	std::cout << "----------------------------------------------\n";

	//	/-----------------\
	//	| filestream shit |
	//	\-----------------/

	std::string path = "D:\\CPP\\C++ Projects\\YaCoding\\Ascii_Art\\images\\HD_Bobby.ppm";


	std::ifstream file(path, std::ios::in | std::ios::binary);
	if (!file.is_open()) {
		std::cout << "ERR[101] could not open: " << path.c_str() << "\n\n";
		exit(101);
	}
	char read;

	//	/-----------\
	//	| read file |
	//	\-----------/
	//magic number
	char identifier[2];
	file.fread(identifier, 2);
	if ((identifier[0] != 'P') | (identifier[1] != '6')) {
		std::cout << "ERR[102] this aint a ppm, identifier is: " << identifier[0] << identifier[1] << "\n\n";
		file.close();
		exit(102);
	}
	else {
		std::cout << "\n loaded [" << path << "], processing...\n\n";
	}

	//whitespace
	file.fread(read, 1);
	read = '0';

	//width
	u16 width = 0;
	file.fread(read, 1);
	while ((read >= '0') && (read <= '9')) {
		width *= 10;
		width += atoi(&read);
		file.fread(read, 1);
	}
	std::cout << " ----------------\n | width  | " << width << " |\n ----------------\n";
	read = '0';

	//height
	u16 height = 0;
	file.fread(read, 1);
	while ((read >= '0') && (read <= '9')) {
		height *= 10;
		height += atoi(&read);
		file.fread(read, 1);
	}
	std::cout << " | height | " << height << " |\n ----------------\n";
	read = '0';

	//maxcol
	u16 maxcol = 0;
	file.fread(read, 1);
	while ((read >= '0') && (read <= '9')) {
		maxcol *= 10;
		maxcol += atoi(&read);
		file.fread(read, 1);
	}
	if (maxcol != 255) {
		std::cout << "\nERR[103] maxcol is not 255, image not supported.\n\n";
		file.close();
		exit(103);
	}
	std::cout << " | maxcol | " << maxcol << " |\n ----------------\n\n";
	read = '0';

	//pixels
	u8* image = new u8[height * width * 3];
	file.read((char*)image, (height * width) * 3);

	//	/----------------------------------------------------------\
	//	|                      Character set                       |
	//	| duck users and their need to controll stuff, smh my head |
	//	\----------------------------------------------------------/
	char* charset;
	u16 char_amount = 0;
	char input = 0;
	std::cout << "choose a charset:\n - [0]: Custom\n - [1]: [^:.-=+\'\"@\\/]\n - [2]: [*~,#]\n";
ccs:
	input = getchar();
	switch (input) {
	case '1': {
		charset = "^:.-=+'\"@\\/";
		char_amount = 11;
		break;
	}
	case '2': {
		charset = "*~,#";
		char_amount = 4;
		break;
	}
	case '0': {
		std::cout << "\n - input charset: ";
		std::string tmp;
		std::cin >> tmp;
		charset = new char[tmp.length() + 1];
		strcpy(charset, tmp.c_str());
		char_amount = tmp.length();
		break;
	}
	default: {
		input = 0;
		std::cin.clear();
		goto ccs;
		break;
	}
	}
	std::cout << "\nusing charset: [" << charset << "] | length: " << char_amount << '\n';


	//	/------------\
	//	| Cuda Stuff |
	//	\------------/
	//host stuff
	char* host_out = new char[height * width];
	float density[95] = { 0.0f, 0.292538f, 0.244776f, 0.665671f, 0.752239f, 0.770149f, 0.752239f, 0.122388f, 0.349255f, 0.355223f, 0.331342f, 0.313432f, 0.18209f, 0.107463f, 0.101493f, 0.310448f, 0.674626f, 0.489553f, 0.525373f, 0.438805f, 0.549254f, 0.540299f, 0.573135f, 0.405969f, 0.695523f, 0.549254f, 0.191045f, 0.277612f, 0.280596f, 0.304477f, 0.283583f, 0.361194f, 1.0f, 0.614925f, 0.662687f, 0.468656f, 0.677613f, 0.555225f, 0.420895f, 0.629851f, 0.573135f, 0.447762f, 0.385075f, 0.537312f, 0.340297f, 0.704478f, 0.725372f, 0.58806f, 0.555225f, 0.808956f, 0.650745f, 0.540299f, 0.37612f, 0.519402f, 0.552238f, 0.728359f, 0.602984f, 0.432836f, 0.534328f, 0.42985f, 0.310448f, 0.42985f, 0.197015f, 0.197015f, 0.0597015f, 0.537312f, 0.552238f, 0.337313f, 0.570148f, 0.504476f, 0.450746f, 0.805969f, 0.498508f, 0.41194f, 0.480598f, 0.489553f, 0.420895f, 0.629851f, 0.432836f, 0.462685f, 0.56418f, 0.56418f, 0.340297f, 0.41791f, 0.432836f, 0.432836f, 0.405969f, 0.543283f, 0.459701f, 0.519402f, 0.423881f, 0.426865f, 0.35821f, 0.42985f, 0.220895f };

	//device stuff
	u8* dev_image;
	char* dev_out;
	char* dev_charset;
	float* dev_density;

	cudaMalloc(&dev_image, 3 * (height * width));
	cudaMemcpy(dev_image, image, 3 * (height * width), cudaMemcpyHostToDevice);
	cudaMalloc(&dev_out, height * width);
	cudaMalloc(&dev_charset, char_amount);
	cudaMemcpy(dev_charset, charset, char_amount, cudaMemcpyHostToDevice);
	cudaMalloc(&dev_density, sizeof(density));
	cudaMemcpy(dev_density, density, sizeof(density), cudaMemcpyHostToDevice);

	//launch kernels, sync and copy back to host
	process_image<<<(height * width) / threads + 1, threads>>>(height * width, char_amount, dev_charset, dev_density, dev_image, dev_out);
	cudaDeviceSynchronize();
	cudaMemcpy(host_out, dev_out, height * width, cudaMemcpyDeviceToHost);
	std::cout << "\n ------------------\n | cuda |  done   |\n ------------------\n";

	//	/--------\
	//	| output |
	//	\--------/
	std::ofstream file_out("out.txt", std::ios::out);
	std::string tmp;

	for (u64 i = 0; i < height * width; i++) {
		tmp += host_out[i];
		tmp += ' ';
		if ((i + 1) % width == 0) {
			tmp += '\n';
		}
	}

	file_out << tmp;
	file_out.close();

	std::cout << " | file | written |\n ------------------\n";

	//	/----------------------------------------------\
	//	| Be a responsable dev and recycle your memory |
	//	\----------------------------------------------/
	cudaFree(dev_image);
	cudaFree(dev_out);
	cudaFree(dev_charset);
	cudaFree(dev_density);
	delete[] image;
	delete[] host_out;
	file.close();
	return 0;
}
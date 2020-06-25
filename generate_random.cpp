#include <iostream>
#include <fstream>
#include <random>
using namespace std;

double fRand(double fMin, double fMax) {
  return fMin + (double) rand() / RAND_MAX * (fMax - fMin);
}

int main() {
  ofstream outfile("dataset.json");
  srand(time(NULL));
  outfile << '[' << endl;
  for (int i = 0; i < 5000; i++)
    outfile << "{\"lat\" : " << fRand(-38.193946, -12.443192) << ", \"lng\" : " << fRand(113.945225, 153.226265) << "} ," << endl;
  outfile << "{\"lat\" : " << fRand(-38.193946, -12.443192) << ", \"lng\" : " << fRand(113.945225, 153.226265) << "}" << endl << ']' << endl;
  return 0;
}

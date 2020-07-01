#include <iostream>
#include <fstream>
using namespace std;

int main() {
  ifstream infile;
  infile.open("raw_input.txt");
  ofstream outfile;
  outfile.open("dataset.json");
  double a, b;
  while (!infile.eof()) {
    infile >> a >> b;
    outfile << "{\"lat\" : " << a << ", \"lng\" : " << b << "} ," << endl;
  }
  outfile << "{\"lat\" : " << a << ", \"lng\" : " << b << "}" << endl << ']' << endl;
  return 0;
}

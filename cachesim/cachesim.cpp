#include <cstddef>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <assert.h>
#include <inttypes.h>
#define ICACHE_NUMS 1
#define ICACHE_SIZE 16
#define INDEX_MASK 0x0f
struct Cache{
  bool valid;
  int tag;
};

struct CachePerf{
  int miss = 0;
  int total;

  ~CachePerf(){
    std::cout << "cache miss = " << miss << '\n';
  }
};

int cachesim(char* itrace){
  assert(itrace != NULL);
  CachePerf perf;
  std::string filename(itrace);
  std::ifstream file(filename);
  std::vector<uint32_t>  pcs;
  std::string line;
  while(std::getline(file, line)){
    size_t pos = line.find(':');
    std::string pc_str = line.substr(0, pos);
    std::stringstream ss(pc_str);
    uint32_t pc;
    ss >> std::hex >> pc;
    /* std::cout << std::hex << pc << '\n'; */
    pcs.emplace_back(pc);
  }
  file.close();
  perf.total = pcs.size();
  Cache mcache[ICACHE_NUMS];
  for(int pc : pcs){
    int index = (pc>>2) & INDEX_MASK;
    if(!mcache[index].valid || mcache[index].tag != pc){
      perf.miss ++;
      mcache[index].valid = 1;
      mcache[index].tag = pc;
    }
  }
  return perf.miss;
}

int main(int argc, char*args[]){
  cachesim(args[1]);
  return 0;
}

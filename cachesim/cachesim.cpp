#include <cstddef>
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <cmath>
#include <assert.h>
#include <inttypes.h>
#define ICACHE_NUMS 16
#define ICACHE_SIZE 1
#define TAG(pc) (pc >> (int)(std::log2(ICACHE_SIZE) + 2 + std::log2(ICACHE_NUMS)))
#define INDEX(pc) ((pc >> (int)(std::log2(ICACHE_SIZE) + 2)) & (int)(ICACHE_NUMS - 1))
struct MissCost{
  int a = 1, b = 1, c = 1, d = 1;
  bool is_pipeline = false;
  int cache_size = ICACHE_SIZE;
  int cache_type = 0;
  MissCost() = default;
  MissCost(int a, int b, int c, int d, bool is_pipeline, int cache_size, int cache_type)
    :a(a), b(b), c(c), d(d), is_pipeline(is_pipeline), cache_size(cache_size), cache_type(cache_type){}
  int miss(){
    return is_pipeline ? (a+b+d+cache_size*c) : cache_size*(a+b+c+d);
  }
};

struct Cache{
  bool valid = false; 
  int tag = 0;
};

struct CachePerf{
  int miss = 0;
  int hit = 0;
  int hit_cost = 1;
  MissCost miss_cost;
  float miss_p(){
    return (miss+hit) == 0? 0 : (float)miss / (float)(miss + hit);
  }
  float atmt(){
    return (float)hit_cost + (float)miss_cost.miss() * miss_p();
  }  
  
  ~CachePerf(){
    std::cout << "cache miss = " << miss << '\n' << "cache hit = " << hit << '\n';
    std::cout << "miss 占比: " << miss_p()*100 << "%\n";
    std::cout << "ATMT = " << atmt() << '\n';
  }
};

int cachesim(char* itrace){
  MissCost mc;
  assert(itrace != NULL);
  CachePerf perf;
  perf.miss_cost.is_pipeline = true;
  //std::string itrace_type(".txt");
  std::string filename(itrace);
  //std::string filename = itrace_name + itrace_type;
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
  std::cout << "inst nums = " << pcs.size() << '\n';
  Cache mcache[ICACHE_NUMS];
  for(int pc : pcs){
    int index = INDEX(pc);
    if(!mcache[index].valid || mcache[index].tag != TAG(pc)){
      perf.miss ++;
      /* std::cout << std::hex << pc << '\n'; */
      mcache[index].valid = 1;
      mcache[index].tag = TAG(pc);
    }
    else {
      perf.hit ++;
    }
  }
  return perf.miss;
}

int main(int argc, char*args[]){
  cachesim(args[1]);
  return 0;
}

/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <assert.h>
#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_INT,TK_HEX,TK_REG, TK_PLUS,TK_SUB, TK_MUL, TK_DIV, TK_LEFT, TK_RIGHT, TK_EQ, TK_NEQ, TK_LAND, TK_NOTYPE = 256,TK_NEG,TK_DEREF, 

  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */
  {"0[xX][0-9,a-f]+",TK_HEX},
  {"[0-9]+",TK_INT},
  //{"\\$(x([0-9]|[1-2][0-9]|3[0-1]))|t[0-6]|a[0-7]|s[0-11]|[stg]p",TK_REG},
  {"\\$[a-z\\$]+[0-9]*", TK_REG},
  {" +", TK_NOTYPE},    // spaces
  {"\\+", TK_PLUS},         // plus
  {"==", TK_EQ},        // equal
  {"!=", TK_NEQ},
  {"-", TK_SUB},
  {"\\*", TK_MUL},
  {"/", TK_DIV},
  {"\\(", TK_LEFT},
  {"\\)", TK_RIGHT},
  {"&&", TK_LAND}
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;
  while (e[position] != '\0') {
    
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        
        switch (rules[i].token_type) {
          case TK_PLUS:
          case TK_DIV:
          case TK_LEFT:
          case TK_RIGHT:
          case TK_EQ:
          case TK_NEQ:
          case TK_LAND:
            tokens[nr_token++].type = rules[i].token_type;
            break;
          case TK_MUL:
            if(nr_token==0 
                || (tokens[nr_token-1].type!=TK_INT 
                && tokens[nr_token-1].type!=TK_RIGHT ))
              tokens[nr_token++].type = TK_DEREF;
            else{
              tokens[nr_token++].type = rules[i].token_type;
            }
            break;
          case TK_SUB:
            if(nr_token==0 
                || (tokens[nr_token-1].type!=TK_INT 
                && tokens[nr_token-1].type!=TK_RIGHT ))
              tokens[nr_token++].type = TK_NEG;
            else{
              tokens[nr_token++].type = rules[i].token_type;
            }
            break;
          case TK_INT:
          case TK_HEX:
          case TK_REG:
            strncpy(tokens[nr_token].str, substr_start, substr_len);
            tokens[nr_token++].type = rules[i].token_type;
            break;
          default: break;
        }
      }
    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }
  }
  return true;
}

static bool check_valid(int p, int q)
{
  int n = 0;
  while(p <= q)
  {
    if(tokens[p].type == TK_LEFT) n++;
    else if(tokens[p].type == TK_RIGHT ) n--;

    if(n < 0) return false;
    p++;
  }
  if(n != 0) return false;
  return true;
}


static bool check_parentheses(int p, int q){
  if(tokens[p].type != TK_LEFT || tokens[q].type != TK_RIGHT)
    return false;
  int n = 0;
  do {
      if(tokens[p].type == TK_LEFT) n++;
      else if(tokens[p].type == TK_RIGHT) n--;
      if(n == 0) return false;
  }while (p++ < q - 1);
  return true;
}

static int main_op(int p, int q){
  int priority = 0;
  int flag = 0;
  int now = 0;
  int op = p;
  while(p <= q){
    switch(tokens[p].type){
      case TK_PLUS: 
      case TK_SUB : priority = 4; break;
      case TK_DIV : 
      case TK_MUL : priority = 3; break;
      case TK_EQ  :
      case TK_NEQ : priority = 5; break;
      case TK_LAND: priority = 2; break;
      case TK_LEFT: flag++;break;
      case TK_RIGHT:flag--;break;
      default: priority = -1; break;
    }
    if(flag==0 && now <= priority){
      now = priority;
      op = p;
    }
    p++;
  }
  return op;
}
word_t vaddr_read(vaddr_t addr, int len);

static int eval(int p, int q){
  if(p > q){
    printf("p > q\n");
    assert(0);
  }
  else if(p == q){
    word_t result;
    switch(tokens[p].type){
        case TK_INT:sscanf(tokens[p].str, "%u", &result);break;
        case TK_HEX:sscanf(tokens[p].str, "%x", &result);break;
        case TK_REG:
            bool success = true;
            result = isa_reg_str2val(1+tokens[p].str, &success);
            if(!success) assert(0);
            break;
        default: assert(0);
    }
    return result;
  }
  else if(tokens[p].type == TK_NEG){
    return -eval(p+1, q);
  }
  else if(tokens[p].type == TK_DEREF){
    return vaddr_read(eval(p+1, q), sizeof(word_t));
  }
  else if(!check_valid(p, q)){
    printf("wrong parentheses numbers\n");
    assert(0);
  }
  else if(check_parentheses(p, q)){
    return eval(p + 1, q - 1);
  }
  else {
      int op = main_op(p, q);
      word_t val1 = eval(p, op - 1);
      word_t val2 = eval(op + 1, q);

      switch(tokens[op].type){
        case TK_PLUS: return val1 + val2;break;
        case TK_SUB : return val1 - val2;break;
        case TK_MUL : return val1 * val2;break;
        case TK_DIV : return val1 / val2;break;
        case TK_EQ  : return val1 == val2;break;
        case TK_NEQ : return val1 != val2;break;
        case TK_LAND: return val1 && val2;break;
        default:printf("invalid op\n");assert(0);
      }
  }
}

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }
  word_t result = eval(0, nr_token - 1);
  *success = true;
  nr_token = 0;
  /* TODO: Insert codes to evaluate the expression. */
  //TODO();

  return result;
}

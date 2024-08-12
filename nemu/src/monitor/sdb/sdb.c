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

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_help(char *args);

static int cmd_si(char *args){
  if(args == NULL){
    cpu_exec(1);
  }
  else {
    cpu_exec(atoi(args));
  }
  return 0;
}
static int cmd_info(char *args){
  switch(args[0]){
    case'r':
      isa_reg_display(&cpu);
      return 0;
    case'w':
      printf("Num\tType\t\t\tWhat\n");
      WP* wp = get_head();
      while(wp!=NULL)
      {
        printf("%d\t%s\t\t%s\n", wp->NO,"watchpoint", wp->str);
        wp = wp->next;
      }
      return 0;   
    default:
      printf("false option \"%s\"\n", args);
  }
  return 0;
}
word_t vaddr_read(vaddr_t addr, int len);
static int cmd_x(char *args){
  if(args == NULL){
    printf("false option\n");
    return 0;
  }
  char* cmd1 = strtok(args, " ");
  char* cmd2 = args + strlen(cmd1) + 1;
  if(cmd2 == NULL){
    printf("false option\n");
    return 0;
  }
  int n = atoi(cmd1);
  word_t addr;
  sscanf(cmd2, "%x", &addr);
  if(addr == 0){
    printf("false option\n");
    return 0;
  }
  for(int i = 0; i < n; i++){
    printf("0x%08x ",vaddr_read(addr+i*4, 4));
  }
  printf("\n");
  return 0;
}
static int cmd_p(char *args){
  char fmt[32] = "(%s) = ";
  char default_fmt[3] = "%d";
  char *args_fmt = NULL;
  if(args[0] == '%'){
    args_fmt = strtok(args, " ");
    args = args + strlen(args_fmt) + 1;
  }
  else{
    args_fmt = default_fmt;
  }
  strcat(fmt, args_fmt);
  bool success;
  word_t result = expr(args, &success);
  printf(fmt, args, result);
  printf("\n");
  return 0;
}
static int cmd_w(char *args){
  WP* wp = new_wp();
  bool success;
  word_t result = expr(args, &success);
  if(!success) {printf("cmd_w error\n");assert(0);}
  wp->value = result;
  strcpy(wp->str, args);
  printf("Add watchpoint %d, %s = %u\n", wp->NO, wp->str, wp->value);
  return 0;
}
static int cmd_d(char *args){
  if(args == NULL) {
    printf("no arguments\n");
    return 0;
  }
  int n = atoi(args);
  WP* wp = get_head();
  while(wp != NULL){
    if(wp->NO == n) {
      free_wp(wp);
      return 0;
    }
    wp = wp->next;
  }
  printf("no watchpoint %s\n", args);
  return 0;
}
static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si", "singal execute", cmd_si },
  { "info", "show state", cmd_info},
  { "x", "memory scanning", cmd_x},
  { "p", "expr", cmd_p},
  { "w", "set watchpoint", cmd_w},
  { "d", "delete watchpoint", cmd_d},

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}

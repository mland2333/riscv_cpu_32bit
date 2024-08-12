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

#include "sdb.h"

#define NR_WP 32



static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;
static int now = 0;
void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].value = 0;
    wp_pool[i].str = NULL;
  }

  head = NULL;
  free_ = wp_pool;
}

WP* new_wp(){
  if(free_ == NULL) assert(0);
  WP* result = free_;
  free_ = free_->next;
  result->NO = now++;
  if(head == NULL){
    head = result;
    head->next = NULL;
  }
  else{
    result->next = head->next;
    head = result;
  }
  result->str = malloc(32);
  return result;
}

void free_wp(WP* wp){
  WP* pre = head;
  if(wp == NULL || head == NULL) assert(0);
  if(wp == head)
    head = head->next;
  else{
    while(pre->next != wp) pre = pre->next;
    pre->next = wp->next;
  }
  free(wp->str);
  if(free_ == NULL){
    free_ = wp;
    wp->next = NULL;
  }
  else {
    wp->next = free_->next;
    free_ = wp;
  }
}
WP* get_head(){
  return head;
}
/* TODO: Implement the functionality of watchpoint */


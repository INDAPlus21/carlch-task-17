#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#define min(a,b) \
  ({__typeof__ (a) _a = (a); \
    __typeof__ (b) _b = (b); \
    _a < _b ? _a : _b; })

// OPERATIONS
// --------------------------
// (1) Remove a letter
// (2) Add a letter
// (3) Change a letter

// REQUIRMENTS
// --------------------------
// * Max length of 40
// * Contains only a-ö
// * # ends current word

void diff(const char *a, const char *b) {
  // Reduce 'strlen' calls
  int alen = strlen(a), blen = strlen(b);
  int i, j;
  int prev_ops[2][alen + 1];
  char *_b[blen];
  memcpy(_b, b, blen + 1);
  // clear matrix
  memset(prev_ops, 0, sizeof(prev_ops));
  for(i = 0; i < alen + 1; i++)
    prev_ops[0][i] = i;

  for(i = 1; i < blen + 1; i++) {
    for(j = 0; j < alen + 1; j++) {
      if(j == 0)
        prev_ops[i % 2][j] = i;
      else if(a[j - 1] == b[i - 1])
        prev_ops[i % 2][j] = prev_ops[(i - 1) % 2][j - 1];
      else {
        prev_ops[i % 2][j] = 1 + min(prev_ops[(i - j) % 2][j],
                                 min(prev_ops[i % 2][j - 1], 
                                     prev_ops[(i - 1) % 2][j-1]));
      }
    }
  }
  
}

#define MAX 40
char *word[MAX];
char buff[MAX];

int main(void) {
  memset(word, 0, MAX); // clear input buffer
  // fread(word, sizeof(char), 1, stdin);
  diff("hello", "yoyo");
}

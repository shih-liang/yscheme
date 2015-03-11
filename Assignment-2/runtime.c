#include <stdlib.h>
#include <stdio.h>

extern long scheme_entry(void*, void*);

void 
print(long x) {
  printf("%ld\n", x);
}

int
main(int argc, char *argv[]) {
	void *stack;
	void *heap;
	
  if (argc != 1) {
    fprintf(stderr, "usage: %s\n", argv[0]);
    exit(1);
  }
  
  stack = malloc(100);
  heap = malloc(100);

  print(scheme_entry(stack, heap));
  
  free(stack);
  free(heap);
  return 0;
}

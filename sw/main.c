// M6 verification program: no OS, no stdlib. Result is observed by the
// testbench reading data memory directly (no UART in this design), so the
// program writes its answer to a fixed address and then halts.

#define RESULT_ADDR 0x100

int main(void) {
    volatile int *result = (volatile int *)RESULT_ADDR;
    int sum = 0;

    for (int i = 1; i <= 10; i++) {
        sum += i;
    }

    *result = sum; // expected: 55
    return 0;      // falls through to start.s's halt loop
}

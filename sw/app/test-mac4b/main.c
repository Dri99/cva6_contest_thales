#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

typedef uint32_t p4uint8_t;
typedef int32_t p4int8_t;

#define MAC4B
static inline int32_t mac4b(int32_t sum_in, p4uint8_t inputs, p4int8_t weights)
{
    int32_t result = 0;
    
#   ifdef MAC4B
    asm inline ( "mac4b %0, %1, %2, %3"
                 : "=r"(result)
                 : "r"(inputs), "r"(weights), "r"(sum_in)
        );
#   else
    for (int i = 0; i < 4; i++) {
        int input = (inputs << 24) >> 24;
        int weight = (weights << 24) >> 24;
        result += input * weight;
        inputs = inputs >> 8;
        weights = weights >> 8;
    }
#   endif
    return result;
}

int32_t loop_mac4b(int32_t result, p4uint8_t inputs, p4int8_t weights) {
    for (int i = 0; i < 4; i++) {
        int input = (inputs << 24) >> 24;
        int weight = (weights << 24) >> 24;
        result += input * weight;
        inputs = inputs >> 8;
        weights = weights >> 8;
    }
    return result;
}


int main(void) {
    uint8_t inputs[] __attribute__ ((aligned (4))) = {2, 24, 67, 249};
    int8_t weights[] __attribute__ ((aligned (4))) = {-128, 0, 4, -19};
    int32_t sum = 1025;

    p4uint8_t pinputs = *((p4uint8_t*)inputs);
    p4int8_t pweights = *((p4uint8_t*)weights);

    int32_t sum1 = mac4b(sum, pinputs, pweights);
    printf("%d\n", sum1);
    
    int32_t sum2 = loop_mac4b(sum, pinputs, pweights);
    printf("%d\n", sum2);
    
    return 0;
}

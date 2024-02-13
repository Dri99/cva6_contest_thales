#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "cpp_utils.h"
#include "env.h"
#include "Network.h"
#include "util.h"

#include "hpm.h"

size_t macsOnRange_time = 0;
int macsOnRange_calls = 0;

void readStimulus(
                  UDATA_T* inputBuffer,
                  Target_T* expectedOutputBuffer)
{
    envRead(ENV_SIZE_Y*ENV_SIZE_X*ENV_NB_OUTPUTS,
            ENV_SIZE_Y, ENV_SIZE_X,
            (DATA_T*) inputBuffer, //TODO
            OUTPUTS_SIZE[0], expectedOutputBuffer);
}

int processInput(        UDATA_T* inputBuffer,
                            Target_T* expectedOutputBuffer,
                            Target_T* predictedOutputBuffer,
			    UDATA_T* output_value)
{
    size_t nbPredictions = 0;
    size_t nbValidPredictions = 0;

    propagate(inputBuffer, predictedOutputBuffer, output_value);

    // assert(expectedOutputBuffer.size() == predictedOutputBuffer.size());
    for(size_t i = 0; i < OUTPUTS_SIZE[0]; i++) {
        if (expectedOutputBuffer[i] >= 0) {
            ++nbPredictions;

            if(predictedOutputBuffer[i] == expectedOutputBuffer[i]) {
                ++nbValidPredictions;
            }
        }
    }

    return (nbPredictions > 0)
        ? nbValidPredictions : 0;
}


int main(int argc, char* argv[]) {

    // const N2D2::Network network{};
    size_t instret, cycles;
    size_t il1_miss, dl1_miss;
    size_t loads, stores;
    size_t stalls, sb_full;

#if ENV_DATA_UNSIGNED
    UDATA_T inputBuffer[ENV_SIZE_Y*ENV_SIZE_X*ENV_NB_OUTPUTS];
#else
    std::vector<DATA_T> inputBuffer(network.inputSize());
#endif

    Target_T expectedOutputBuffer[OUTPUTS_SIZE[0]];
    Target_T predictedOutputBuffer[OUTPUTS_SIZE[0]];
    UDATA_T output_value;

    readStimulus(inputBuffer, expectedOutputBuffer);
    
#ifndef X86
    // Active les compteurs de performance
    write_csr(mhpmevent3, HPM_L1_ICACHE_MISSES);
    write_csr(mhpmevent4, HPM_L1_DCACHE_MISSES);
    write_csr(mhpmevent5, HPM_LOADS);
    write_csr(mhpmevent6, HPM_STORES);
    write_csr(mhpmevent7, HPM_STALL);
    write_csr(mhpmevent8, HPM_MSB_FULL);

    il1_miss = -read_csr(mhpmcounter3);
    dl1_miss = -read_csr(mhpmcounter4);
    loads = -read_csr(mhpmcounter5);
    stores = -read_csr(mhpmcounter6);
    stalls = -read_csr(mhpmcounter7);
    sb_full = -read_csr(mhpmcounter8);
    
    instret = -read_csr(minstret);
    cycles = -read_csr(mcycle);
#endif

    int success;
#ifdef X86
    for (int i=0; i<1000000; i++) {
#endif
    success = processInput(inputBuffer, 
                                     expectedOutputBuffer, 
                                     predictedOutputBuffer,
                                     &output_value);
#ifdef X86
    }
#endif
#ifndef X86
    instret += read_csr(minstret);
    cycles += read_csr(mcycle);

    il1_miss += read_csr(mhpmcounter3);
    dl1_miss += read_csr(mhpmcounter4);
    loads += read_csr(mhpmcounter5);
    stores += read_csr(mhpmcounter6);
    stalls += read_csr(mhpmcounter7);
    sb_full += read_csr(mhpmcounter8);
#endif

    printf("Expected  = %d\n", expectedOutputBuffer[0]);
    printf("Predicted = %d\n", predictedOutputBuffer[0]);
    printf("Result : %d/1\n", success);
    printf("credence: %d\n", output_value);
    printf("image %s: %d instructions\n", stringify(MNIST_INPUT_IMAGE), (int)(instret));
    printf("image %s: %d cycles\n", stringify(MNIST_INPUT_IMAGE), (int)(cycles));
    printf("il1_miss : %d\n", (int)il1_miss);
    printf("dl1_miss : %d\n", (int)dl1_miss);
    printf("loads : %d\n", (int)loads);
    printf("stores : %d\n", (int)stores);
    printf("stalls : %d\n", (int)stalls);
    printf("scoreboard full : %d\n", (int)sb_full);

    printf("macsOnRange calls : %d\n", macsOnRange_calls);
    printf("macsOnRange cycles : %d\n", (int)macsOnRange_time);

#ifdef OUTPUTFILE
    FILE *f = fopen("success_rate.txt", "w");
    if (f == NULL) {
        N2D2_THROW_OR_ABORT(std::runtime_error,
            "Could not create file:  success_rate.txt");
    }
    fprintf(f, "%f", successRate);
    fclose(f);
#endif
}

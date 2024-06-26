#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "cpp_utils.h"
#include "env.h"
#include "Network.h"
#include "util.h"

#include "hpm.h"

#ifdef BENCHMARK
size_t macsOnRange_time = 0;
int macsOnRange_calls = 0;
size_t align32_time = 0;
size_t align32_count = 0;

size_t time_conv1, time_conv2, time_fc1, time_fc2, time_max;
size_t stall_conv1, stall_conv2, stall_fc1, stall_fc2, stall_max;
size_t branch_conv1, branch_conv2, branch_fc1, branch_fc2, branch_max;
size_t bmis_conv1, bmis_conv2, bmis_fc1, bmis_fc2, bmis_max;
#endif // BENCHMARK

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
#ifdef BENCHMARK
    size_t il1_miss, dl1_miss;
    size_t loads, stores;
    size_t stalls, sb_full;
#endif // BENCHMARK

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
#ifdef BENCHMARK
    // Active les compteurs de performance
    write_csr(mhpmevent3, HPM_L1_ICACHE_MISSES);
    write_csr(mhpmevent4, HPM_L1_DCACHE_MISSES);
    //write_csr(mhpmevent5, HPM_LOADS);
    write_csr(mhpmevent5, HPM_L1_ICACHE_ACCESS);
    //write_csr(mhpmevent6, HPM_STORES);
    write_csr(mhpmevent6, HPM_L1_DCACHE_ACCESS);
    //write_csr(mhpmevent7, HPM_BRANCHS);
    //write_csr(mhpmevent8, HPM_BRANCH_MIS);
    write_csr(mhpmevent7, HPM_STALL);
    write_csr(mhpmevent8, HPM_MSB_FULL);

    il1_miss = -read_csr(mhpmcounter3);
    dl1_miss = -read_csr(mhpmcounter4);
    loads = -read_csr(mhpmcounter5);
    stores = -read_csr(mhpmcounter6);
    stalls = -read_csr(mhpmcounter7);
    sb_full = -read_csr(mhpmcounter8);
#endif // BENCHMARK
    
    instret = -read_csr(minstret);
    cycles = -read_csr(mcycle);
#endif // not X86

    int success;
    
    success = processInput(inputBuffer, 
                                     expectedOutputBuffer, 
                                     predictedOutputBuffer,
                                     &output_value);

#ifndef X86
    instret += read_csr(minstret);
    cycles += read_csr(mcycle);

#ifdef BENCHMARK
    il1_miss += read_csr(mhpmcounter3);
    dl1_miss += read_csr(mhpmcounter4);
    loads += read_csr(mhpmcounter5);
    stores += read_csr(mhpmcounter6);
    stalls += read_csr(mhpmcounter7);
    sb_full += read_csr(mhpmcounter8);
#endif // BENCHMARK
#endif // not X86

    printf("\n==============================\n");
    printf("Expected  = %d\n", expectedOutputBuffer[0]);
    printf("Predicted = %d\n", predictedOutputBuffer[0]);
    printf("Result : %d/1\n", success);
    printf("credence: %d\n", output_value);
    printf("image %s: %d instructions\n", stringify(MNIST_INPUT_IMAGE), (int)(instret));
    printf("image %s: %d cycles\n", stringify(MNIST_INPUT_IMAGE), (int)(cycles));
#ifdef BENCHMARK
    printf("il1_miss : %d\n", (int)il1_miss);
    printf("dl1_miss : %d\n", (int)dl1_miss);
    printf("loads : %d\n", (int)loads);
    printf("stores : %d\n", (int)stores);
    printf("stalls : %d\n", (int)stalls);
    printf("scoreboard full : %d\n", (int)sb_full);
    printf("\n");
    printf("macsOnRange calls : %d\n", macsOnRange_calls);
    printf("macsOnRange cycles : %d\n", (int)macsOnRange_time);
    printf("align32 count : %d\n", (int)align32_count);
    printf("align32 cycles : %d\n", (int)align32_time);
    printf("\n");
    printf("conv1 %d cycles\n", time_conv1);
    printf("conv2 %d cycles\n", time_conv2);
    printf("fc1 %d cycles\n", time_fc1);
    printf("fc2 %d cycles\n", time_fc2);
    printf("max %d cycles\n", time_max);
    printf("\n");
    printf("conv1 %d branch\n", branch_conv1);
    printf("conv2 %d branch\n", branch_conv2);
    printf("fc1 %d branch\n", branch_fc1);
    printf("fc2 %d branch\n", branch_fc2);
    printf("max %d branch\n", branch_max);
    printf("\n");
    printf("conv1 %d branch mis\n", bmis_conv1);
    printf("conv2 %d branch mis\n", bmis_conv2);
    printf("fc1 %d branch mis\n", bmis_fc1);
    printf("fc2 %d branch mis\n", bmis_fc2);
    printf("max %d branch mis\n", bmis_max);
    printf("\n");
    printf("conv1 %d stalls\n", stall_conv1);
    printf("conv2 %d stalls\n", stall_conv2);
    printf("fc1 %d stalls\n", stall_fc1);
    printf("fc2 %d stalls\n", stall_fc2);
    printf("max %d stalls\n", stall_max);
#endif // BENCHMARK

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

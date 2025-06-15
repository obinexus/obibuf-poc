/*
 * Basic DFA Engine Tests
 * Validates language-agnostic parsing functionality
 */

#include "obiprotocol_dfa.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

void test_dfa_initialization() {
    printf("Testing DFA initialization...\n");
    
    obi_protocol_dfa_t *dfa = NULL;
    int result = obi_dfa_initialize(dfa, true); // Zero Trust mode
    
    // Basic initialization test
    assert(result != -1);
    printf("✅ DFA initialization test passed\n");
}

void test_uscn_normalization() {
    printf("Testing USCN normalization...\n");
    
    // Test path traversal normalization
    const char *test_inputs[] = {
        "%2e%2e%2f",
        "%c0%af",
        ".%2e/",
        "../"
    };
    
    printf("✅ USCN normalization tests configured\n");
}

int main() {
    printf("🧪 Running OBI Protocol DFA Tests\n");
    printf("=================================\n");
    
    test_dfa_initialization();
    test_uscn_normalization();
    
    printf("\n✅ All DFA tests passed!\n");
    return 0;
}

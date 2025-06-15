/*
 * Unit Tests for protocol-state-validation Core
 * OBINexus Computing - Aegis Framework
 */

#include "protocol-state-validation.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

void test_protocol-state-validation_init() {
    printf("Testing protocol-state-validation_init...\n");
    
    protocol-state-validation_result_t result = protocol-state-validation_init();
    assert(result == PROTOCOL-STATE-VALIDATION_SUCCESS);
    
    // Cleanup
    protocol-state-validation_cleanup();
    
    printf("✅ protocol-state-validation_init test passed\n");
}

void test_protocol-state-validation_process() {
    printf("Testing protocol-state-validation_process...\n");
    
    // Initialize
    protocol-state-validation_result_t result = protocol-state-validation_init();
    assert(result == PROTOCOL-STATE-VALIDATION_SUCCESS);
    
    // Test valid input
    const uint8_t test_data[] = "test_input";
    result = protocol-state-validation_process(test_data, strlen((const char*)test_data));
    assert(result == PROTOCOL-STATE-VALIDATION_SUCCESS);
    
    // Test invalid input
    result = protocol-state-validation_process(NULL, 0);
    assert(result == PROTOCOL-STATE-VALIDATION_ERROR_INVALID_INPUT);
    
    // Cleanup
    protocol-state-validation_cleanup();
    
    printf("✅ protocol-state-validation_process test passed\n");
}

int main() {
    printf("🧪 Running protocol-state-validation Unit Tests\n");
    printf("====================================\n");
    
    test_protocol-state-validation_init();
    test_protocol-state-validation_process();
    
    printf("\n✅ All unit tests passed!\n");
    return 0;
}

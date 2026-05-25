//
//  ByeDpiProxy.h
//  ByeDPICore
//
//  C bridge header for byedpi library
//

#ifndef ByeDpiProxy_h
#define ByeDpiProxy_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// byedpi C API
typedef struct bye_dpi_context {
    int tunnel_fd;
    int is_running;
    void* internal_state;
} bye_dpi_context_t;

// Initialize byedpi with arguments
// Returns 0 on success, negative on error
int bye_dpi_init(const char** argv, int argc);

// Start byedpi proxy with tunnel file descriptor
// Returns 0 on success, negative on error
int bye_dpi_start(int tunnel_fd);

// Stop byedpi proxy
void bye_dpi_stop(void);

// Check if byedpi is running
int bye_dpi_is_running(void);

// Get last error message
const char* bye_dpi_get_error(void);

// Test a specific DPI bypass strategy
// Returns 0 if the strategy works (connection successful), non-zero otherwise
// This function runs a quick test connection using the provided arguments
int test_byedpi_strategy(const char** argv, int argc);

#endif /* ByeDpiProxy_h */

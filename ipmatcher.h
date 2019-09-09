#ifndef LUA_RESTY_RADIXTREE_H
#define LUA_RESTY_RADIXTREE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>
#include <ctype.h>


#ifdef BUILDING_SO
    #ifndef __APPLE__
        #define LSH_EXPORT __attribute__ ((visibility ("protected")))
    #else
        /* OSX does not support protect-visibility */
        #define LSH_EXPORT __attribute__ ((visibility ("default")))
    #endif
#else
    #define LSH_EXPORT
#endif

/* **************************************************************************
 *
 *              Export Functions
 *
 * **************************************************************************
 */

int is_valid_ipv4(const char *ipv4);
int is_valid_ipv6(const char *ipv6);
int parse_ipv6(const char *ipv6, unsigned int *addr_32);

#ifdef __cplusplus
}
#endif

#endif

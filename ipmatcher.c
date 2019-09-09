#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h>


int
is_valid_ipv4(const char *ipv4)
{
    struct      in_addr addr;

    if(ipv4 == NULL) {
        return -1;
    }

    if(inet_pton(AF_INET, ipv4, (void *)&addr) != 1) {
        return -1;
    }

    return 0;
}


int
is_valid_ipv6(const char *ipv6)
{
    struct in6_addr addr6;

    if(ipv6 == NULL) {
        return -1;
    }

    if(inet_pton(AF_INET6, ipv6, (void *)&addr6) != 1) {
        return -1;
    }

    return 0;
}

int
parse_ipv6(const char *ipv6, unsigned int *addr_32)
{
    unsigned int       addr6[4];
    int                i;

    if(ipv6 == NULL) {
        return -1;
    }

    if(inet_pton(AF_INET6, ipv6, (void *)addr6) != 1) {
        return -1;
    }

    for (i = 0; i < 4; i++) {
        addr_32[i] = ntohl(addr6[i]);
    }

    return 0;
}

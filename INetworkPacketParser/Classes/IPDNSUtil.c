//
//  IPDNSUtil.c
//  INetworkPacketParser
//
//  Created by admin on 2019/3/13.
//

#include "IPDNSUtil.h"

uint8_t compress_label(const char *domain_label_origin, uint8_t length, uint8_t **compresslabel) {
    
    // deep copy
    char *domain_label = (char *)malloc(length + 1);
    memset(domain_label, 0, length + 1);
    strcpy(domain_label, domain_label_origin);
    
    uint8_t *label = (uint8_t *)domain_label;
    uint8_t *tmp = (uint8_t *)malloc(length + 1 + 1);
    uint8_t *p = tmp;
    memset(tmp, 0, length + 1 + 1);
    memcpy(tmp, &length, 1);
    p++;
    memcpy(p, label, length);
    *compresslabel = tmp;
    return length + 1;
}

uint8_t compress_domain(const char *domain_name_origin, uint8_t length, uint8_t **compresslabel) {
    
    // deep copy
    char *domain_name = (char *)malloc(length + 1);
    memset(domain_name, 0, length + 1);
    strcpy(domain_name, domain_name_origin);
    
    uint8_t *domain_labels = NULL;
    uint8_t domain_labels_length = 0;
    
    char *str = (char *)&(*domain_name);
    char *p;
    
    p = strtok(str, ".");
    while (p) {
        uint8_t *label = NULL;
        uint8_t length = compress_label(p, strlen(p), &label);
        
        if (domain_labels == NULL) {
            domain_labels = label;
            domain_labels_length = length;
            p = strtok(NULL, ".");
            continue;
        }
        uint8_t *tmp = (uint8_t *)malloc(domain_labels_length + length + 1);
        uint8_t *ptr = tmp;
        memset(tmp, 0, domain_labels_length + length + 1);
        memcpy(tmp, domain_labels, domain_labels_length);
        ptr+=domain_labels_length;
        memcpy(ptr, label, length);
        domain_labels = tmp;
        domain_labels_length += length;

        
        p = strtok(NULL, ".");
    }
    
    // append .
    domain_labels_length += 1;
    *compresslabel = domain_labels;
    
    return domain_labels_length;
    
}

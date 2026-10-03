#ifndef OC_SHIM_H
#define OC_SHIM_H

#include <openconnect.h>

/// Swift cannot supply the variadic `progress` callback libopenconnect wants, so this formats the message
/// in C and hands Swift a plain string. One tunnel session runs at a time, so the sink is process-wide.
typedef void (*oc_shim_log_fn)(int level, const char *message);

void oc_shim_set_log(oc_shim_log_fn log);

struct openconnect_info *oc_shim_vpninfo_new(const char *useragent,
                                             openconnect_validate_peer_cert_vfn validate,
                                             openconnect_write_new_config_vfn write_config,
                                             openconnect_process_auth_form_vfn process_form,
                                             void *privdata);

#endif

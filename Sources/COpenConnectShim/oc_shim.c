#include "oc_shim.h"
#include <stdarg.h>
#include <stdio.h>

static oc_shim_log_fn g_log = NULL;

void oc_shim_set_log(oc_shim_log_fn log) {
    g_log = log;
}

static void oc_shim_progress(void *privdata, int level, const char *fmt, ...) {
    (void)privdata;
    if (!g_log) return;
    char buffer[1024];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);
    g_log(level, buffer);
}

struct openconnect_info *oc_shim_vpninfo_new(const char *useragent,
                                             openconnect_validate_peer_cert_vfn validate,
                                             openconnect_write_new_config_vfn write_config,
                                             openconnect_process_auth_form_vfn process_form,
                                             void *privdata) {
    return openconnect_vpninfo_new(useragent, validate, write_config, process_form, oc_shim_progress, privdata);
}

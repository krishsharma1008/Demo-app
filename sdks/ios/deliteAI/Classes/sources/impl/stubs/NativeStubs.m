/*
 * NativeStubs.m
 * Temporary placeholder implementations to satisfy linker while full native library is unavailable.
 * These functions perform no-ops or return default values.
 * Once real C/C++ runtime is integrated these stubs must be removed.
 */

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

// --- Global function pointers expected by bridge (defined weakly) ---
char * (*get_hardware_info_global)(void) = NULL;
char * (*get_phonemes_global)(const char *) = NULL;
bool (*set_thread_priority_max_global)(void) = NULL;
bool (*set_thread_priority_min_global)(void) = NULL;
bool (*log_verbose_global)(const char*) = NULL;
bool (*log_debug_global)(const char*) = NULL;
bool (*log_info_global)(const char*) = NULL;
bool (*log_warn_global)(const char*) = NULL;
bool (*log_error_global)(const char*) = NULL;
bool (*log_fatal_global)(const char*) = NULL;
@class CNetworkResponse;
CNetworkResponse* (*send_request_global)(const char*, const char*, const char*, const char*, int) = NULL;

// --- JSON allocator / manipulation stubs ---
void *create_json_allocator(void) { return NULL; }
void deallocate_json_allocator(void *alloc) { (void)alloc; }

void *create_json_object(void *alloc) { (void)alloc; return NULL; }
void *create_json_array(void *alloc) { (void)alloc; return NULL; }
void *create_json_iterator(void *json) { (void)json; return NULL; }
void *get_next_json_element(void *iter) { (void)iter; return NULL; }

void add_bool_value(const char *key, bool value, void *json) { (void)key; (void)value; (void)json; }
void add_double_value(const char *key, double value, void *json) { (void)key; (void)value; (void)json; }
void add_int64_value(const char *key, long long value, void *json) { (void)key; (void)value; (void)json; }
void add_string_value(const char *key, const char *value, void *json) { (void)key; (void)value; (void)json; }
void add_null_value(const char *key, void *json) { (void)key; (void)json; }
void add_json_object_to_json(const char *key, void *child, void *parent) {
    (void)key; (void)child; (void)parent;
}

void move_bool_value_to_array(bool value, void *jsonArray) { (void)value; (void)jsonArray; }
void move_double_value_to_array(double value, void *jsonArray) { (void)value; (void)jsonArray; }
void move_int64_value_to_array(long long value, void *jsonArray) { (void)value; (void)jsonArray; }
void move_json_object_or_array_to_array(void *child, void *jsonArray) { (void)child; (void)jsonArray; }
void move_string_value_to_array(const char *value, void *jsonArray) { (void)value; (void)jsonArray; }
void move_null_value_to_array(void *jsonArray) { (void)jsonArray; }

// Output memory stub
void deallocate_output_memory2(void *ptr) { free(ptr); }

// --- NimbleNet engine stubs ---
int initialize_nimblenet(const char *config_json) {
    (void)config_json; return 0; // success
}
int load_modules(const char *assets_json) {
    (void)assets_json; return 0;
}
int is_ready(void) { return 1; }
int internet_switched_on(void) { return 1; }

int add_event(const char *event_json, const char *event_type) {
    (void)event_json; (void)event_type; return 0;
}
int delete_database(void) { return 0; }

int reset(void){ return 0; }
int run_method(const char *method_name, void *inputs_json, void *output_json){ (void)method_name; (void)inputs_json; (void)output_json; return 0; }
void send_crash_log(const char *log){ (void)log; }

int update_session(const char* session_json){ (void)session_json; return 0; }
int write_metric(const char* metric_json){ (void)metric_json; return 0; }
int write_run_method_metric(const char* metric_json, long long total_time){ (void)metric_json; (void)total_time; return 0; }

#ifdef __cplusplus
}
#endif

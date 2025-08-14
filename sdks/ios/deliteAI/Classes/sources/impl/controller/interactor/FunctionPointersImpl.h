/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef FunctionPointersImpl_h
#define FunctionPointersImpl_h

#import "executor_structs.h"
// #import "nimble_net_util.hpp" // C++ header not accessible to Swift - using local definitions

// Essential type definitions for basic functionality
// Forward declaration for Swift @objc class - will be defined in generated header
@class CNetworkResponse;
@class FileDownloadInfo;

// IosObject struct definition (matches the expected C++ structure)
typedef struct {
    void* obj;
    int type;
} IosObject;

// Essential enum constants for data types (from DATATYPE enum in nimble_net_util.hpp)
#define JSON 670
#define JSON_ARRAY 681
#define STRING 8
#define INT32 6
#define BOOLEAN 9
#define FLOAT 1
#define DOUBLE 11
#define INT64 7
#define FE_OBJ 700
#define NONE 667
#define UNKNOWN 0
#define IOS_MAP 701
#define IOS_ARRAY 702
#define IOS_PROTO_OBJECT 703
#define IOS_ANY_OBJECT 704

// Metric type constants
#define INTERNALSTORAGEMETRICS 1001
#define STATICDEVICEMETRICS 1002

// Global function pointer declarations
extern CNetworkResponse* (*send_request_global)(const char*, const char*, const char*, const char*, int);
extern char* (*get_hardware_info_global)(void);
extern void (*log_verbose_global)(const char*);
extern void (*log_debug_global)(const char*);
extern void (*log_info_global)(const char*);
extern void (*log_warn_global)(const char*);
extern void (*log_error_global)(const char*);
extern void (*log_fatal_global)(const char*);
// extern FileDownloadInfo* (*download_model_global)(const char*, const char*, const char*, const char*); // Disabled pending full implementation
extern bool (*set_thread_priority_max_global)(void);
extern bool (*set_thread_priority_min_global)(void);
extern char* (*get_phonemes_global)(const char*);
extern IosObject* (*get_ios_object_string_subscript_global)(IosObject*, const char*);
extern IosObject* (*get_ios_object_int_subscript_global)(IosObject*, int);
extern void (*deallocate_ios_nimblenet_status_global)(IosObject*);
extern void (*deallocate_frontend_ctensor_global)(IosObject*);
extern int (*get_ios_object_size_global)(IosObject*);
extern void (*set_ios_object_string_subscript_global)(IosObject*, const char*, IosObject*);
extern void (*set_ios_object_int_subscript_global)(IosObject*, int, IosObject*);
extern char* (*ios_object_to_string_global)(IosObject*);
extern IosObject* (*ios_object_arrange_global)(IosObject*, const char*);
extern bool (*in_ios_object_global)(const char*, IosObject*);
extern void (*release_ios_object_global)(IosObject*);
// extern void (*get_keys_ios_object_global)(IosObject*); // disabled

void initClientFunctionPointers(void);
CNetworkResponse* send_request_interop(const char *body, const char *headers, const char *url,
                                       const char *method, int length);
char *get_hardware_info_interop(void);
void log_debug_interop(const char *message);
void log_info_interop(const char *message);
void log_warn_interop(const char *message);
void log_error_interop(const char *message);
void log_fatal_interop(const char *message);
// FileDownloadInfo* download_model_interop(const char *url, const char *headers, const char *fileName, const char *tagDir); // Disabled
bool set_thread_priority_min_interop();
bool set_thread_priority_max_interop();

char *get_phonemes_interop(const char *text);

NimbleNetStatus* get_ios_object_string_subscript(IosObject proto, const char* key, CTensor* child);
NimbleNetStatus* get_ios_object_int_subscript(IosObject proto, int key, CTensor* child);
void deallocate_ios_nimblenet_status(NimbleNetStatus* status);
void deallocate_frontend_ctensor(CTensor* ctensor);
NimbleNetStatus* get_ios_object_size(IosObject proto, int* val);
NimbleNetStatus* createNimbleNetStatus(NSString *message);
NimbleNetStatus* set_ios_object_string_subscript(IosObject proto, const char* key, CTensor* value);
NimbleNetStatus* set_ios_object_int_subscript(IosObject proto, int key, CTensor* value);
NimbleNetStatus* ios_object_to_string(IosObject obj, char** str);
NimbleNetStatus* ios_object_arrange(IosObject obj, const int* indices,int numIndices, IosObject* newObj);
NimbleNetStatus* in_ios_object(IosObject obj, const char* key, bool* result);
NimbleNetStatus* release_ios_object(IosObject obj);
NimbleNetStatus* get_keys_ios_object(IosObject obj, CTensor* result);

#endif /* FunctionPointersImpl_h */

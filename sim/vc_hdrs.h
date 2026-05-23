#ifndef _VC_HDRS_H
#define _VC_HDRS_H

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdio.h>
#include <dlfcn.h>
#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef _VC_TYPES_
#define _VC_TYPES_
/* common definitions shared with DirectC.h */

typedef unsigned int U;
typedef unsigned char UB;
typedef unsigned char scalar;
typedef struct { U c; U d;} vec32;

#define scalar_0 0
#define scalar_1 1
#define scalar_z 2
#define scalar_x 3

extern long long int ConvUP2LLI(U* a);
extern void ConvLLI2UP(long long int a1, U* a2);
extern long long int GetLLIresult();
extern void StoreLLIresult(const unsigned int* data);
typedef struct VeriC_Descriptor *vc_handle;

#ifndef SV_3_COMPATIBILITY
#define SV_STRING const char*
#else
#define SV_STRING char*
#endif

#endif /* _VC_TYPES_ */


 extern int vc_uvmOnewayHash(/* INPUT */const char* string_in, /* INPUT */int seed);

 extern int vc_uvmCreateRandomSeed(/* INPUT */const char* string_in, /* INPUT */int seed);

 extern void vc_uvmReseed();

 extern int uvm_hdl_check_path(/* INPUT */const char* path);

 extern int uvm_hdl_deposit(/* INPUT */const char* path, const /* INPUT */svLogicVecVal *value);

 extern int uvm_hdl_force(/* INPUT */const char* path, const /* INPUT */svLogicVecVal *value);

 extern int uvm_hdl_release_and_read(/* INPUT */const char* path, /* INOUT */svLogicVecVal *value);

 extern int uvm_hdl_release(/* INPUT */const char* path);

 extern int uvm_hdl_read(/* INPUT */const char* path, /* OUTPUT */svLogicVecVal *value);

 extern SV_STRING uvm_hdl_read_string(/* INPUT */const char* path);

 extern int uvm_memory_load(/* INPUT */const char* nid, /* INPUT */const char* scope, /* INPUT */const char* fileName, /* INPUT */const char* radix, /* INPUT */const char* startaddr, /* INPUT */const char* endaddr, /* INPUT */const char* types);

 extern SV_STRING uvm_dpi_get_next_arg_c();

 extern SV_STRING uvm_dpi_get_tool_name_c();

 extern SV_STRING uvm_dpi_get_tool_version_c();

 extern void* uvm_dpi_regcomp(/* INPUT */const char* regex);

 extern int uvm_dpi_regexec(/* INPUT */void* preg, /* INPUT */const char* str);

 extern void uvm_dpi_regfree(/* INPUT */void* preg);

 extern int uvm_re_match(/* INPUT */const char* re, /* INPUT */const char* str);

 extern void uvm_dump_re_cache();

 extern SV_STRING uvm_glob_to_re(/* INPUT */const char* glob);

 extern void dpi_f32_add(/* INPUT */int a, /* INPUT */int b, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f32_sub(/* INPUT */int a, /* INPUT */int b, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f32_mul(/* INPUT */int a, /* INPUT */int b, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f32_div(/* INPUT */int a, /* INPUT */int b, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f64_add(/* INPUT */long long a, /* INPUT */long long b, /* INPUT */char rm, /* OUTPUT */long long *res, /* OUTPUT */char *fflags);

 extern void dpi_f64_sub(/* INPUT */long long a, /* INPUT */long long b, /* INPUT */char rm, /* OUTPUT */long long *res, /* OUTPUT */char *fflags);

 extern void dpi_f64_mul(/* INPUT */long long a, /* INPUT */long long b, /* INPUT */char rm, /* OUTPUT */long long *res, /* OUTPUT */char *fflags);

 extern void dpi_f64_div(/* INPUT */long long a, /* INPUT */long long b, /* INPUT */char rm, /* OUTPUT */long long *res, /* OUTPUT */char *fflags);

 extern void dpi_f32_mulAdd(/* INPUT */int a, /* INPUT */int b, /* INPUT */int c, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f64_mulAdd(/* INPUT */long long a, /* INPUT */long long b, /* INPUT */long long c, /* INPUT */char rm, /* OUTPUT */long long *res, /* OUTPUT */char *fflags);

 extern void dpi_f32_sqrt(/* INPUT */int a, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f64_sqrt(/* INPUT */long long a, /* INPUT */char rm, /* OUTPUT */long long *res, /* OUTPUT */char *fflags);

 extern void dpi_f64_to_f32(/* INPUT */long long a, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f32_to_f64(/* INPUT */int a, /* INPUT */char rm, /* OUTPUT */long long *res, /* OUTPUT */char *fflags);

 extern void dpi_i32_to_f32(/* INPUT */int a, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_ui32_to_f32(/* INPUT */int a, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_i32_to_f64(/* INPUT */int a, /* INPUT */char rm, /* OUTPUT */long long *res, /* OUTPUT */char *fflags);

 extern void dpi_ui32_to_f64(/* INPUT */int a, /* INPUT */char rm, /* OUTPUT */long long *res, /* OUTPUT */char *fflags);

 extern void dpi_f32_to_i32(/* INPUT */int a, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f32_to_ui32(/* INPUT */int a, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f64_to_i32(/* INPUT */long long a, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);

 extern void dpi_f64_to_ui32(/* INPUT */long long a, /* INPUT */char rm, /* OUTPUT */int *res, /* OUTPUT */char *fflags);
void SdisableFork();

#ifdef __cplusplus
}
#endif


#endif //#ifndef _VC_HDRS_H


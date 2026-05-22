#include "softfloat.h"
#include <stdint.h>
#include <stdbool.h>

static uint_fast8_t get_softfloat_rm(uint8_t rm) {
    switch(rm) {
        case 0: return softfloat_round_near_even;
        case 1: return softfloat_round_minMag;
        case 2: return softfloat_round_min;
        case 3: return softfloat_round_max;
        case 4: return softfloat_round_near_maxMag;
        default: return softfloat_round_near_even;
    }
}

static void set_rm(uint8_t rm) {
    softfloat_roundingMode = get_softfloat_rm(rm);
    softfloat_exceptionFlags = 0;
}

void dpi_f32_add(uint32_t a, uint32_t b, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fa = {a}, fb = {b};
    float32_t fres = f32_add(fa, fb);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f32_sub(uint32_t a, uint32_t b, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fa = {a}, fb = {b};
    float32_t fres = f32_sub(fa, fb);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f32_mul(uint32_t a, uint32_t b, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fa = {a}, fb = {b};
    float32_t fres = f32_mul(fa, fb);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f32_div(uint32_t a, uint32_t b, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fa = {a}, fb = {b};
    float32_t fres = f32_div(fa, fb);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f64_add(uint64_t a, uint64_t b, uint8_t rm, uint64_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fa = {a}, fb = {b};
    float64_t fres = f64_add(fa, fb);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f64_sub(uint64_t a, uint64_t b, uint8_t rm, uint64_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fa = {a}, fb = {b};
    float64_t fres = f64_sub(fa, fb);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f64_mul(uint64_t a, uint64_t b, uint8_t rm, uint64_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fa = {a}, fb = {b};
    float64_t fres = f64_mul(fa, fb);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f64_div(uint64_t a, uint64_t b, uint8_t rm, uint64_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fa = {a}, fb = {b};
    float64_t fres = f64_div(fa, fb);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f32_mulAdd(uint32_t a, uint32_t b, uint32_t c, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fa = {a}, fb = {b}, fc = {c};
    float32_t fres = f32_mulAdd(fa, fb, fc);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f64_mulAdd(uint64_t a, uint64_t b, uint64_t c, uint8_t rm, uint64_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fa = {a}, fb = {b}, fc = {c};
    float64_t fres = f64_mulAdd(fa, fb, fc);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f32_sqrt(uint32_t a, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fa = {a};
    float32_t fres = f32_sqrt(fa);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f64_sqrt(uint64_t a, uint8_t rm, uint64_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fa = {a};
    float64_t fres = f64_sqrt(fa);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f64_to_f32(uint64_t a, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fa = {a};
    float32_t fres = f64_to_f32(fa);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f32_to_f64(uint32_t a, uint8_t rm, uint64_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fa = {a};
    float64_t fres = f32_to_f64(fa);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_i32_to_f32(int32_t a, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fres = i32_to_f32(a);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_ui32_to_f32(uint32_t a, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fres = ui32_to_f32(a);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_i32_to_f64(int32_t a, uint8_t rm, uint64_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fres = i32_to_f64(a);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_ui32_to_f64(uint32_t a, uint8_t rm, uint64_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fres = ui32_to_f64(a);
    *res = fres.v;
    *fflags = softfloat_exceptionFlags;
}

void dpi_f32_to_i32(uint32_t a, uint8_t rm, int32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fa = {a};
    *res = (int32_t)f32_to_i32(fa, get_softfloat_rm(rm), true);
    *fflags = softfloat_exceptionFlags;
}

void dpi_f32_to_ui32(uint32_t a, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float32_t fa = {a};
    *res = (uint32_t)f32_to_ui32(fa, get_softfloat_rm(rm), true);
    *fflags = softfloat_exceptionFlags;
}

void dpi_f64_to_i32(uint64_t a, uint8_t rm, int32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fa = {a};
    *res = (int32_t)f64_to_i32(fa, get_softfloat_rm(rm), true);
    *fflags = softfloat_exceptionFlags;
}

void dpi_f64_to_ui32(uint64_t a, uint8_t rm, uint32_t* res, uint8_t* fflags) {
    set_rm(rm);
    float64_t fa = {a};
    *res = (uint32_t)f64_to_ui32(fa, get_softfloat_rm(rm), true);
    *fflags = softfloat_exceptionFlags;
}

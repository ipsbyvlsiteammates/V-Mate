#include "riscv_test.h"
RVTEST_RV32U
RVTEST_CODE_BEGIN
  la t0, fp_data
  flw f0, 0(t0)
  fld f1, 8(t0)
  fadd.s f2, f0, f0
  fadd.d f3, f1, f1
  fmul.s f4, f0, f2
  fmul.d f5, f1, f3
  j pass
fail:
  RVTEST_FAIL
pass:
  RVTEST_PASS
RVTEST_CODE_END
RVTEST_DATA_BEGIN
fp_data:
  .word 0x3f800000
  .word 0x00000000
  .dword 0x3ff0000000000000
RVTEST_DATA_END

#include "riscv_test.h"
RVTEST_RV32U
RVTEST_CODE_BEGIN
  la t0, subnormal_data
  flw f0, 0(t0)
  flw f1, 4(t0)
  flw f2, 8(t0)
  fmadd.s f3, f0, f1, f2
  j pass
fail:
  RVTEST_FAIL
pass:
  RVTEST_PASS
RVTEST_CODE_END
RVTEST_DATA_BEGIN
subnormal_data:
  .word 0x00000001
  .word 0x00000001
  .word 0x00000001
RVTEST_DATA_END

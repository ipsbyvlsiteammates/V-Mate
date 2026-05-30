#include "riscv_test.h"
RVTEST_RV32U
RVTEST_CODE_BEGIN
  li t0, 0
  csrw fcsr, t0
  fcvt.s.w f0, x0
  fcvt.s.w f1, x0
  fadd.s f2, f0, f1
  li t0, 1
  csrw fcsr, t0
  fadd.s f3, f0, f1
  csrr t0, fcsr
  li t1, 1
  bne t0, t1, fail
  j pass
fail:
  RVTEST_FAIL
pass:
  RVTEST_PASS
RVTEST_CODE_END
RVTEST_DATA_BEGIN
RVTEST_DATA_END

#include "riscv_test.h"
RVTEST_RV32U
RVTEST_CODE_BEGIN
  fcvt.s.w f0, x0
  fcvt.s.w f1, x0
  fdiv.s f2, f0, f1
  fdiv.s f3, f0, f1
  fdiv.s f4, f0, f1
  fdiv.s f5, f0, f1
  fdiv.s f6, f0, f1
  fdiv.s f7, f0, f1
  fdiv.s f8, f0, f1
  fdiv.s f9, f0, f1
  ecall
  j pass
fail:
  RVTEST_FAIL
pass:
  RVTEST_PASS
RVTEST_CODE_END
RVTEST_DATA_BEGIN
RVTEST_DATA_END

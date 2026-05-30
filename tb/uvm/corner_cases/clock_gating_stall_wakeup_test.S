#include "riscv_test.h"
RVTEST_RV32U
RVTEST_CODE_BEGIN
  wfi
  la t0, wake_data
  lw t1, 0(t0)
  add t2, t1, t1
  j pass
fail:
  RVTEST_FAIL
pass:
  RVTEST_PASS
RVTEST_CODE_END
RVTEST_DATA_BEGIN
wake_data:
  .word 0x12345678
RVTEST_DATA_END

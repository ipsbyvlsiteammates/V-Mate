#include "riscv_test.h"
RVTEST_RV32U
RVTEST_CODE_BEGIN
  la t0, test_data
  lw t1, 0(t0)
  li t2, 1
  beq t1, t2, mispredict_target
  sw t1, 4(t0)
  lw t3, 4(t0)
  bne t1, t3, fail
  j pass
mispredict_target:
  j fail
fail:
  RVTEST_FAIL
pass:
  RVTEST_PASS
RVTEST_CODE_END
RVTEST_DATA_BEGIN
test_data:
  .word 0x0
  .word 0x0
RVTEST_DATA_END

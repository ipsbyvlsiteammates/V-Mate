#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

  li x1, 1
  li x2, 2
  add x3, x1, x2

  RVTEST_PASS

RVTEST_CODE_END

RVTEST_DATA_BEGIN
.align 4
RVTEST_DATA_END

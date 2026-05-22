// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

void  schedNewEvent (struct dummyq_struct * I1489, EBLK  * I1193, U  I621);
void  schedNewEvent (struct dummyq_struct * I1489, EBLK  * I1193, U  I621)
{
    U  I1779;
    U  I1780;
    U  I1781;
    struct futq * I1782;
    struct dummyq_struct * pQ = I1489;
    I1779 = ((U )vcs_clocks) + I621;
    I1781 = I1779 & ((1 << fHashTableSize) - 1);
    I1193->I667 = (EBLK  *)(-1);
    I1193->I668 = I1779;
    if (0 && rmaProfEvtProp) {
        vcs_simpSetEBlkEvtID(I1193);
    }
    if (I1779 < (U )vcs_clocks) {
        I1780 = ((U  *)&vcs_clocks)[1];
        sched_millenium(pQ, I1193, I1780 + 1, I1779);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I621 == 1)) {
        I1193->I670 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I667 = I1193;
        peblkFutQ1Tail = I1193;
    }
    else if ((I1782 = pQ->I1387[I1781].I691)) {
        I1193->I670 = (struct eblk *)I1782->I689;
        I1782->I689->I667 = (RP )I1193;
        I1782->I689 = (RmaEblk  *)I1193;
    }
    else {
        sched_hsopt(pQ, I1193, I1779);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif

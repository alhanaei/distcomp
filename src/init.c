/*
** This file causes the entry points of my .C routines to be preloaded
** Added at the request of R-core.
** It adds one more layer of protection by declaring the number of arguments,
**  and perhaps a tiny bit of speed
*/
#include "survS.h"
#include "R_ext/Rdynload.h"
#include "survproto.h"

static const R_CMethodDef Centries[] = {
    {"Ccoxmart",    (DL_FUNC) &coxmart,    8},
    {NULL, NULL, 0}
};

static const R_CallMethodDef Callentries[] = {
    {"Ccoxcount1",    (DL_FUNC) &coxcount1,    2},
    {"Ccoxcount2",    (DL_FUNC) &coxcount2,    4},
    {"Ccoxfit6",      (DL_FUNC) &coxfit6,     12},
    {NULL, NULL, 0}
};

void R_init_distcomp(DllInfo *dll){
    R_registerRoutines(dll, Centries, Callentries, NULL, NULL);

    /* My take on the documentation is that adding the following line
       will make symbols available ONLY through the above tables.
       Anyone who then tried to link to my C code would be SOL.
       It also wouldn't work with .C(routines[1], ....
    */
   /* R_useDynamicSymbols(dll, FALSE);  */
}


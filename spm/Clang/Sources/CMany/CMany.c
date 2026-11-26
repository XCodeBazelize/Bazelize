#include "CMany.h"
#include "CManyExtra.h"

int many_total(void) {
    return many_value() + many_extra_value();
}

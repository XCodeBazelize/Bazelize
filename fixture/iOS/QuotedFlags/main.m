#import <Foundation/Foundation.h>
#import <string.h>

/// Only `HEADER_SEARCH_PATHS`, a quoted directory with a space in its name,
/// reaches this header.
#import "Spaced.h"

/// Defined here, called by the name `OTHER_LDFLAGS` gives it with `-alias`.
int quoted_flags_symbol(void) {
    return SPACED_HEADER_VALUE;
}

extern int quoted_flags_alias(void);

int main(void) {
    if (strcmp(QUOTED_MESSAGE, "two words") != 0
        || strcmp(OTHER_MESSAGE, "other words") != 0
        || quoted_flags_alias() != 41) {
        fprintf(stderr, "A quoted build setting did not arrive as one argument\n");
        return 1;
    }
    puts("Quoted header search path, definitions, and linker flags arrived whole");
    return 0;
}

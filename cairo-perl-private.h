/*
 * Copyright (c) 2004-2005 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Header: /cvs/cairo/cairo-perl/cairo-perl-private.h,v 1.3 2006/07/15 14:41:11 tsch Exp $
 *
 */

#ifndef _CAIRO_PERL_PRIVATE_H_
#define _CAIRO_PERL_PRIVATE_H_

void cair_perl_set_isa (const char * child_package, const char * parent_package);

cairo_matrix_t * cairo_perl_copy_matrix (cairo_matrix_t *matrix);

#endif /* _CAIRO_PERL_PRIVATE_H_ */

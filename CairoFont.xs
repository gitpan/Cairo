/*
 * Copyright (c) 2004-2005 by the cairo perl team (see the file README)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Header: /cvs/cairo/cairo-perl/CairoFont.xs,v 1.4 2005/07/29 17:19:55 tsch Exp $
 */

#include <cairo-perl.h>

MODULE = Cairo::Font	PACKAGE = Cairo::FontFace	PREFIX = cairo_font_face_

cairo_status_t cairo_font_face_status (cairo_font_face_t * font);

void DESTROY (cairo_font_face_t * font)
    CODE:
	cairo_font_face_destroy (font);

MODULE = Cairo::Font	PACKAGE = Cairo::ScaledFont	PREFIX = cairo_scaled_font_

##cairo_scaled_font_t* cairo_scaled_font_create (cairo_font_face_t *font_face, const cairo_matrix_t *font_matrix, const cairo_matrix_t *ctm, const cairo_font_options_t *options);
cairo_scaled_font_t_noinc * cairo_scaled_font_create (class, cairo_font_face_t *font_face, const cairo_matrix_t *font_matrix, const cairo_matrix_t *ctm, const cairo_font_options_t *options)
    C_ARGS:
	font_face, font_matrix, ctm, options

cairo_status_t cairo_scaled_font_status (cairo_scaled_font_t *scaled_font);

##cairo_status_t cairo_scaled_font_extents (cairo_scaled_font_t *scaled_font, cairo_font_extents_t *extents);
cairo_font_extents_t * cairo_scaled_font_extents (cairo_scaled_font_t *scaled_font)
    PREINIT:
	cairo_font_extents_t extents;
    CODE:
	cairo_scaled_font_extents (scaled_font, &extents);
	RETVAL = &extents;
    OUTPUT:
	RETVAL

##void cairo_scaled_font_glyph_extents (cairo_scaled_font_t *scaled_font, cairo_glyph_t *glyphs, int num_glyphs, cairo_text_extents_t *extents);
cairo_text_extents_t * cairo_scaled_font_glyph_extents (cairo_scaled_font_t *scaled_font, ...)
    PREINIT:
	cairo_glyph_t * glyphs = NULL;
	int num_glyphs, i;
	cairo_text_extents_t extents;
    CODE:
	num_glyphs = items - 1;
	glyphs = calloc (sizeof (cairo_glyph_t), num_glyphs);
	for (i = 1; i < items; i++)
		glyphs[i - 1] = *SvCairoGlyph (ST (i));
	cairo_scaled_font_glyph_extents (scaled_font, glyphs, num_glyphs, &extents);
	RETVAL = &extents;
	free (glyphs);
    OUTPUT:
	RETVAL

void DESTROY (cairo_scaled_font_t * font)
    CODE:
	cairo_scaled_font_destroy (font);

MODULE = Cairo::Font	PACKAGE = Cairo::FontOptions	PREFIX = cairo_font_options_

##cairo_font_options_t * cairo_font_options_create (void);
cairo_font_options_t * cairo_font_options_create (class)
    C_ARGS:
	/* void */

# FIXME: Necessary?
##cairo_font_options_t * cairo_font_options_copy (const cairo_font_options_t *original);

cairo_status_t cairo_font_options_status (cairo_font_options_t *options);

void cairo_font_options_merge (cairo_font_options_t *options, const cairo_font_options_t *other);

cairo_bool_t cairo_font_options_equal (const cairo_font_options_t *options, const cairo_font_options_t *other);

unsigned long cairo_font_options_hash (const cairo_font_options_t *options);

void cairo_font_options_set_antialias (cairo_font_options_t *options, cairo_antialias_t antialias);

cairo_antialias_t cairo_font_options_get_antialias (const cairo_font_options_t *options);

void cairo_font_options_set_subpixel_order (cairo_font_options_t *options, cairo_subpixel_order_t subpixel_order);

cairo_subpixel_order_t cairo_font_options_get_subpixel_order (const cairo_font_options_t *options);

void cairo_font_options_set_hint_style (cairo_font_options_t *options, cairo_hint_style_t hint_style);

cairo_hint_style_t cairo_font_options_get_hint_style (const cairo_font_options_t *options);

void cairo_font_options_set_hint_metrics (cairo_font_options_t *options, cairo_hint_metrics_t hint_metrics);

cairo_hint_metrics_t cairo_font_options_get_hint_metrics (const cairo_font_options_t *options);

void DESTROY (cairo_font_options_t *options)
    CODE:
	cairo_font_options_destroy (options);

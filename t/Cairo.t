#
# Copyright (c) 2004-2005 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#
# $Header: /cvs/cairo/cairo-perl/t/Cairo.t,v 1.8 2006/06/03 14:21:10 tsch Exp $
#

use strict;
use warnings;

use Test::More tests => 56;

use constant {
	IMG_WIDTH => 256,
	IMG_HEIGHT => 256,
};

BEGIN {
	use_ok ('Cairo');
}

ok(defined Cairo::version);
ok(defined Cairo::version_string);

ok(defined Cairo->version);
ok(defined Cairo->version_string);

my $surf = Cairo::ImageSurface->create ('rgb24', IMG_WIDTH, IMG_HEIGHT);
isa_ok ($surf, 'Cairo::Surface');

my $cr = Cairo::Context->create ($surf);
isa_ok ($cr, 'Cairo::Context');

$cr->save;
$cr->restore;

$cr->push_group();
isa_ok ($cr->get_group_target, 'Cairo::Surface');
isa_ok ($cr->pop_group(), 'Cairo::Pattern');

$cr->push_group_with_content('color');
$cr->pop_group_to_source();

$cr->set_operator ('clear');
is ($cr->get_operator, 'clear');

$cr->set_source_rgb (0.5, 0.6, 0.7);
$cr->set_source_rgba (0.5, 0.6, 0.7, 0.8);

my $pat = Cairo::SurfacePattern->create ($surf);

$cr->set_source ($pat);
$cr->set_source_surface ($surf, 23, 42);

$cr->set_tolerance (0.75);
is ($cr->get_tolerance, 0.75);

$cr->set_antialias ('subpixel');
is ($cr->get_antialias, 'subpixel');

$cr->set_fill_rule ('winding');
is ($cr->get_fill_rule, 'winding');

$cr->set_line_width (3);
is ($cr->get_line_width, 3);

$cr->set_line_cap ('butt');
is ($cr->get_line_cap, 'butt');

$cr->set_line_join ('miter');
is ($cr->get_line_join, 'miter');

$cr->set_dash (0, 2, 4, 6, 4, 2);

$cr->set_miter_limit (2.2);
is ($cr->get_miter_limit, 2.2);

$cr->translate (2.2, 3.3);
$cr->scale (2.2, 3.3);
$cr->rotate (2.2);

my $mat = Cairo::Matrix->init_identity;
isa_ok ($mat, 'Cairo::Matrix');

$cr->set_matrix ($mat);
isa_ok ($cr->get_matrix, 'Cairo::Matrix');

$cr->transform ($mat);
$cr->identity_matrix;

is_deeply ([$cr->user_to_device (23, 42)], [23, 42]);
is_deeply ([$cr->user_to_device_distance (1, 2)], [1, 2]);
is_deeply ([$cr->device_to_user (23, 42)], [23, 42]);
is_deeply ([$cr->device_to_user_distance (1, 2)], [1, 2]);

$cr->new_path;
$cr->new_sub_path;
$cr->move_to (1.1, 2.2);
$cr->line_to (2.2, 3.3);
$cr->curve_to (3.3, 4.4, 5.5, 6.6, 7.7, 8.8);
$cr->arc (4.4, 5.5, 6.6, 7.7, 8.8);
$cr->arc_negative (5.5, 6.6, 7.7, 8.8, 9.9);
$cr->rel_move_to (6.6, 7.7);
$cr->rel_line_to (8.8, 9.9);
$cr->rel_curve_to (9.9, 0.0, 1.1, 2.2, 3.3, 4.4);
$cr->rectangle (0.0, 1.1, 2.2, 3.3);
$cr->close_path;

$cr->paint;
$cr->paint_with_alpha (0.5);
$cr->mask ($pat);
$cr->mask_surface ($surf, 23, 42);
$cr->stroke;
$cr->stroke_preserve;
$cr->fill;
$cr->fill_preserve;
$cr->copy_page;
$cr->show_page;

ok (!$cr->in_stroke (23, 42));
ok (!$cr->in_fill (23, 42));

my @ext = $cr->stroke_extents;
is (@ext, 4);

@ext = $cr->fill_extents;
is (@ext, 4);

$cr->clip;
$cr->clip_preserve;
$cr->reset_clip;
$cr->select_font_face ('Sans', 'normal', 'normal');
$cr->set_font_size (12);

$cr->set_font_matrix ($mat);
isa_ok ($cr->get_font_matrix, 'Cairo::Matrix');

my $opt = Cairo::FontOptions->create;

$cr->set_font_options ($opt);
ok ($opt->equal ($cr->get_font_options));

my @glyphs = ({ index => 1, x => 2, y => 3 },
              { index => 2, x => 3, y => 4 },
              { index => 3, x => 4, y => 5 });

$cr->show_text ('Urgs?');
$cr->show_glyphs (@glyphs);

my $face = $cr->get_font_face;
isa_ok ($face, 'Cairo::FontFace');
$cr->set_font_face ($face);

my $ext = $cr->font_extents;
isa_ok ($ext, 'HASH');
ok (exists $ext->{'ascent'});
ok (exists $ext->{'descent'});
ok (exists $ext->{'height'});
ok (exists $ext->{'max_x_advance'});
ok (exists $ext->{'max_y_advance'});

foreach $ext ($cr->text_extents ('Urgs?'),
              $cr->glyph_extents (@glyphs)) {
	isa_ok ($ext, 'HASH');
	ok (exists $ext->{'x_bearing'});
	ok (exists $ext->{'y_bearing'});
	ok (exists $ext->{'width'});
	ok (exists $ext->{'height'});
	ok (exists $ext->{'x_advance'});
	ok (exists $ext->{'y_advance'});
}

$cr->text_path ('Urgs?');
$cr->glyph_path (@glyphs);

my $options = Cairo::FontOptions->create;
my $matrix = Cairo::Matrix->init_identity;
my $ctm = Cairo::Matrix->init_identity;
my $font = Cairo::ScaledFont->create ($face, $matrix, $ctm, $options);
$cr->set_scaled_font ($font);

isa_ok ($cr->get_source, 'Cairo::Pattern');

my @pnt = $cr->get_current_point;
is (@pnt, 2);

isa_ok ($cr->get_target, 'Cairo::Surface');

my $path = $cr->copy_path;
isa_ok ($path, 'ARRAY');

$path = $cr->copy_path_flat;
isa_ok ($path, 'ARRAY');

$cr->append_path ($path);

is ($cr->status, 'success');

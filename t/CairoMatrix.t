#
# Copyright (c) 2004-2005 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#
# $Header: /cvs/cairo/cairo-perl/t/CairoMatrix.t,v 1.3 2005/07/29 17:19:55 tsch Exp $
#

use strict;
use warnings;

use Test::More tests => 10;

use Cairo;

my $matrix = Cairo::Matrix->init (1, 2, 3, 4, 5, 6);
isa_ok ($matrix, 'Cairo::Matrix');

$matrix = Cairo::Matrix->init_identity;
isa_ok ($matrix, 'Cairo::Matrix');

$matrix = Cairo::Matrix->init_translate (1, 2);
isa_ok ($matrix, 'Cairo::Matrix');

$matrix = Cairo::Matrix->init_scale (3, 4);
isa_ok ($matrix, 'Cairo::Matrix');

$matrix = Cairo::Matrix->init_rotate (3.1415);
isa_ok ($matrix, 'Cairo::Matrix');

eval
{
	$matrix->translate (1, 2);
	$matrix->scale (3, 4);
	$matrix->rotate (3.1415);
};
is ($@, '', 'translate, scale, rotate');

is ($matrix->invert, 'success');

my $id = Cairo::Matrix->init_identity;

isa_ok ($matrix->multiply ($id), 'Cairo::Matrix');

is_deeply ([$id->transform_distance (1, 1)], [1, 1],
	   '$id->transform_distance');

is_deeply ([$id->transform_point (1, 1)], [1, 1],
	   '$id->transform_point');

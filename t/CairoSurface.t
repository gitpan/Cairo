#
# Copyright (c) 2004-2005 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#
# $Header: /cvs/cairo/cairo-perl/t/CairoSurface.t,v 1.17.2.2 2006/11/23 19:13:01 tsch Exp $
#

use strict;
use warnings;

use Test::More tests => 64;

use constant {
	IMG_WIDTH => 256,
	IMG_HEIGHT => 256,
};

use Cairo;

my $surf = Cairo::ImageSurface->create ('rgb24', IMG_WIDTH, IMG_HEIGHT);
isa_ok ($surf, 'Cairo::ImageSurface');
isa_ok ($surf, 'Cairo::Surface');

SKIP: {
	skip 'new stuff', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	is ($surf->get_content, 'color');
	is ($surf->get_format, 'rgb24');
}

is ($surf->get_width, IMG_WIDTH);
is ($surf->get_height, IMG_HEIGHT);

{
	my $data = pack ('CCCC', 0, 0, 0, 0);
	my $surf = Cairo::ImageSurface->create_for_data (
	             $data, 'argb32', 1, 1, 4);
	isa_ok ($surf, 'Cairo::ImageSurface');
	isa_ok ($surf, 'Cairo::Surface');

	SKIP: {
		skip 'new stuff', 4
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		is ($surf->get_data, $data);
		is ($surf->get_stride, 4);

		# Change the image data and make sure $data gets updated accordingly.
		my $cr = Cairo::Context->create ($surf);
		$cr->set_source_rgba (1.0, 0, 0, 1.0);
		$cr->rectangle (0, 0, 1, 1);
		$cr->fill;

		is ($surf->get_data, $data);
		is ($surf->get_data, pack ('CCCC', 0, 0, 255, 255));
	}
}

$surf = $surf->create_similar ('color', IMG_WIDTH, IMG_HEIGHT);
isa_ok ($surf, 'Cairo::ImageSurface');
isa_ok ($surf, 'Cairo::Surface');

# Test that the enum wrappers differentiate between color and color-alpha.
SKIP: {
	skip 'content tests', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	my $tmp = $surf->create_similar ('color-alpha', IMG_WIDTH, IMG_HEIGHT);
	is ($tmp->get_content, 'color-alpha');
	$tmp = $surf->create_similar ('color', IMG_WIDTH, IMG_HEIGHT);
	is ($tmp->get_content, 'color');
}

$surf->set_device_offset (23, 42);

SKIP: {
	skip 'new stuff', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	is_deeply ([$surf->get_device_offset], [23, 42]);

	$surf->set_fallback_resolution (72, 72);

	is ($surf->get_type, 'image');
}

is ($surf->status, 'success');

isa_ok ($surf->get_font_options, 'Cairo::FontOptions');

$surf->mark_dirty;
$surf->mark_dirty_rectangle (10, 10, 10, 10);
$surf->flush;

sub clear {
	if (Cairo::VERSION() < Cairo::VERSION_ENCODE (1, 2, 0)) {
		my $cr = Cairo::Context->create ($surf);
		$cr->set_operator ('clear');
		$cr->paint;
	}
}

SKIP: {
	skip 'png surface', 16
		unless Cairo::HAS_PNG_FUNCTIONS;

	my $surf = Cairo::ImageSurface->create ('rgb24', IMG_WIDTH, IMG_HEIGHT);
	clear ($surf);
	is ($surf->write_to_png ('tmp.png'), 'success');

	is ($surf->write_to_png_stream (sub {
		my ($closure, $data) = @_;
		is ($closure, 'blub');
		like ($data, qr/PNG/);
		die 'write-error';
	}, 'blub'), 'no-memory');

	is ($surf->write_to_png_stream (sub {
		my ($closure, $data) = @_;
		is ($closure, undef);
		like ($data, qr/PNG/);
		die 'write-error';
	}), 'no-memory');

	$surf = Cairo::ImageSurface->create_from_png ('tmp.png');
	isa_ok ($surf, 'Cairo::ImageSurface');
	isa_ok ($surf, 'Cairo::Surface');

	open my $fh, 'tmp.png';
	$surf = Cairo::ImageSurface->create_from_png_stream (sub {
		my ($closure, $length) = @_;
		my $buffer;

		if ($length != sysread ($fh, $buffer, $length)) {
			die 'no-memory';
		}

		return $buffer;
	});
	isa_ok ($surf, 'Cairo::ImageSurface');
	isa_ok ($surf, 'Cairo::Surface');
	is ($surf->status, 'success');
	close $fh;

	$surf = Cairo::ImageSurface->create_from_png_stream (sub {
		my ($closure, $length) = @_;
		is ($closure, 'blub');
		die 'read-error';
	}, 'blub');
	isa_ok ($surf, 'Cairo::ImageSurface');
	isa_ok ($surf, 'Cairo::Surface');
	is ($surf->status, 'read-error');

	unlink 'tmp.png';
}

SKIP: {
	skip 'pdf surface', 8
		unless Cairo::HAS_PDF_SURFACE;

	my $surf = Cairo::PdfSurface->create ('tmp.pdf', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::PdfSurface');
	isa_ok ($surf, 'Cairo::Surface');

	SKIP: {
		skip 'new stuff', 0
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		$surf->set_size (23, 42);
	}

	$surf = $surf->create_similar ('alpha', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::Surface');

	# create_similar actually returns an image surface at the moment, but
	# the compatibility layer has no way of knowing this and thus turns it
	# into a pdf surface.
	if (Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0)) {
		isa_ok ($surf, 'Cairo::ImageSurface');
	} else {
		isa_ok ($surf, 'Cairo::PdfSurface');
	}

	unlink 'tmp.pdf';

	SKIP: {
		skip 'create_for_stream on pdf surfaces', 4
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		$surf = Cairo::PdfSurface->create_for_stream (sub {
			my ($closure, $data) = @_;
			is ($closure, 'blub');
			like ($data, qr/PDF/);
			die 'write-error';
		}, 'blub', IMG_WIDTH, IMG_HEIGHT);
		isa_ok ($surf, 'Cairo::PdfSurface');
		isa_ok ($surf, 'Cairo::Surface');
	}
}

SKIP: {
	skip 'ps surface', 8
		unless Cairo::HAS_PS_SURFACE;

	my $surf = Cairo::PsSurface->create ('tmp.ps', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::PsSurface');
	isa_ok ($surf, 'Cairo::Surface');

	SKIP: {
		skip 'new stuff', 0
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		$surf->set_size (23, 42);

		$surf->dsc_comment("Bla?");
		$surf->dsc_begin_setup;
		$surf->dsc_begin_page_setup;
	}

	$surf = $surf->create_similar ('alpha', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::Surface');

	# create_similar actually returns an image surface at the moment, but
	# the compatibility layer has no way of knowing this and thus turns it
	# into a ps surface.
	if (Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0)) {
		isa_ok ($surf, 'Cairo::ImageSurface');
	} else {
		isa_ok ($surf, 'Cairo::PsSurface');
	}

	unlink 'tmp.ps';


	SKIP: {
		skip 'create_for_stream on ps surfaces', 4
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		$surf = Cairo::PsSurface->create_for_stream (sub {
			my ($closure, $data) = @_;
			is ($closure, 'blub');
			like ($data, qr/PS/);
			die 'write-error';
		}, 'blub', IMG_WIDTH, IMG_HEIGHT);
		isa_ok ($surf, 'Cairo::PsSurface');
		isa_ok ($surf, 'Cairo::Surface');
	}
}

SKIP: {
	skip 'svg surface', 12
		unless Cairo::HAS_SVG_SURFACE;

	my $surf = Cairo::SvgSurface->create ('tmp.svg', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::SvgSurface');
	isa_ok ($surf, 'Cairo::Surface');

	$surf->restrict_to_version ('1-1');
	$surf->restrict_to_version ('1-2');

	unlink 'tmp.svg';

	$surf = Cairo::SvgSurface->create_for_stream (sub {
		my ($closure, $data) = @_;
		is ($closure, 'blub');
		like ($data, qr/xml/);
		die 'write-error';
	}, 'blub', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::SvgSurface');
	isa_ok ($surf, 'Cairo::Surface');

	my @versions = Cairo::SvgSurface::get_versions();
	ok (scalar @versions > 0);
	is ($versions[0], '1-1');

	@versions = Cairo::SvgSurface->get_versions();
	ok (scalar @versions > 0);
	is ($versions[0], '1-1');

	like (Cairo::SvgSurface::version_to_string('1-1'), qr/1\.1/);
	like (Cairo::SvgSurface->version_to_string('1-1'), qr/1\.1/);
}

#
# this is all hacky etc. it works so it's gonna stay for now. it is not and
# should not be installed.
#
# $Id$
#

package MakeHelper;

use strict;
use warnings;
use IO::File;
use File::Spec;

our $autogen_dir = '.';

# --------------------------------------------------------------------------- #

# copied/borrowed from Gtk2-Perl's CodeGen
sub write_boot
{
	my %opts = (
		ignore => '^[^:]+$',	# ignore package with no colons in it
		filename => File::Spec->catdir ($autogen_dir,
						'cairo-perl-boot.xsh'),
		'glob' => File::Spec->catfile ('xs', '*.xs'),
		@_,
	);
	my $ignore = $opts{ignore};

	my $file = IO::File->new (">$opts{filename}")
		or die "Cannot write $opts{filename}: $!";

	print $file "\n\n/* This file is automatically generated, any changes made here will be lost! */\n\n";

	my %boot=();

	my @xs_files = 'ARRAY' eq ref $opts{xs_files}
	             ? @{ $opts{xs_files} }
	             : glob $opts{'glob'};

	foreach my $xsfile (@xs_files) {
		my $in = IO::File->new ($xsfile)
				or die "can't open $xsfile: $!\n";

		while (<$in>) {
			next unless m/^MODULE\s*=\s*(\S+)/;
			#warn "found $1 in $&\n";

			my $package = $1;

			next if $package =~ m/$ignore/;

			$package =~ s/:/_/g;
			my $sym = "boot_$package";
			print $file "CAIRO_PERL_CALL_BOOT ($sym);\n"
				unless $boot{$sym};
			$boot{$sym}++;
		}

		close $in;
	}

	close $file;
}

# --------------------------------------------------------------------------- #

sub do_typemaps
{
	my %objects = %{shift ()};
	my %structs = %{shift ()};
	my %enums = %{shift ()};
	my %backend_guards = %{shift ()};
	my %enum_guards = %{shift ()};

	my $cairo_perl = File::Spec->catfile ($autogen_dir,
					      'cairo-perl-auto.typemap');
	open TYPEMAP, '>', $cairo_perl
		or die "unable to open ($cairo_perl) for output";

	print TYPEMAP <<EOS;
#
# This file was automatically generated.  Do not edit.
#

TYPEMAP

EOS

	sub type_id
	{
		my $ret = shift;
		$ret =~ s/ \*//;
		uc ($ret);
	}

	sub func_name
	{
		$_[0] =~ /cairo_(\w+)_t/;
		$1;
	}

	foreach (keys %objects, keys %structs, keys %enums)
	{
		print TYPEMAP "$_\tT_CAIROPERL_GENERIC_WRAPPER\n";
	}

	foreach (keys %objects, keys %structs)
	{
		my $trunk = $_;
		$trunk =~ s/ \*//;

		print TYPEMAP "const $_\tT_CAIROPERL_GENERIC_WRAPPER\n";
		print TYPEMAP "${trunk}_ornull *\tT_CAIROPERL_GENERIC_WRAPPER\n";
		print TYPEMAP "const ${trunk}_ornull *\tT_CAIROPERL_GENERIC_WRAPPER\n";
	}

	foreach (keys %objects)
	{
		my $trunk = $_;
		$trunk =~ s/ \*//;

		print TYPEMAP "${trunk}_noinc *\tT_CAIROPERL_GENERIC_WRAPPER\n";
	}

	my $conversion_code = ';
	  (my $ntype = $type) =~ s/(?:const\s+)?([:\w]+)(?:\s*\*)$/$1/x;
	  my $result = $type;
	  if ($ntype =~ m/(.+)_t(_.+)?/) {
	    my ($name, $options) = ($1, $2);
	    $name =~ s/([^_]+)/ucfirst $1/ge;
	    $name =~ s/_//g;
	    $result = $name . $options;
	  }
	  \$result';

        print TYPEMAP <<"EOS";

INPUT

T_CAIROPERL_GENERIC_WRAPPER
	\$var = Sv\${$conversion_code} (\$arg);

OUTPUT

T_CAIROPERL_GENERIC_WRAPPER
	\$arg = newSV\${$conversion_code} (\$var);
EOS

	close TYPEMAP;

	# ------------------------------------------------------------------- #

	my $header = File::Spec->catfile ($autogen_dir,
					  'cairo-perl-auto.h');
	open HEADER, '>', $header
		or die "unable to open ($header) for output";

	print HEADER <<EOS;
/*
 * This file was automatically generated.  Do not edit.
 */

#include <cairo.h>
EOS

	sub mangle
	{
		my $mangled = shift;
		$mangled =~ s/_t$//;
		$mangled =~ s/([^_]+)/ucfirst $1/ge;
		$mangled =~ s/_//g;
		return $mangled;
	}

	sub reference
	{
		my $ref = shift;
		$ref =~ s/_t$//;
		$ref .= '_reference';
		return $ref;
	}

	sub name
	{
		$_[0] =~ /cairo_(\w+)_t/;
		return $1;
	}

	# ------------------------------------------------------------------- #

	print HEADER "\n/* objects */\n\n";

	foreach (keys %objects)
	{
		/^(.+) \*/;
		my $type = $1;
		my $mangled = mangle ($type);
		my $ref = reference ($type);

		if (exists $backend_guards{$type}) {
			print HEADER "#ifdef $backend_guards{$type}\n";
		}

		print HEADER <<"EOS";
typedef $type ${type}_noinc;
typedef $type ${type}_ornull;
#define Sv$mangled(sv)			(($type *) cairo_object_from_sv (sv, "$objects{$_}"))
#define Sv${mangled}_ornull(sv)		(((sv) && SvOK (sv)) ? Sv$mangled(sv) : NULL)
#define newSV$mangled(object)		(cairo_object_to_sv (($type *) $ref (object), "$objects{$_}"))
#define newSV${mangled}_noinc(object)	(cairo_object_to_sv (($type *) object, "$objects{$_}"))
#define newSV${mangled}_ornull(object)	(((object) == NULL) ? &PL_sv_undef : newSV$mangled(object))
EOS

		if (exists $backend_guards{$type}) {
			print HEADER "#endif /* $backend_guards{$type} */\n";
		}
	}

	# ------------------------------------------------------------------- #

	print HEADER "\n/* structs */\n\n";

	foreach (keys %structs)
	{
		/^(.+) \*/;
		my $type = $1;
		my $mangled = mangle ($type);

		print HEADER <<"EOS";
typedef $type ${type}_ornull;
#define Sv$mangled(sv)			(($type *) cairo_struct_from_sv (sv, "$structs{$_}"))
#define Sv${mangled}_ornull(sv)		(((sv) && SvOK (sv)) ? Sv$mangled(sv) : NULL)
#define newSV$mangled(struct)		(cairo_struct_to_sv (($type *) struct, "$structs{$_}"))
#define newSV${mangled}_ornull(struct)	(((struct) == NULL) ? &PL_sv_undef : newSV$mangled(struct))
EOS
	}

	# ------------------------------------------------------------------- #

	print HEADER "\n/* enums */\n\n";

	foreach my $type (keys %enums)
	{
		my $mangled = mangle ($type);
		my $name = name ($type);

		next unless @{$enums{$type}};

		if (exists $enum_guards{$type}) {
			print HEADER "#ifdef $enum_guards{$type}\n";
		}

		print HEADER <<"EOS";
$type cairo_${name}_from_sv (SV * $name);
SV * cairo_${name}_to_sv ($type val);
#define Sv$mangled(sv)		(cairo_${name}_from_sv (sv))
#define newSV$mangled(val)	(cairo_${name}_to_sv (val))
EOS

		if (exists $enum_guards{$type}) {
			print HEADER "#endif /* $enum_guards{$type} */\n";
		}
	}

	close HEADER;

	return ($cairo_perl);
}

# --------------------------------------------------------------------------- #

sub do_enums
{
	my %enums = %{shift ()};
        my %guards = %{shift ()};

	my $cairo_enums = 'cairo-perl-enums.c';
	open ENUMS, '>', $cairo_enums
		or die "unable to open ($cairo_enums) for output";

	print ENUMS "
/*
 * This file was automatically generated.  Do not edit.
 */

#include <cairo-perl.h>

";

	sub canonicalize
	{
		my ($name, $prefix) = @_;
		$name =~ s/$prefix//;
		$name =~ tr/_/-/;
		$name = lc ($name);
		return $name;
	}

	sub if_tree_from
	{
		my @enums = @_;

		my $prefix = shift @enums;

		my $full = shift @enums;
		my $name = canonicalize($full, $prefix);

		# +1 so that strncmp also looks at the trailing \0, and discerns
		# 'color' and 'color-alpha', for example.
		my $len = length ($name) + 1;

		my $str = <<"EOS";
	if (strncmp (str, "$name", $len) == 0)
		return $full;
EOS

		foreach $full (@enums)
		{
			my $name = canonicalize($full, $prefix);
			$len = length ($name);

			$str .= <<"EOS";
	else if (strncmp (str, "$name", $len) == 0)
		return $full;
EOS
		}

		$str;
	}

	sub if_tree_to
	{
		my @enums = @_;

		my $prefix = shift @enums;
		my $full = shift @enums;
		my $name = canonicalize($full, $prefix);

		my $str = <<"EOS";
	if (val == $full)
		return newSVpv ("$name", 0);
EOS

		foreach $full (@enums)
		{
			my $name = canonicalize($full, $prefix);
			$str .= <<"EOS";
	else if (val == $full)
		return newSVpv ("$name", 0);
EOS
		}

		$str;
	}

	foreach my $type (keys %enums)
	{
		my $name = name($type);
		my @enum_values = @{$enums{$type}};

		next unless @enum_values;

		my $value_list = join ", ", map { canonicalize($_, $enum_values[0]) } @enum_values[1..$#enum_values];
		my $tree_from = if_tree_from (@enum_values);
		my $tree_to = if_tree_to (@enum_values);

		if (exists $guards{$type}) {
			print ENUMS "#ifdef $guards{$type}\n\n";
		}

		print ENUMS <<"EOS";
$type
cairo_${name}_from_sv (SV * $name)
{
	char * str = SvPV_nolen ($name);

	$tree_from
	croak ("`%s' is not a valid $type value; valid values are: $value_list", str);

	return 0;
}

SV *
cairo_${name}_to_sv ($type val)
{
	$tree_to
	warn ("unknown $type value %d encountered", val);
	return &PL_sv_undef;
}

EOS

		if (exists $guards{$type}) {
			print ENUMS "#endif /* $guards{$type} */\n";
		}
	}

	close ENUMS;
}

1;
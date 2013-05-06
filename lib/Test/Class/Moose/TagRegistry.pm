package Test::Class::Moose::TagRegistry;

## ABSTRACT: Global registry of tags by class and method.

use strict;
use warnings;

use Carp qw( croak );

my $by_tag = {};

sub add {
    my ( undef, $class, $method, $tags ) = @_;

    if ( not scalar @{ $tags } ) {
        die "no tags defined\n";
    }

    foreach my $tag ( @{ $tags } ) {
        if ( $tag !~ /^\w+$/ ) {
            die "tags must be alphanumeric\n";
        }
    }

    # dedupe tags
    my %tags = map { $_ => 1 } @{ $tags };

    my $exists = grep {
        exists $by_tag->{ $_ }{ $class }
          and exists $by_tag->{ $_ }{ $class }{ $method }
    } __PACKAGE__->tags;
    if ( $exists ) {
        die "tags for $class->$method already exists, method redefinition perhaps?\n";
    }

    foreach my $tag ( keys %tags ) {
        $by_tag->{ $tag }{ $class }{ $method } = 1;
    }
}

sub tags {
    return sort keys %{ $by_tag };
}

sub classes_with_tag {
    my ( undef, $tag ) = @_;

    croak( "no tag specified" ) if not defined $tag;

    return if not exists $by_tag->{ $tag };

    return sort keys %{ $by_tag->{ $tag } };
}

sub methods_with_tag {
    my ( undef, $class, $tag ) = @_;

    croak( "no class specified" ) if not defined $class;
    croak( "no tag specified" ) if not defined $tag;

    # avoid auto-vivication
    return if not exists $by_tag->{ $tag };

    return sort keys %{ $by_tag->{ $tag }{ $class } };
}

sub method_has_tag {
    my ( undef, $class, $method, $tag ) = @_;

    croak( "no class specified" ) if not defined $class;
    croak( "no method specified" ) if not defined $method;
    croak( "no tag specified" ) if not defined $tag;

    # avoid auto-vivication
    return 0 if not exists $by_tag->{ $tag };
    return 0 if not exists $by_tag->{ $tag }{ $class };

    return exists $by_tag->{ $tag }{ $class }{ $method }
      ? 1
      : 0;
}

1;

__END__

=head1 SYNOPSIS

 use Test::Class::Moose::TagRegistry;

 my @tags = Test::Class::Moose::TagRegistry->tags;
 foreach my $tag ( @tags ) {
     my @classes = Test::Class::Moose::TagRegistry->classes_with_tag( $tag );

     foreach my $class ( @classes ) {
         my @methods = Test::Class::Moose::TagRegistry->methods_with_tag( $class, $tag );

         foreach my $method ( @methods ) {
             print Test::Class::Moose::TagRegistry->method_has_tag( $class, $method, $tag );
         }
     }
 }

=head1 DESCRIPTION

This class permits addition and querying of the tags defined on methods. It's
been gleefully stolen from L<Attribute::Method::Tags> and is for internal use
only. Don't rely on this code.

=head1 METHODS

All the following are class methods, as the tag registry is shared globally.
Note that all parameters for any of the methods below are required.

=over 4

=item add( $class, $method, $tags_ref )

Adds the given list of tags (as an array-ref) for the specified class/method
combination.  An exception will be raised if either the tags are
non-alphanumeric or the method is one that has already had tags registered
for it.

=item tags

Find all tags defined for all methods.  Returns a sorted list of tags.

=item classes_with_tag( $tag )

Find all classes that have the specified tag.  Returns a sorted list of classes.

=item methods_with_tag( $class, $tag )

Returns a sorted list of methods in the specified class that have the
specified tag.

=item method_has_tag( $class, $method, $tag )

Returns a boolean (0|1), indicating whether the given method in the given class
has the specified tag.

=back

=head1 SEE ALSO

=over 4

=item L<Attribute::Method::Tags>

Attribute-based interface for adding tags to methods. Your author "liberated"
this code from L<Attribute::Method::Tags::Registry> (with a tip 'o the
keyboard to Mark Morgan for his work on this).

=back

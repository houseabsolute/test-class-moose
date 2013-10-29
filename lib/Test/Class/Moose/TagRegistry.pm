package Test::Class::Moose::TagRegistry;

## ABSTRACT: Global registry of tags by class and method.

use strict;
use warnings;

use Carp;
use Class::MOP;
use List::MoreUtils qw( any uniq );

my %BY_METHOD;

sub add {
    my ( $class, $test_class, $method, $tags ) = @_;

    my @tags_copy = @{$tags};

    # check for additions or deletions to the inherited tag list
    if (any { /^[-+]/ } @tags_copy) {
        @tags_copy = $class->_augment_tags($test_class, $method, $tags);
    }

    foreach my $tag ( @tags_copy ) {
        if ( $tag !~ /^\w+$/ ) {
            die "tags must be alphanumeric\n";
        }
    }

    # dedupe tags
    my %tags = map { $_ => 1 } @tags_copy;

    if (exists $BY_METHOD{$method} && exists $BY_METHOD{$method}{$test_class}) {
        die
          "tags for $test_class->$method already exists, method redefinition perhaps?\n";
    }

    $BY_METHOD{$method}{$test_class} = \%tags;

    return;
}

sub tags {
    my @tags;
    for my $method ( keys %BY_METHOD ) {
        for my $test_class ( keys %{ $BY_METHOD{$method} } ) {
            push @tags, keys %{ $BY_METHOD{$method}{$test_class} };
        }
    }

    return sort( uniq(@tags) );
}

sub method_has_tag {
    my ( $class, $test_class, $method, $tag ) = @_;

    croak("no class specified")  if not defined $test_class;
    croak("no method specified") if not defined $method;
    croak("no tag specified")    if not defined $tag;

    # avoid auto-vivication
    return if not exists $BY_METHOD{$method};

    if (not exists $BY_METHOD{$method}{$test_class}) {
        # If this method has no tag data at all, then inherit the tags from
        # from the superclass
        $BY_METHOD{$method}{$test_class} = $class->_superclass_tags($test_class, $method);
    }

    return exists $BY_METHOD{$method}{$test_class}{$tag};
}

sub _superclass_tags {
    my ( $class, $test_class, $method ) = @_;

    croak("no class specified")  if not defined $test_class;
    croak("no method specified") if not defined $method;

    return {} if not exists $BY_METHOD{$method};

    my $test_class_meta = Class::MOP::Class->initialize($test_class);
    my $method_meta;
    
    $method_meta = $test_class_meta->find_next_method_by_name($method)
    	if $test_class_meta->can('find_next_method_by_name');

    if(!$method_meta){
	#Might be a from a role or this class
	my $mm = $test_class_meta->find_method_by_name($method);
	my $orig = $mm->original_method;

	if($orig && ($mm->package_name ne $orig->package_name)){
		$method_meta = $orig;
	}
    }

    # no method, so no tags to inherit
    return {} if not $method_meta;

    my $super_test_class = $method_meta->package_name();
    if ( exists $BY_METHOD{$method}{$super_test_class} ) {
        # shallow copy the superclass method's tags, because it's possible to
        # change add/remove items from the subclass's list later
        my %tags = map { $_ => 1 } keys %{ $BY_METHOD{$method}{$super_test_class} };
        return \%tags;
    }

    # nothing defined at this level, recurse
    return $class->_superclass_tags($super_test_class, $method);
}

sub _augment_tags {
    my ( $class, $test_class, $method, $tags ) = @_;

    croak("no class specified")  if not defined $test_class;
    croak("no method specified") if not defined $method;

    # Get the base list from the superclass
    my $tag_list = $class->_superclass_tags($test_class, $method);

    for my $tag_definition (@{$tags}) {
        my $direction = substr($tag_definition, 0, 1);
        my $tag = substr($tag_definition, 1);
        if ($direction eq '+') {
            $tag_list->{$tag} = 1;
        }
        elsif ($direction eq '-') {
            # die here if the tag wasn't inherited?
            delete $tag_list->{$tag};
        }
        else {
            die "$test_class->$method attempting to override and modify tags, did you forget a '+'?\n";
        }
    }

    return keys %{$tag_list};
}

1;

__END__

=head1 SYNOPSIS

 use Test::Class::Moose::TagRegistry;

 my @tags = Test::Class::Moose::TagRegistry->tags;
 print Test::Class::Moose::TagRegistry->method_has_tag( 'TestsFor::FooBar', 'test_baz', 'network' );

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

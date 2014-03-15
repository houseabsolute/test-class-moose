package TestsFor::Basic::Role;

use Test::Class::Moose::Role;

sub test_in_a_role {
	my $test = shift;

	pass "This is picked up from role";
}

sub in_a_role_with_tags : Tags(first){	
	fail "We should never see this test";
}

sub test_in_a_role_with_tags : Tags(second){
	pass "We should see this test";
}

1;

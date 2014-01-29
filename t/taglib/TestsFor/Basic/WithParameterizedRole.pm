package TestsFor::Basic::WithParameterizedRole;
use Test::Class::Moose;

with 'TestsFor::Basic::ParameterizedRole' => {
  message => "This is picked up from a parameterized role"
};

sub test_in_withparameterizedrole {
  pass "Got here";
}

1;

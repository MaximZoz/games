package store

import "testing"

func TestStakePotRefundsEveryone(t *testing.T) {
	t.Parallel()
	if !StakePotRefundsEveryone(true, []string{"a"}) {
		t.Fatal("draw must refund even if a winner id leaked")
	}
	if !StakePotRefundsEveryone(false, nil) {
		t.Fatal("empty winners must refund")
	}
	if StakePotRefundsEveryone(false, []string{"a"}) {
		t.Fatal("a winner must not refund the pot")
	}
}

#!/usr/bin/env bats

@test "prints version when --version given" {
	run workstation --version
	[ $status -eq 0 ]
	echo "$output" | grep -q "0.1.0"
}

@test "version command prints version" {
	run workstation version
	[ $status -eq 0 ]
	echo "$output" | grep -q "0.1.0"
}

@test "prints help when --help given" {
	run workstation --help
	[ $status -eq 0 ]
	echo "$output" | grep -q "Usage"
}

@test "prints help when unknown command given" {
	run workstation help
	[ $status -eq 0 ]
	echo "$output" | grep -q "Usage"
}

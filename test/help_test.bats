#!/usr/bin/env bats

@test "prints version when --version given" {
	run workstation --version
	[ $status -eq 0 ]
	echo "${output}" | grep -q "0.2.0"
}

@test "version command prints version" {
	run workstation version
	[ $status -eq 0 ]
	echo "${output}" | grep -q "0.2.0"
}

@test "prints help when --help given" {
	run workstation --help
	[ $status -eq 0 ]
	echo "${output}" | grep -qi "usage"
}

@test "prints help when unknown command given" {
	run workstation help
	[ $status -eq 0 ]
	echo "${output}" | grep -qi "usage"
}

@test "prints usage when no args given" {
	run workstation
	[ $status -eq 1 ]
	echo "${output}" | grep -qi "usage"
}

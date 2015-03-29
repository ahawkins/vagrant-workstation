#!/usr/bin/env bats

setup() {
	rm -rf "${WORKSTATION_PROJECT_PATH}"/*
}

@test "fails if no command given" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" << EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo bar
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo/cmd"

	cd "${WORKSTATION_PROJECT_PATH}/foo"
	run workstation run

	[ $status -eq 1 ]
}

@test "run executes command in matching project directory" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" << EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo bar
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo/cmd"

	cd "${WORKSTATION_PROJECT_PATH}/foo"
	run workstation run ./cmd

	[ $status -eq 0 ]
	echo "$output" | grep -q bar
}

@test "run accepts -p to specify project" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" << EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo foo-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo/cmd"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/bar"
	cat > "${WORKSTATION_PROJECT_PATH}/bar/cmd" << EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo bar-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/bar/cmd"

	run workstation run -p foo -- ./cmd

	[ $status -eq 0 ]
	echo "$output" | grep -q foo-project

	run workstation run -p bar -- ./cmd

	[ $status -eq 0 ]
	echo "$output" | grep -q bar-project
}

@test "run -p does fuzzy matching" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" << EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo foo-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo/cmd"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/bar"
	cat > "${WORKSTATION_PROJECT_PATH}/bar/cmd" << EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo bar-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/bar/cmd"

	# Test fuzzy match start of project
	run workstation run -p f -- ./cmd
	echo "$output"
	[ $status -eq 0 ]
	echo "$output" | grep -q foo-project

	# Test fuzzy match end of project
	run workstation run -p oo -- ./cmd
	[ $status -eq 0 ]
	echo "$output" | grep -q foo-project

	# Test the other project is also matched in a fuzzy way
	run workstation run -p b -- ./cmd
	[ $status -eq 0 ]
	echo "$output" | grep -q bar-project
}

@test "run -p fails if multiple fuzzy matches" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo-bar"
	cat > "${WORKSTATION_PROJECT_PATH}/foo-bar/cmd" << EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo foo-bar-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo-bar/cmd"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo-baz"
	cat > "${WORKSTATION_PROJECT_PATH}/foo-baz/cmd" << EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo foo-baz-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo-baz/cmd"

	# Test fuzzy match start of project
	run workstation run -p f -- ./cmd
	[ $status -eq 1 ]

	run workstation run -p foo -- ./cmd
	[ $status -eq 1 ]

	run workstation run -p foo-bar -- ./cmd
	[ $status -eq 0 ]
	echo "$output" | grep -q foo-bar-project

	run workstation run -p foo-baz -- ./cmd
	[ $status -eq 0 ]
	echo "$output" | grep -q foo-baz-project
}

@test "recurses up directories to find project from CWD" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo/bar/baz/qux"
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" << EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo OK
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo/cmd"

	cd "${WORKSTATION_PROJECT_PATH}/foo/bar/baz/qux"
	run workstation run ./cmd

	echo "$output"

	[ $status -eq 0 ]
	echo "$output" | grep -q OK
}

@test "fails if project cannot be determed from CWD" {
	skip
}

@test "runs in a login shell" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cd "${WORKSTATION_PROJECT_PATH}/foo"

	run workstation run shopt -q login_shell

	[ $status -eq 0 ]
}

# Extend with custom run commands, eg define something that shortcuts
# workstation make to be like workstation run make

# Workstation specific commands. Create some file in some directory
# (e.g) .workstation/my-command, then you can $ workstation my-command

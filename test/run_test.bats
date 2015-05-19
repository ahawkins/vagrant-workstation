#!/usr/bin/env bats

setup() {
	# NOTE: This setting will cause failures if a variable is undefined.
	# If this does happen, no output is printed to the screen because
	# the process exists outside of bats expected loop.
	set -u

	rm -rf "${WORKSTATION_PROJECT_PATH}/commands"
	rm -rf "${WORKSTATION_PROJECT_PATH}"
	rm -rf "${WORKSTATION_HOME}/commands"

	mkdir -p "${WORKSTATION_PROJECT_PATH}"
}

teardown() {
	set +u
}

@test "run fails if no command given" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" <<EOF
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
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" <<EOF
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
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" <<EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo foo-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo/cmd"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/bar"
	cat > "${WORKSTATION_PROJECT_PATH}/bar/cmd" <<EOF
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
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" <<EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo foo-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo/cmd"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/bar"
	cat > "${WORKSTATION_PROJECT_PATH}/bar/cmd" <<EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo bar-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/bar/cmd"

	# Test fuzzy match start of project
	run workstation run -p f -- ./cmd
	[ $status -eq 0 ]
	echo "$output" | grep -q foo-project

	# Test fuzzy match end of project
	run workstation run -p oo -- ./cmd
	[ $status -eq 0 ]
	echo "$output" | grep -q foo-project

	# Test fuzzy match also accepts complete name
	run workstation run -p foo -- ./cmd
	[ $status -eq 0 ]
	echo "$output" | grep -q foo-project

	# Test the other project is also matched in a fuzzy way
	run workstation run -p b -- ./cmd
	[ $status -eq 0 ]
	echo "$output" | grep -q bar-project
}

@test "run -p prefers an exact match" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" <<EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo foo-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo/cmd"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo-bar"
	cat > "${WORKSTATION_PROJECT_PATH}/foo-bar/cmd" <<EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo foo-bar-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo-bar/cmd"

	# Test hits the exact match
	run workstation run -p foo -- ./cmd
	[ $status -eq 0 ]
	echo "$output" | grep -q foo-project
}

@test "run -p fails if multiple fuzzy matches" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo-bar"
	cat > "${WORKSTATION_PROJECT_PATH}/foo-bar/cmd" <<EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo foo-bar-project
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo-bar/cmd"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo-baz"
	cat > "${WORKSTATION_PROJECT_PATH}/foo-baz/cmd" <<EOF
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
	cat > "${WORKSTATION_PROJECT_PATH}/foo/cmd" <<EOF
	#!/usr/bin/env bash
	set -eou pipefail
	echo OK
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/foo/cmd"

	cd "${WORKSTATION_PROJECT_PATH}/foo/bar/baz/qux"
	run workstation run ./cmd

	[ $status -eq 0 ]
	echo "$output" | grep -q OK
}

@test "fails if project cannot be determined from CWD" {
	skip
}

@test "runs in a login shell" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cd "${WORKSTATION_PROJECT_PATH}/foo"

	run workstation run -- shopt -q login_shell

	[ $status -eq 0 ]
}

@test "includes correct ssh options" {
	skip
}

@test "custom aliases defined in PROJECT_PATH" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/.workstation/commands"
	echo "/projects/test-command" > "${WORKSTATION_PROJECT_PATH}/.workstation/commands/test"

	cat > "${WORKSTATION_PROJECT_PATH}/test-command" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	if [ "$*" = "foo --bar" ]; then
		echo "OK"
		exit 0
	else
		exit 1
	fi
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/test-command"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cd "${WORKSTATION_PROJECT_PATH}/foo"

	run workstation test -- foo --bar
	[ $status -eq 0 ]
	echo "$output" | grep -q "OK"
}

@test "custom aliases defined in WORKSTATION_HOME" {
	mkdir -p "${WORKSTATION_HOME}/commands"
	echo "/projects/test-command" > "${WORKSTATION_HOME}/commands/test"

	cat > "${WORKSTATION_PROJECT_PATH}/test-command" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	if [ "$*" = "foo --bar" ]; then
		echo "OK"
		exit 0
	else
		exit 1
	fi
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/test-command"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cd "${WORKSTATION_PROJECT_PATH}/foo"

	run workstation test foo --bar
	[ $status -eq 0 ]
	echo "$output" | grep -q "OK"
}

@test "PROJECT_PATH aliases work with -p" {
	mkdir -p "${WORKSTATION_PROJECT_PATH}/.workstation/commands"
	echo "/projects/test-command" > "${WORKSTATION_PROJECT_PATH}/.workstation/commands/test"

	cat > "${WORKSTATION_PROJECT_PATH}/test-command" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	if [ "${PWD}" = "/projects/foo" ] && [ "$*" = "bar --baz" ]; then
		echo "OK"
		exit 0
	else
		exit 1
	fi
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/test-command"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	mkdir -p "${WORKSTATION_PROJECT_PATH}/bar"

	run workstation test -p foo -- bar --baz
	[ $status -eq 0 ]
	echo "$output" | grep -q "OK"
}

@test "WORKSTATION_HOME aliases work with -p" {
	mkdir -p "${WORKSTATION_HOME}/commands"
	echo "/projects/test-command" > "${WORKSTATION_HOME}/commands/test"

	cat > "${WORKSTATION_PROJECT_PATH}/test-command" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	if [ "${PWD}" = "/projects/foo" ] && [ "$*" = "bar --baz" ]; then
		echo "OK"
		exit 0
	else
		exit 1
	fi
EOF
	chmod +x "${WORKSTATION_PROJECT_PATH}/test-command"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	mkdir -p "${WORKSTATION_PROJECT_PATH}/bar"

	run workstation test -p foo -- bar --baz
	[ $status -eq 0 ]
	echo "$output" | grep -q "OK"
}

@test "PROJECT_PATH aliases override WORKSTATION_HOME aliases" {
	mkdir -p "${WORKSTATION_HOME}/commands"
	echo "echo 'workstation-alias'" > "${WORKSTATION_HOME}/commands/test"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/.workstation/commands"
	echo "echo 'project-alias'" > "${WORKSTATION_PROJECT_PATH}/.workstation/commands/test"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cd "${WORKSTATION_PROJECT_PATH}/foo"

	run workstation test
	[ $status -eq 0 ]
	echo "$output" | grep -q "project-alias"
}

@test "PROJECT_PATH aliases may be symlinked" {
	scratch="$(mktemp -d -t workstation)"
	echo "echo 'symlink-alias'" > "${scratch}/test"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/.workstation"
	ln -s "$scratch" "${WORKSTATION_PROJECT_PATH}/.workstation/commands"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cd "${WORKSTATION_PROJECT_PATH}/foo"

	run workstation test
	[ $status -eq 0 ]
	echo "$output" | grep -q "symlink-alias"
}

@test "WORKSTATION_HOME aliases may be symlinked" {
	scratch="$(mktemp -d -t workstation)"
	echo "echo 'symlink-alias'" > "${scratch}/test"

	ln -s "$scratch" "${WORKSTATION_HOME}/commands"

	mkdir -p "${WORKSTATION_PROJECT_PATH}/foo"
	cd "${WORKSTATION_PROJECT_PATH}/foo"

	run workstation test
	[ $status -eq 0 ]
	echo "$output" | grep -q "symlink-alias"
}

#!/usr/bin/env bats

setup() {
	scratch="$(mktemp -d)"
	project_path="$(mktemp -d)"
	vagrant_file="$(mktemp)"
	workstation_home="$(mktemp -d)"

	command_path="${project_path}/.workstation/commands"

	mkdir -p "${command_path}"
	echo "placeholder" > "${command_path}/placeholder"
}

@test "prints usage when cannot determine name from filesystem" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo "WORKSTATION_NAME=${WORKSTATION_NAME}"
EOF
	chmod +x "${scratch}/ssh"

	mkdir -p "${project_path}/foo/bar/baz"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"

	pushd "$(mktemp -d)" > /dev/null

	mkdir -p "${workstation_home}/dummy"
	echo "${project_path}" > "${workstation_home}/dummy/project_path"
	echo "${vagrant_file}" > "${workstation_home}/dummy/vagrant_file"

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_HOME=${workstation_home}" \
		workstation placholder

	[ $status -eq 1 ]
	echo "${output}" | fgrep -qi 'usage'
}

@test "command WORKSTATION_NAME prefers file system based lookup" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo "WORKSTATION_NAME=${WORKSTATION_NAME}"
EOF
	chmod +x "${scratch}/ssh"

	mkdir -p "${project_path}/foo"
	mkdir -p "${project_path}/.workstation"
	echo "junk" > "${project_path}/.workstation/name"
	pushd "${project_path}/foo" > /dev/null

	mkdir -p "${workstation_home}/dummy"
	echo "${project_path}" > "${workstation_home}/dummy/project_path"
	echo "${vagrant_file}" > "${workstation_home}/dummy/vagrant_file"

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_HOME=${workstation_home}" \
		"WORKSTATION_NAME=dummy" \
		workstation placeholder

	[ $status -eq 0 ]
	echo "${output}" | fgrep -q "WORKSTATION_NAME=dummy"
}

@test "command fails if machine does not exist" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	exit 1 # nothing should be invoked so fail
EOF
	chmod +x "${scratch}/ssh"

	[ ! -d "${workstation_home}/dummy" ]

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_HOME=${workstation_home}" \
		"WORKSTATION_NAME=dummy" \
		workstation placeholder

	[ $status -eq 1 ]
}

@test "command fails if ssh config stale" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	if [ "$4" = "default" ] && [ "$5" = "true" ]; then
		exit 1
	else
		exit 0
	fi
EOF
	chmod +x "${scratch}/ssh"

	mkdir -p "${project_path}/foo"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"

	mkdir -p "${workstation_home}/dummy"
	echo "${project_path}" > "${workstation_home}/dummy/project_path"
	echo "${vagrant_file}" > "${workstation_home}/dummy/vagrant_file"

	pushd "${project_path}/foo" > /dev/null

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_HOME=${workstation_home}" \
		workstation placeholder

	[ $status -eq 5 ]
	echo "${output}" | fgrep -q "stale"
	echo "${output}" | fgrep -q "reload"
}

@test "command invoked over ssh in appopriate directory" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo args=$@
EOF
	chmod +x "${scratch}/ssh"

	mkdir -p "${project_path}/foo"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"

	mkdir -p "${workstation_home}/dummy"
	echo "${project_path}" > "${workstation_home}/dummy/project_path"
	echo "${vagrant_file}" > "${workstation_home}/dummy/vagrant_file"

	pushd "${project_path}/foo" > /dev/null

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_HOME=${workstation_home}" \
		workstation placeholder -foo bar

	[ $status -eq 0 ]
	echo "${output}" | fgrep -q "cd '/projects/foo' && bash -l -c 'placeholder -foo bar'"
	echo "${output}" | fgrep -q -- "-F ${workstation_home}/dummy/ssh_config"
}

@test "prints usage if alias does not exist" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo args=$@
EOF
	chmod +x "${scratch}/ssh"

	mkdir -p "${project_path}/foo"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"

	mkdir -p "${workstation_home}/dummy"
	echo "${project_path}" > "${workstation_home}/dummy/project_path"
	echo "${vagrant_file}" > "${workstation_home}/dummy/vagrant_file"

	pushd "${project_path}/foo" > /dev/null

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_HOME=${workstation_home}" \
		workstation junk

	[ $status -eq 1 ]
	echo "${output}" | fgrep -qi "usage"
}

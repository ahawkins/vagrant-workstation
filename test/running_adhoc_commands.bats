#!/usr/bin/env bats

setup() {
	[ -n "${XDG_DATA_HOME}" ]

	data_dir="${XDG_DATA_HOME}/workstation"
	rm -rf "${data_dir}"

	scratch="$(mktemp -d)"
	project_path="$(mktemp -d)"
	vagrant_file="$(mktemp)"
}

@test "command fails if cannot determine name from file system" {
	mkdir -p "${project_path}/foo/bar/baz"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"

	pushd "$(mktemp -d)" > /dev/null

	mkdir -p "${data_dir}/dummy"
	echo "${project_path}" > "${data_dir}/dummy/project_path"
	echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

	run env \
		"PATH=${scratch}:${PATH}" \
		workstation run true

	[ $status -eq 3 ]
}

@test "command fails if machine does not exist" {
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	exit 1 # nothing should be invoked so fail
EOF
	chmod +x "${scratch}/vagrant"

	[ ! -d "${data_dir}/dummy" ]

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_NAME=dummy" \
		workstation run true

	[ $status -eq 1 ]
}

@test "command fails if ssh config stale" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo "$@"
	if [ "$4" = "default" ] && [ "$5" = "true" ]; then
		exit 1
	else
		exit 0
	fi
EOF
	chmod +x "${scratch}/ssh"

	mkdir -p "${project_path}/foo/bar/baz"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"

	mkdir -p "${data_dir}/dummy"
	echo "${project_path}" > "${data_dir}/dummy/project_path"
	echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

	pushd "${project_path}/foo/bar/baz" > /dev/null

	run env \
		"PATH=${scratch}:${PATH}" \
		workstation run true

	[ $status -eq 5 ]
	echo "${output}" | fgrep -q "stale"
	echo "${output}" | fgrep -q "reload"
}

@test "command fails if cannot determine project directory" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo args=$@
EOF
	chmod +x "${scratch}/ssh"

	mkdir -p "${project_path}/foo"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"

	mkdir -p "${data_dir}/dummy"
	echo "${project_path}" > "${data_dir}/dummy/project_path"
	echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

	pushd "$(mktemp -d)" > /dev/null

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_NAME=dummy" \
		workstation run true

	[ $status -eq 1 ]
	echo "${output}" | fgrep -qi "change directory"
}

@test "command invoked over ssh in appopriate directory" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo args=$@
EOF
	chmod +x "${scratch}/ssh"

	mkdir -p "${project_path}/foo/bar/baz"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"

	mkdir -p "${data_dir}/dummy"
	echo "${project_path}" > "${data_dir}/dummy/project_path"
	echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

	pushd "${project_path}/foo/bar/baz" > /dev/null

	run env \
		"PATH=${scratch}:${PATH}" \
		workstation run true

	[ $status -eq 0 ]
	echo "${output}" | fgrep -q "cd '/projects/foo' && bash -l -c 'true'"
	echo "${output}" | fgrep -q -- "-F ${data_dir}/dummy/ssh_config"
}

@test "command WORKSTATION_NAME prefers file system based lookup" {
	cat > "${scratch}/ssh" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo "WORKSTATION_NAME=${WORKSTATION_NAME}"
EOF
	chmod +x "${scratch}/ssh"

	mkdir -p "${project_path}/foo/bar/baz"
	mkdir -p "${project_path}/.workstation"
	echo "junk" > "${project_path}/.workstation/name"
	pushd "${project_path}/foo/bar/baz" > /dev/null

	mkdir -p "${data_dir}/dummy"
	echo "${project_path}" > "${data_dir}/dummy/project_path"
	echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_NAME=dummy" \
		workstation run true

	[ $status -eq 0 ]
	echo "${output}" | fgrep -q "WORKSTATION_NAME=dummy"
}


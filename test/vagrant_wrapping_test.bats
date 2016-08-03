#!/usr/bin/env bats

setup() {
	[ -n "${XDG_DATA_HOME}" ]

	data_dir="${XDG_DATA_HOME}/workstation"
	rm -rf "${data_dir}"

	scratch="$(mktemp -d)"
	project_path="$(mktemp -d)"
	vagrant_file="$(mktemp)"
}

@test "command reads name from file system" {
	declare -a WRAPPED_COMMANDS=( destroy reload provision halt suspend ssh-config ssh rsync )

	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo "WORKSTATION_NAME=${WORKSTATION_NAME}"
EOF
	chmod +x "${scratch}/vagrant"

	mkdir -p "${project_path}/foo/bar/baz"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"
	pushd "${project_path}/foo/bar/baz" > /dev/null

	for wrapped_command in "${WRAPPED_COMMANDS[@]}"; do
		mkdir -p "${data_dir}/dummy"
		echo "${project_path}" > "${data_dir}/dummy/project_path"
		echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

		run env \
			"PATH=${scratch}:${PATH}" \
			workstation "${wrapped_command}"

		[ $status -eq 0 ]
		echo "${output}" | fgrep -q "WORKSTATION_NAME=dummy"
	done
}

@test "command fails if cannot determine name from file system" {
	declare -a WRAPPED_COMMANDS=( destroy reload provision halt suspend ssh-config ssh rsync )

	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo "WORKSTATION_NAME=${WORKSTATION_NAME}"
EOF
	chmod +x "${scratch}/vagrant"

	mkdir -p "${project_path}/foo/bar/baz"
	mkdir -p "${project_path}/.workstation"
	echo "dummy" > "${project_path}/.workstation/name"

	pushd "$(mktemp -d)" > /dev/null

	for wrapped_command in "${WRAPPED_COMMANDS[@]}"; do
		mkdir -p "${data_dir}/dummy"
		echo "${project_path}" > "${data_dir}/dummy/project_path"
		echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

		run env \
			"PATH=${scratch}:${PATH}" \
			workstation "${wrapped_command}"

		[ $status -eq 3 ]
	done
}

@test "command WORKSTATION_NAME prefers file system based lookup" {
	declare -a WRAPPED_COMMANDS=( destroy reload provision halt status snapshot suspend ssh-config ssh rsync)

	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo "WORKSTATION_NAME=${WORKSTATION_NAME}"
EOF
	chmod +x "${scratch}/vagrant"

	mkdir -p "${project_path}/foo/bar/baz"
	mkdir -p "${project_path}/.workstation"
	echo "junk" > "${project_path}/.workstation/name"
	pushd "${project_path}/foo/bar/baz" > /dev/null

	for wrapped_command in "${WRAPPED_COMMANDS[@]}"; do
		mkdir -p "${data_dir}/dummy"
		echo "${project_path}" > "${data_dir}/dummy/project_path"
		echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

		run env \
			"PATH=${scratch}:${PATH}" \
			"WORKSTATION_NAME=dummy" \
			workstation "${wrapped_command}"

		[ $status -eq 0 ]
		echo "${output}" | fgrep -q "WORKSTATION_NAME=dummy"
	done
}

@test "command fails if machine does not exist" {
	declare -a WRAPPED_COMMANDS=( destroy reload provision halt status snapshot suspend ssh-config ssh rsync )

	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	exit 1 # nothing should be invoked so fail
EOF
	chmod +x "${scratch}/vagrant"

	for wrapped_command in "${WRAPPED_COMMANDS[@]}"; do
		[ ! -d "${data_dir}/dummy" ]

		run env \
			"PATH=${scratch}:${PATH}" \
			"WORKSTATION_NAME=dummy" \
			workstation "${wrapped_command}" -foo bar

		[ $status -eq 1 ]
	done
}

@test "commands are wrapped appropriately" {
	declare -a WRAPPED_COMMANDS=( destroy reload provision halt status snapshot suspend ssh-config ssh rsync )

	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail

	env
	echo "args=$@"
EOF
	chmod +x "${scratch}/vagrant"

	for wrapped_command in "${WRAPPED_COMMANDS[@]}"; do
		mkdir -p "${data_dir}/dummy"
		echo "${project_path}" > "${data_dir}/dummy/project_path"
		echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

		run env \
			"PATH=${scratch}:${PATH}" \
			"WORKSTATION_NAME=dummy" \
			workstation "${wrapped_command}" -foo bar

		[ $status -eq 0 ]
		echo "${output}" | fgrep -q "VAGRANT_CWD=$(dirname "${vagrant_file}")"
		echo "${output}" | fgrep -q "WORKSTATION_PROJECT_PATH=${project_path}"
		echo "${output}" | fgrep -q "args=${wrapped_command} -foo bar"
	done
}

@test "reload regenerates ssh config" {
	mkdir -p "${data_dir}/dummy"
	echo "${project_path}" > "${data_dir}/dummy/project_path"
	echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail

	if [ "$1" = "reload" ]; then
		env
		echo "args=$@"
	elif [ "$1" = "ssh-config" ]; then
		env
		echo "fake-ssh-config"
	else
		exit 1
	fi
EOF
	chmod +x "${scratch}/vagrant"

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_NAME=dummy" \
		workstation reload -foo bar

	[ $status -eq 0 ]

	fgrep -q "VAGRANT_CWD=$(dirname "${vagrant_file}")" "${data_dir}/dummy/ssh_config"
	fgrep -q "WORKSTATION_PROJECT_PATH=${project_path}" "${data_dir}/dummy/ssh_config"
	fgrep -q "fake-ssh-config" "${data_dir}/dummy/ssh_config"
}

@test "destroy removes workstation artifcats" {
	mkdir -p "${data_dir}/dummy"
	echo "${project_path}" > "${data_dir}/dummy/project_path"
	echo "${vagrant_file}" > "${data_dir}/dummy/vagrant_file"

	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail

	env
	echo "args=$@"
EOF
	chmod +x "${scratch}/vagrant"

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_NAME=dummy" \
		workstation destroy -foo bar

	echo "${output}"
	[ $status -eq 0 ]
	[ ! -d "${data_dir}/dummy" ]
}

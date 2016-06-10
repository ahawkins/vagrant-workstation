#!/usr/bin/env bats

setup() {
	[ -n "${XDG_DATA_HOME}" ]

	data_dir="${XDG_DATA_HOME}/workstation"
	rm -rf "${data_dir}"

	scratch="$(mktemp -d)"
	project_path="$(mktemp -d)"
	vagrant_file="$(mktemp)"
}

@test "up requires -v" {
	run workstation up -n "test" -p "$(mktemp -d)"
	[ $status -ne 0 ]
}

@test "up fails when -v is not a file" {
	run workstation up -n "test" -p "$(mktemp -d)" -v "$(mktemp -d)"
	[ $status -ne 0 ]
}

@test "up requires -n" {
	run workstation up -v "$(mktemp)" -p "$(mktemp -d)"
	[ $status -ne 0 ]
}

@test "up requires -p" {
	run workstation up -v "$(mktemp)" -n "test"
	[ $status -ne 0 ]
}

@test "up fails when -p is not a directory" {
	run workstation up -v "$(mktemp)" -n "test" -p "$(mktemp)"
	[ $status -ne 0 ]
}

@test "up wraps vagrant up & vagrant ssh-config" {
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail

	if [ "$1" = "up" ]; then
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
		workstation up \
		-n "dummy" \
		-v "${vagrant_file}" \
		-p "${project_path}" \
		-- -foo bar

	[ $status -eq 0 ]

	echo "${output}" | fgrep -q "VAGRANT_CWD=$(dirname "${vagrant_file}")"
	echo "${output}" | fgrep -q "WORKSTATION_PROJECT_PATH=${project_path}"
	echo "${output}" | fgrep -q "args=up -foo bar"

	fgrep -q "VAGRANT_CWD=$(dirname "${vagrant_file}")" "${data_dir}/dummy/ssh_config"
	fgrep -q "WORKSTATION_PROJECT_PATH=${project_path}" "${data_dir}/dummy/ssh_config"
	fgrep -q "fake-ssh-config" "${data_dir}/dummy/ssh_config"

	[ "$(cat "${project_path}/.workstation/name")" = "dummy" ]
	[ -d "${project_path}/.workstation/commands" ]
}

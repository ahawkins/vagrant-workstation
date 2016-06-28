#!/usr/bin/env bats

setup() {
	[ -n "${XDG_DATA_HOME}" ]

	data_dir="${XDG_DATA_HOME}/workstation"
	rm -rf "${data_dir}"

	scratch="$(mktemp -d)"
	project_path="$(mktemp -d)"
	vagrant_file="$(mktemp)"
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

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_NAME=dummy" \
		workstation exec true

	[ $status -eq 5 ]
	echo "${output}" | fgrep -q "stale"
	echo "${output}" | fgrep -q "reload"
}

@test "command invoked over ssh" {
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

	run env \
		"PATH=${scratch}:${PATH}" \
		"WORKSTATION_NAME=dummy" \
		workstation exec true

	[ $status -eq 0 ]
	echo "${output}" | fgrep -q "bash -l -c 'true'"
	echo "${output}" | fgrep -q -- "-F ${data_dir}/dummy/ssh_config"
}

#!/usr/bin/env bats

@test "reload fails if VM not booted" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	[ ! -e "${scratch}/project_path" ] # precondition

	run env PATH="${scratch}:$PATH" WORKSTATION_HOME="$scratch" workstation reload
	[ $status -eq 1 ]
	echo "$output" | grep -q "up"
}

@test "reload fails if no WORKSTATION_VAGRANTFILE" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE= workstation reload
	[ $status -eq 1 ]
	echo "$output" | grep -q "WORKSTATION_VAGRANTFILE"
}

@test "reload fails if WORKSTATION_VAGRANTFILE does not exist" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	[ ! -d "/foo/bar/baz" ]

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE="/foo/bar/baz" workstation reload
	[ $status -eq 1 ]
	echo "$output" | grep -q "WORKSTATION_VAGRANTFILE"
}

@test "reload executes vagrant reload with correct WORKSATION_PROJECT_PATH" {
	scratch="$(mktemp -d -t workstation)"
	echo -n "/foo/bar" > "${scratch}/project_path"

	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	if [ "$1" = "reload" ] && [ "$WORKSTATION_PROJECT_PATH" = "/foo/bar" ]; then
		exit 0
	elif [ "$1" = "ssh-config" ]; then
		echo "fake-ssh-config"
		exit 0
	else
		exit 1
	fi
EOF
	chmod +x "${scratch}/vagrant"

	run env PATH="${scratch}:$PATH" WORKSTATION_HOME="$scratch" workstation reload
	[ $status -eq 0 ]
}

@test "reload regenerates ssh config" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	echo fake-ssh-config
EOF
	chmod +x "${scratch}/vagrant"
	echo "/foo/bar" > "${scratch}/project_path"

	run env PATH="${scratch}:$PATH" WORKSTATION_HOME="$scratch" workstation reload
	[ $status -eq 0 ]
	[ "$(cat "${scratch}/ssh_config")" = "fake-ssh-config" ]
}

@test "reload executes in the vagrantfile directory" {
	scratch="$(mktemp -d -t workstation)"
	echo "$scratch"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	echo "${PWD}-pwd"
EOF
	chmod +x "${scratch}/vagrant"
	echo "/foo/bar" > "${scratch}/project_path"

	cd "$(mktemp -d -t workstation)"
	run env PATH="${scratch}:$PATH" WORKSTATION_HOME="$scratch" workstation reload
	[ $status -eq 0 ]
	echo "$output" | grep -q "$(dirname "${WORKSTATION_VAGRANTFILE}")-pwd"
}

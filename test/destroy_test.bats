#!/usr/bin/env bats

@test "destroy fails if no WORKSTATION_VAGRANTFILE" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE= workstation destroy
	[ $status -eq 1 ]
	echo "$output" | grep -q "WORKSTATION_VAGRANTFILE"
}

@test "destroy fails if WORKSTATION_VAGRANTFILE does not exist" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	[ ! -d "/foo/bar/baz" ]

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE="/foo/bar/baz" workstation destroy
	[ $status -eq 1 ]
	echo "$output" | grep -q "WORKSTATION_VAGRANTFILE"
}

@test "destroy deletes ssh config artifact" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 0
EOF
	chmod +x "${scratch}/vagrant"
	touch "${scratch}/ssh_config"

	run env PATH="${scratch}:$PATH" WORKSTATION_HOME="$scratch" workstation destroy
	[ $status -eq 0 ]
	[ ! -e "${scratch}/ssh_config" ]
}

@test "destroy deletes project root artifatc" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 0
EOF
	chmod +x "${scratch}/vagrant"
	touch "${scratch}/project_root"

	run env PATH="${scratch}:$PATH" WORKSTATION_HOME="$scratch" workstation destroy
	[ $status -eq 0 ]
	[ ! -e "${scratch}/project_root" ]
}

@test "destroy executes vagrant destroy" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	echo $@
EOF
	chmod +x "${scratch}/vagrant"

	run env PATH="${scratch}:$PATH" WORKSTATION_HOME="$scratch" workstation destroy --foo
	[ $status -eq 0 ]
	echo "$output" | grep -q "destroy --foo"
}

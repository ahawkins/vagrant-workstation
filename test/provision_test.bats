@test "fails if no WORKSTATION_VAGRANTFILE" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE= workstation provision
	[ $status -eq 1 ]
	echo "$output" | grep -q "WORKSTATION_VAGRANTFILE"
}

@test "fails if WORKSTATION_VAGRANTFILE does not exist" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	[ ! -d "/foo/bar/baz" ]

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE="/foo/bar/baz" workstation provision
	[ $status -eq 1 ]
	echo "$output" | grep -q "WORKSTATION_VAGRANTFILE"
}

@test "provision is executed in correct directory" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	
	if [ "$1" = "provision" ]; then
		echo "provision-${PWD}"
		exit 0
	else
		exit 1
	fi
EOF
	chmod +x "${scratch}/vagrant"

	pushd "$(mktemp -d -t junk)" > /dev/null
	run env PATH="${scratch}:$PATH" workstation provision
	popd > /dev/null

	[ $status -eq 0 ]
	echo "$output" | grep -q "provision-$(dirname "$WORKSTATION_VAGRANTFILE")"
}

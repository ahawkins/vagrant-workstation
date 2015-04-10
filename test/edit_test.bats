#!/usr/bin/env bats

@test "edit fails if no WORKSTATION_VAGRANTFILE" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE= workstation edit
	[ $status -eq 1 ]
	echo "$output" | grep -q "WORKSTATION_VAGRANTFILE"
}

@test "edit fails if WORKSTATION_VAGRANTFILE does not exist" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	[ ! -d "/foo/bar/baz" ]

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE="/foo/bar/baz" workstation edit
	[ $status -eq 1 ]
	echo "$output" | grep -q "WORKSTATION_VAGRANTFILE"
}

@test "edit passes WORKSTATION_VAGRANTFILE to EDITOR" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	cat > "${scratch}/editor" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	echo "${1}-editor"
EOF
	chmod +x "${scratch}/editor"

	touch "${scratch}/Vagrantfile"

	run \
		env \
		PATH="${scratch}:$PATH" \
		EDITOR="${scratch}/editor" \
		WORKSTATION_VAGRANTFILE="${scratch}/Vagrantfile" \
		workstation edit

	[ $status -eq 0 ]
	echo "$output" | grep -q "${scratch}/Vagrantfile-editor"
}

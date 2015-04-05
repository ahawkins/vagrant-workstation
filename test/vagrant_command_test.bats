#!/usr/bin/env bats

@test "fails if no WORKSTATION_VAGRANTFILE" {
	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	exit 1 # This should not be invoked so fail if it does
EOF
	chmod +x "${scratch}/vagrant"

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE= workstation halt
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

	run env PATH="${scratch}:$PATH" WORKSTATION_VAGRANTFILE="/foo/bar/baz" workstation halt
	[ $status -eq 1 ]
	echo "$output" | grep -q "WORKSTATION_VAGRANTFILE"
}

@test "halt is forwaded to vagrant" {
	tmp_bin="$(mktemp -d -t workstation)"
	cat > "${tmp_bin}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	echo $@
EOF
	chmod +x "${tmp_bin}/vagrant"

	run env PATH="${tmp_bin}:$PATH" workstation halt --foo
	[ $status -eq 0 ]
	echo "$output" | grep -q "halt --foo"
}

@test "ssh-config is forwarded to vagrant" {
	tmp_bin="$(mktemp -d -t workstation)"
	cat > "${tmp_bin}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	echo $@
EOF
	chmod +x "${tmp_bin}/vagrant"

	run env PATH="${tmp_bin}:$PATH" workstation ssh-config --foo
	[ $status -eq 0 ]
	echo "$output" | grep -q "ssh-config --foo"
}

@test "ssh is forwarded to vagrant" {
	tmp_bin="$(mktemp -d -t workstation)"
	cat > "${tmp_bin}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	echo $@
EOF
	chmod +x "${tmp_bin}/vagrant"

	run env PATH="${tmp_bin}:$PATH" workstation ssh --foo
	[ $status -eq 0 ]
	echo "$output" | grep -q "ssh --foo"
}

@test "status is forwarded to vagrant" {
	tmp_bin="$(mktemp -d -t workstation)"
	cat > "${tmp_bin}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	echo $@
EOF
	chmod +x "${tmp_bin}/vagrant"

	run env PATH="${tmp_bin}:$PATH" workstation status --foo
	[ $status -eq 0 ]
	echo "$output" | grep -q "status --foo"
}

@test "suspend is forwarded to vagrant" {
	tmp_bin="$(mktemp -d -t workstation)"
	cat > "${tmp_bin}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	echo $@
EOF
	chmod +x "${tmp_bin}/vagrant"

	run env PATH="${tmp_bin}:$PATH" workstation suspend --foo
	[ $status -eq 0 ]
	echo "$output" | grep -q "suspend --foo"
}

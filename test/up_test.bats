@test "up changes to correct directory for vagrant provisioning" {
	scratch_home="$(mktemp -d -t workstation)"

	scratch="$(mktemp -d -t workstation)"
	cat > "${scratch}/vagrant" <<'EOF'
	#!/usr/bin/env bash
	set -eou pipefail
	
	if [ "$1" = "up" ]; then
		echo "up-pwd-${PWD}"
		exit 0
	elif [ "$1" = "ssh-config" ]; then
		echo "fake-ssh-config"
		exit 0
	else
		exit 1
	fi
EOF
	chmod +x "${scratch}/vagrant"

	pushd "$(mkdtemp -d -t workstation)"
	run env PATH="${scratch}:$PATH" WORKSTATION_HOME="$scratch_home" workstation up "$scratch"
	popd

	[ $status -eq 0 ]
	echo "$output" | grep -q "up-pwd-$(dirname "$WORKSTATION_VAGRANTFILE")"
}

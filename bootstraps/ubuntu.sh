#!/bin/sh
set -eu

FSTAB=/etc/fstab
MOUNTRC=/sbin/mount.rc

init () {
	# run scripts at start up
	mount='none none rc defaults 0 0'

	cat $FSTAB | sed "/^$mount$/d" | sudo tee $FSTAB
	echo "$mount" | sudo tee -a $FSTAB

	# add a script file
	cat <<-EOF | sudo tee $MOUNTRC
	#!/bin/sh
	set -eu
	EOF

	sudo chmod +x $MOUNTRC
}

ssh () {
	cat <<-EOF | sudo tee -a $MOUNTRC

	ssh () {
		[ ! -e /etc/ssh/ssh_host_key ] && ssh-keygen -A
		service ssh start
	}
	ssh

	EOF
}

docker () {
	cat <<-EOF | sudo tee -a $MOUNTRC

	docker () {
		mkdir -p /sys/fs/cgroup/systemd
		mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd

		if ! type docker; then
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
			echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
			| tee /etc/apt/sources.list.d/docker.list

			apt update
			apt install -y docker-ce docker-ce-cli containerd.io

			update-alternatives --set iptables /usr/sbin/iptables-legacy
			update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

			sudo usermod -aG docker 1000
		fi

		service docker start
	}
	docker

	EOF
}

init
ssh

### option: install and start docker
# docker

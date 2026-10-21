#!/usr/bin/env bash
# The Chess Plus sims server on AWS (Mac's project, us-east-2): a c7a.16xlarge
# (64 cores) named "chessplus-sims", kept stopped between runs (Mac's choice).
# Its address changes every time it starts, so "start" looks it up and points
# the SSH shortcut "chessplus-sims" (in ~/.ssh/config) at it.
#
#   bash tools/sims_server.sh status         running / stopped, and its address
#   bash tools/sims_server.sh start          start it, wait until it takes SSH
#   bash tools/sims_server.sh stop           stop it (it keeps its disk)
#   bash tools/sims_server.sh ssh <command>  run a command on it
#
# Needs the AWS CLI logged in as profile "chessplus" (aws login --region
# us-east-2 --profile chessplus) and the key ~/.ssh/chessplus-key.pem.
set -euo pipefail

PROFILE=chessplus
NAME=chessplus-sims
# In ~/.ssh/config the key path must have no spaces ("Mac Wood"), so ~ is used.
KEY="~/.ssh/chessplus-key.pem"
GROUP_NAME=chessplus-sims
AWS_EXE="${AWS_EXE:-$(cygpath -u "$LOCALAPPDATA")/Programs/Amazon/AWSCLIV2/aws.exe}"
export PYTHONIOENCODING=utf-8

aws() { "$AWS_EXE" --profile "$PROFILE" --region us-east-2 "$@" | tr -d '\r'; }

instance_id() {
	aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" \
		"Name=instance-state-name,Values=pending,running,stopping,stopped" \
		--query "Reservations[0].Instances[0].InstanceId" --output text
}

state_and_address() {
	aws ec2 describe-instances --instance-ids "$1" \
		--query "Reservations[0].Instances[0].[State.Name,PublicDnsName]" --output text
}

# Let this PC's current internet address in over SSH (home addresses change now
# and then). Old addresses are left; they only ever allow SSH with the key.
allow_my_ip() {
	local ip group
	ip="$(curl -fsS https://checkip.amazonaws.com | tr -d '\r\n ')"
	group="$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$GROUP_NAME" --query "SecurityGroups[0].GroupId" --output text)"
	if ! aws ec2 describe-security-groups --group-ids "$group" \
		--query "SecurityGroups[0].IpPermissions[].IpRanges[].CidrIp" --output text | tr '\t' '\n' | grep -qx "$ip/32"; then
		aws ec2 authorize-security-group-ingress --group-id "$group" \
			--ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$ip/32,Description=Mac}]" >/dev/null
		echo "Allowed SSH from this PC's new address $ip."
	fi
}

# Point the "chessplus-sims" SSH shortcut at the server's current address.
write_ssh_config() {
	local host="$1" config="$HOME/.ssh/config"
	touch "$config"
	sed -i '/^# BEGIN chessplus-sims/,/^# END chessplus-sims/d' "$config"
	cat >> "$config" <<EOF
# BEGIN chessplus-sims (written by tools/sims_server.sh)
Host chessplus-sims
  HostName $host
  User ubuntu
  IdentityFile $KEY
  HostKeyAlias chessplus-sims
  StrictHostKeyChecking accept-new
  ServerAliveInterval 30
# END chessplus-sims
EOF
}

id="$(instance_id)"
if [ -z "$id" ] || [ "$id" = "None" ]; then
	echo "No $NAME server found in us-east-2." >&2
	exit 1
fi

case "${1:-status}" in
	status)
		echo "$id $(state_and_address "$id")"
		;;
	start)
		allow_my_ip
		aws ec2 start-instances --instance-ids "$id" >/dev/null
		aws ec2 wait instance-running --instance-ids "$id"
		read -r state host <<< "$(state_and_address "$id")"
		write_ssh_config "$host"
		for _ in $(seq 1 30); do
			if ssh -o BatchMode=yes -o ConnectTimeout=10 chessplus-sims true 2>/dev/null; then
				echo "$NAME is running at $host (ssh chessplus-sims)."
				exit 0
			fi
			sleep 5
		done
		echo "$NAME is running at $host but doesn't answer SSH yet." >&2
		exit 1
		;;
	stop)
		aws ec2 stop-instances --instance-ids "$id" >/dev/null
		aws ec2 wait instance-stopped --instance-ids "$id"
		echo "$NAME is stopped."
		;;
	ssh)
		shift
		ssh -o BatchMode=yes chessplus-sims "$@"
		;;
	*)
		echo "Usage: bash tools/sims_server.sh status|start|stop|ssh <command>" >&2
		exit 2
		;;
esac

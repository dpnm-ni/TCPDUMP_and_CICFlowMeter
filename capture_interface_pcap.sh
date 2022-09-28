#!/bin/bash

interface=$1
storage_url=$2

output_dir=pcap
rotate_interval=60

[[ "$(grep -c "$interface" /proc/net/dev)" == "0" ]] && echo "The interface is NOT found!" && exit 255
[[ ! -d "$output_dir" ]] && echo "The output directory does NOT exist!" && exit 255

[[ ! -z "${storage_url}" ]] && export STORAGE_URL=$storage_url

# Clean
cleanup() {
	echo "=== Capturer is being cancled ==="
    echo "=== Wait the converter finished for 3 seconds..."
	sleep 3
	echo
	echo "=== Convert left PCAP files if any"
	OIFS="$IFS"
	IFS=$'\n'
	for f in `find "${output_dir}" -type f -name "*.pcap"`; do
		echo "=== $f is left"
		"${post_rotate_command}" "$f"
	done
	IFS="$OIFS"

    echo "=== Clean stuff up"
    rm -f "$output_dir"/*.pcap

	echo
    exit 0
}

trap 'cleanup' INT TERM EXIT

#output_file=${output_dir}/$(date +'%Y-%m-%d-%H:%M:%S.pcap')
output_file_format=${output_dir}/"${HOSTNAME}--%Y-%m-%d--%H-%M-%S.pcap"
options="-n -nn -N -s 0"

# Before the post-rotatation script can be run, please edit an AppArmor configuration file:
#   $ sudo vi /etc/apparmor.d/usr.sbin.tcpdump
# by adding the line:
#   /**/* ixr,
# then
#   $ sudo service apparmor restart
#
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # On the same directory.
post_rotate_script="${script_dir}"/convert_pcap_csv.sh

# FIXME: a better way to pass args to this script? ENV or export do not work
sed -i -E "s|STORAGE_URL=.*|STORAGE_URL=$storage_url|" ${post_rotate_script}

sudo tcpdump ${options} -z "${post_rotate_script}" -i ${interface} -G ${rotate_interval} -w "${output_file_format}"

#sudo chown 1000:1000 "${output_dir}"/*


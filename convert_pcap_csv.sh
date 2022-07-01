#!/bin/bash
set -x
pcap_file="$1"

[[ ! -f "${pcap_file}" ]] && echo "PCAP file ${pcap_file} does NOT exist!" && exit 255

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # On the same directory.
echo ">>> Script dir: ${script_dir}"

output_dir="${script_dir}"/csv
pcap_file_name=$(basename "$pcap_file")
# cicflowmeter add _ISCX to the exported filename
csv_file=${pcap_file_name/.pcap/_ISCX.csv}

# This script is run via tcpdump, where there is no easy way to pass other optional arguments
STORAGE_URL=http://141.223.181.149:8402/cicflowmeter

## Clean
cancel() {
	echo "+++ Converter is being canceled +++"
	echo "+++ The last conversion, ${pcap_file}, is not completed!"
	echo
	exit 0
}
trap 'cancel' INT TERM

cleanup() {
#    echo "+++ Remove ${pcap_file}"
#    rm -f "${pcap_file}"

	echo "+++ Finish the conversion"
	echo
    exit 0
}
trap 'cleanup' EXIT


## Convert
echo "+++ CICFlowMeter PCAP-to-CSV Converter +++"
echo "    Input file: ${pcap_file}"
echo "    Output dir: ${output_dir}"

# CICFlowMeter-3.0/bin/CICFlowMeter
cic="${script_dir}"/CICFlowMeters/CICFlowMeter-3.0/bin/CICFlowMeter
# cic="${script_dir}"/CICFlowMeters/CICFlowMeter-4.0/bin/CICFlowMeter

"${cic}" "${pcap_file}" "${output_dir}"


[[ ! -z "${STORAGE_URL}" ]] && \
	curl -T ${output_dir}/${csv_file} ${STORAGE_URL}/${csv_file} && \
	rm ${output_dir}/${csv_file}

echo "+++ Remove ${pcap_file}"
rm -f "${pcap_file}"




## Rearrange the PCAP due to other CICFlowMeter versions' compatibility
# pcap_dir="${script_dir}"/tmp
# pcap_tmp="${pcap_dir}"/$(basename "${pcap_file}")

#echo "> move ${pcap_file} to ${pcap_tmp}"
#mv "${pcap_file}" "${pcap_dir}"


# CICFlowMeterV2
#cic_dir="${script_dir}"/CICFlowMeters/CICFlowMeterV2
#java -Djava.library.path="${cic_dir}" -jar "${cic_dir}"/CICFlowMeter.jar "${pcap_dir}/" "${output_dir}/2/"

#cic_dir=${HOME}/CICFlowMeterV2
#java -Djava.library.path="${cic_dir}/jnetpcap" -jar "${cic_dir}"/CICFlowMeter.jar "${pcap_dir}/" "${output_dir}/2/"

# CICFlowMeterV3-jnetpcap-1.3
#cic_dir="${script_dir}"/CICFlowMeters/CICFlowMeterV3-jnetpcap-1.3
#java -Djava.library.path="${cic_dir}" -jar "${cic_dir}"/CICFlowMeterV3.jar "${pcap_tmp}" "${output_dir}/3.1.3/"

# CICFlowMeterV3-jnetpcap-1.4
#cic_dir="${script_dir}"/CICFlowMeters/CICFlowMeterV3-jnetpcap-1.4
#java -Djava.library.path="${cic_dir}" -jar "${cic_dir}"/CICFlowMeterV3.jar "${pcap_tmp}" "${output_dir}/3.1.4/"


#echo "+++ remove ${pcap_tmp}"
#rm -f "${pcap_tmp}"



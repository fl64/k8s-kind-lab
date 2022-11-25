hubble-http:
	hubble observe --tls-allow-insecure -f -n echo-cilium -l app=echo  -o jsonpb | \
	jq '.flow |
	  {
			src_labels: .source.labels,
		  src_pod_name: .source.pod_name,
			dst_labels: .destination.labels,
		  dst_pod_name: .destination.pod_name,
			type: .Type,
			l4: .l4.TCP,
		}'

	hubble observe --tls-allow-insecure -f -n echo-cilium -l app=echo  -o jsonpb | \
	jq '.flow |
	  {
		  src_pod_name: .source.pod_name,
		  dst_pod_name: .destination.pod_name,
			type: .Type,
			l4: .l4.TCP,
		}'

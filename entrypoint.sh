#!/bin/sh

cat <<EOF > bucket.yml
type: S3
config:
  bucket: "example-bucket"
  endpoint: "s3.amazonaws.com"
  access_key: "abdce"
  secret_key: "ebcda"
EOF

if [ $THANOS_MODE == "query" ]; then
    /bin/thanos query \
    --http-address=0.0.0.0:9090 \
    --store=thanos-sidecar:10901
    
    elif [ $THANOS_MODE == "store" ]; then
    /bin/thanos store \
    --data-dir=/local/state/data/dir \
    --objstore.config-file=bucket.yml
else
    /bin/thanos sidecar \
    --http-address=0.0.0.0:10902 \
    --grpc-address=0.0.0.0:10901 \
    --tsdb.path=/prometheus \
    --prometheus.url=http://localhost:9090 \
    --objstore.config-file=bucket.yml
fi

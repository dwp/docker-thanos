#!/bin/sh
set -e
echo "INFO: Checking container configuration..."
if [ -z "${THANOS_CONFIG_S3_BUCKET}" -o -z "${THANOS_CONFIG_S3_PREFIX}" ]; then
    echo "ERROR: THANOS_CONFIG_S3_BUCKET and THANOS_CONFIG_S3_PREFIX environment variables must be provided"
    exit 1
fi

S3_URI="s3://${THANOS_CONFIG_S3_BUCKET}/${THANOS_CONFIG_S3_PREFIX}"

# If either of the AWS credentials variables were provided, validate them
if [ -n "${AWS_ACCESS_KEY_ID}${AWS_SECRET_ACCESS_KEY}" ]; then
    if [ -z "${AWS_ACCESS_KEY_ID}" -o -z "${AWS_SECRET_ACCESS_KEY}" ]; then
        echo "ERROR: You must provide both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY variables if you want to use access key based authentication"
        exit 1
    else
        echo "INFO: Using supplied access key for authentication"
    fi
    
    # If either of the ASSUMEROLE variables were provided, validate them and configure a shared credentials fie
    if [ -n "${AWS_ASSUMEROLE_ACCOUNT}${AWS_ASSUMEROLE_ROLE}" ]; then
        if [ -z "${AWS_ASSUMEROLE_ACCOUNT}" -o -z "${AWS_ASSUMEROLE_ROLE}" ]; then
            echo "ERROR: You must provide both the AWS_ASSUMEROLE_ACCOUNT and AWS_ASSUMEROLE_ROLE variables if you want to assume role"
            exit 1
        else
            ASSUME_ROLE="arn:aws:iam::${AWS_ASSUMEROLE_ACCOUNT}:role/${AWS_ASSUMEROLE_ROLE}"
            echo "INFO: Configuring AWS credentials for assuming role to ${ASSUME_ROLE}..."
            mkdir ~/.aws
      cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

[${AWS_ASSUMEROLE_ROLE}]
role_arn=${ASSUME_ROLE}
source_profile=default
EOF
            PROFILE_OPTION="--profile ${AWS_ASSUMEROLE_ROLE}"
        fi
    fi
    if [ -n "${AWS_SESSION_TOKEN}" ]; then
        sed -i -e "/aws_secret_access_key/a aws_session_token=${AWS_SESSION_TOKEN}" ~/.aws/credentials
    fi
else
    echo "INFO: Using attached IAM roles/instance profiles to authenticate with S3 as no AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY have been provided"
fi

if [ -f "/etc/thanos/bucket.yml" ]; then
    echo "Config mounted as Volume from S3"
else
    echo "INFO: Copying prometheus configuration file(s) from ${S3_URI} to /etc/thanos..."
    aws ${PROFILE_OPTION} s3 sync ${S3_URI}/ /etc/thanos/
fi

for HOSTNAME in ${STORE_HOSTNAMES};
do
    STORE_ARGS=${STORE_ARGS}"--store=${HOSTNAME}:10901 ";
done

echo "INFO: Starting thanos..."
if [ ${THANOS_MODE} == "query" ]; then
    /bin/thanos query \
    --store.unhealthy-timeout=1m \
    --http-address="0.0.0.0:9090" \
    --query.lookback-delta=1d \
    ${STORE_ARGS}
    elif [ ${THANOS_MODE} == "store" ]; then
    /bin/thanos store \
    --data-dir="/thanos" \
    --http-address="0.0.0.0:9090" \
    --grpc-address="0.0.0.0:10901" \
    --objstore.config-file="/etc/thanos/bucket.yml"
    elif [ ${THANOS_MODE} == "rule" ]; then
    /bin/thanos rule \
    --rule-file="/etc/thanos/rules/*.rules.yaml" \
    --alert.query-url="http://"${QUERY_URL} \
    --alertmanagers.url="http://"${ALERTMANAGER_URL} \
    --query=${QUERY_URL} \
    --data-dir="/thanos" \
    --objstore.config-file="/etc/thanos/bucket.yml" \
    --http-address="0.0.0.0:9090"
else
    /bin/thanos receive \
    --http-address="0.0.0.0:10902" \
    --grpc-address="0.0.0.0:10901" \
    --remote-write.address="0.0.0.0:10903" \
    --tsdb.path="/prometheus" \
    --objstore.config-file="/etc/thanos/bucket.yml" \
    --tsdb.wal-compression \
    --tsdb.retention=3d \
    --label="receive_env=\"${RECEIVE_ENV}\"" \
    --label="tenant=\"receive_${RECEIVE_ENV}\"" \
    --receive.default-tenant-id="receive_${RECEIVE_ENV}"
fi

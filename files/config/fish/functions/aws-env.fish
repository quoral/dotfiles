function aws-env
  set -gx AWS_ACCESS_KEY_ID (aws configure get aws_access_key_id)
  set -gx AWS_SESSION_TOKEN (aws configure get aws_session_token)
  set -gx AWS_SECRET_ACCESS_KEY (aws configure get aws_secret_access_key)
end

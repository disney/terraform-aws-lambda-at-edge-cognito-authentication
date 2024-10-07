// Mitigation for https://github.com/awslabs/cognito-at-edge/issues/86
// This won't fix all situations but this does seem to help reduce the total amount of 503 errors 
// that occur from cognito-at-edge due to timeouts.
process.env['AWS_NODEJS_CONNECTION_REUSE_ENABLED'] = '1';

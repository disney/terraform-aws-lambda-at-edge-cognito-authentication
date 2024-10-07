const { IAMClient, GetRolePolicyCommand } = require('@aws-sdk/client-iam');
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');
const { STSClient, GetCallerIdentityCommand } = require('@aws-sdk/client-sts');

const NodeCache = require("node-cache");
const { Authenticator } = require('cognito-at-edge');
const { getLogger } = require('./logger');

// Global Static variables
const cacheAuthenticatorKey = "AUTHENTICATOR_OBJECT";
const POLICY_NAME = "SSM_PARAMETER_PERMISSION_FOR_LAMBDA_AUTH";

const cache = new NodeCache({
  stdTTL: 300,
  checkperiod: 150, 
  deleteOnExpire: true,
  useClones: false
});

/**
 * Gets a resource name from a given ARN and resourceType.
 * @param {string} arn ARN to parse
 * @param {string} resourceType Resource type to strip from resource name
 * @returns {string} Resource Name
 */
function getResourceNameFromARN(arn, resourceType) {
  return arn.split(':').pop().replace(`${resourceType}/`, '');
}

/**
 * Gets the execution role name from the given ARN.
 * NOTE: This expects a format similar to the following: arn:aws:sts::<accountNumber>:assumed-role/<my lambda execution role name>/<region>.<lambda function name>
 * DEV NOTE: This is using a combination of array manipulations which is less readable but tested to be more performant than regex lookups.
 * @param {string} arn ARN to parse
 * @returns Role Name from execution arn.
 */
function getRoleNameFromExecutionARN(arn) {
  return arn.split(':').pop().split('/')[1];
}

/**
 * Fetches Configuration from SSM by inspecting the IAM Role to this lambda and finding a preset Role Policy.
 * NOTE: This is a bit of a hacky way, but very much inline with approaches I've found in researching this setup.
 * Once AWS has a more defined or documented way to have easily customizable configurations for a Lambda@Edge, we
 * can probably revisit this setup.
 * @returns {void}
 * @throws {Error} Throws error to cause a 500 if we cannot successful create a new authenticator.
 */
async function createAuthenticatorFromConfiguration() {
  const rootLogger = getLogger();

  try {
    const ssmClient = new SSMClient({ region: 'us-east-1' });
    const stsClient = new STSClient({ region: 'us-east-1' });
    const iamClient = new IAMClient({ region: 'us-east-1' });

    // Get the IAM role that is currently running this lambda.
    rootLogger.info('Attempting to get current execution IAM Role.');
    const curIdentity = await stsClient.send(new GetCallerIdentityCommand({}));
    const iamRole = curIdentity.Arn;
    rootLogger.info(`Running as IAM Role[${iamRole}].`);
    const iamRoleName = getRoleNameFromExecutionARN(iamRole, 'role')

    // Get the predefined policy which references the SSM Parameter we need to pull
    rootLogger.info(`Fetching Policy[${POLICY_NAME}] from IAM Role[${iamRole}].`);
    const { PolicyDocument } = await iamClient.send(new GetRolePolicyCommand({ PolicyName: POLICY_NAME, RoleName: iamRoleName }));
    rootLogger.info('Successfully fetched Policy document.');

    const parsedPolicyDoc = decodeURIComponent(PolicyDocument);
    const referencedPolicy = JSON.parse(parsedPolicyDoc);
    const ssmParameterArn = referencedPolicy.Statement[0].Resource;
    rootLogger.info(`Found SSM Resource[${ssmParameterArn}].`);
    const ssmParameterName = `/${getResourceNameFromARN(ssmParameterArn, 'parameter')}`;
    
    // Fetch the data from parameter store
    rootLogger.info(`Fetching Parameter[${ssmParameterName}].`);
    const { Parameter } = await ssmClient.send(new GetParameterCommand({ Name: ssmParameterName, WithDecryption: true }));
    rootLogger.info(`Successfully fetched Parameter[${ssmParameterName}].`);

    const authConfig = JSON.parse(Parameter.Value);
    rootLogger.info(`Successfully parsed config.`);

    // Initialize Authenticator with the config from parameter store
    const authenticator = new Authenticator(authConfig);
    if (cache.set(cacheAuthenticatorKey, authenticator)) {
      rootLogger.info('Successfully initialized Authenticator.');
    } else {
      throw new Error('Failed to store authenticator in cache.');
    }

    // Force a JWKS Cache hydrate on startup to speed up subsequent calls
    rootLogger.info("Hydrating JWKS Cache.")
    await authenticator.hydrateJwtCache()
    rootLogger.info("Successfully hydrated")

  } catch (err) {
    rootLogger.error('Failed to fetch Authenticator configuration from parameter store!');
    rootLogger.error(err.stack);
    throw new Error('Failed to Authenticate user.');
  }
}

exports.handler = async (request) => {
  let authenticator = cache.get(cacheAuthenticatorKey);

  if (!authenticator) {
    await createAuthenticatorFromConfiguration();
    authenticator = cache.get(cacheAuthenticatorKey);
  }

  return authenticator.handle(request);
};

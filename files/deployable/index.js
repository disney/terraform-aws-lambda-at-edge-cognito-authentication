const { IAMClient, GetRolePolicyCommand } = require('@aws-sdk/client-iam');
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');
const { STSClient, GetCallerIdentityCommand } = require('@aws-sdk/client-sts');

const NodeCache = require("node-cache");
const { Authenticator } = require('cognito-at-edge');
const { getLogger } = require('./logger');

const fs = require('fs');

// Global Static variables
const cacheAuthenticatorKey = "AUTHENTICATOR_OBJECT";
const POLICY_NAME = "SSM_PARAMETER_PERMISSION_FOR_LAMBDA_AUTH";

const cache = new NodeCache({
  stdTTL: 300,
  checkperiod: 150,
  deleteOnExpire: true,
  useClones: false
});

// if you change this, also update local.lambda_config_file in /lambda.tf
const configFile = './config.json';

const rootLogger = getLogger();
/**
 * Gets a resource name from a given ARN and resourceType.
 * @param {string} arn ARN to parse
 * @param {string} resourceType Resource type to strip from resource name
 * @returns {string} Resource Name
 */
function getResourceNameFromARN(arn, resourceType) {
  return arn.split(':').pop().replace(`${resourceType}`, '');
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
 * Inspect the IAM Role of this lambda for a specific attached policy named POLICY_NAME, inspect that policy
 * for the parameter store entry it grants rights to, and return the parameter name of that entry.
 * NOTE: This is a bit of a hacky way, but very much inline with approaches I've found in researching this setup.
 * Once AWS has a more defined or documented way to have easily customizable configurations for a Lambda@Edge, we
 * can probably revisit this setup.
 * @returns {string} Parameter Name that contains the configuration for this lambda.
 */
async function introspectConfigParameterName() {
  const stsClient = new STSClient({ region: 'us-east-1' });
  const iamClient = new IAMClient({ region: 'us-east-1' });

  // Get the IAM role the lambda is running under.
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
  return getResourceNameFromARN(ssmParameterArn, 'parameter');
}

/**
 * Fetch the lambda config from the local file system or SSM and use it to initialise a 
 * cognito-at-edge Authenticator object
 * @returns {void}
 * @throws {Error} Throws error to cause a 500 if we cannot successful create a new authenticator.
 */
async function createAuthenticatorFromConfiguration() {
  let authConfig;
  let ssmParameterName;

  try {
    // if terraform was configured with lambda_config_mode = 'dynamic' then configFile will not exist
    // in the local file system, so introspect the IAM role to get the name of the SSM parameter that
    // contains the config
    if (!fs.existsSync(configFile)) {
      ssmParameterName = await introspectConfigParameterName();
      rootLogger.info(`Successfully introspected ssmParameterName from IAM [${ssmParameterName}].`);
    }
    // otherwise there is a local configFile, parse it into authConfig.  If terraform was configured
    // with lambda_config_mode = 'static' this will be the full config.
    else {
      authConfig = JSON.parse(fs.readFileSync(configFile, 'utf8'));
      rootLogger.info(`Successfully read local configFile [${configFile}].`);

      // if terraform was configured with lambda_config_mode = 'hybrid' then authConfig will contain
      // a single key 'parameterName'.  If this key exists, set ssmParameterName to its value.
      if (authConfig.parameterName) {
        ssmParameterName = authConfig.parameterName
        rootLogger.info(`Found parameterName in local configFile [${ssmParameterName}].`);
      }
    }

    // if ssmParameterName is defined, fetch the value from parameter store as the config
    if (ssmParameterName) {
      rootLogger.info(`Fetching Parameter from SSM [${ssmParameterName}].`);
      const ssmClient = new SSMClient({ region: 'us-east-1' });
      const { Parameter } = await ssmClient.send(new GetParameterCommand({ Name: ssmParameterName, WithDecryption: true }));
      authConfig = JSON.parse(Parameter.Value);
      rootLogger.info(`Successfully parsed config from SSM entry [${ssmParameterName}].`);
    }

    // Initialize Authenticator with the config from parameter store/local file
    const authenticator = new Authenticator(authConfig);
    if (cache.set(cacheAuthenticatorKey, authenticator)) {
      rootLogger.info('Successfully initialized Authenticator.');
    } else {
      throw new Error('Failed to store authenticator in cache.');
    }

  } catch (err) {
    rootLogger.error('Failed to find valid Authenticator config!');
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

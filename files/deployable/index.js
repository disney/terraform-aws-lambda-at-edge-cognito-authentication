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

/**
 * terraform writes the name of the SSM parameter into a local config.json file, which is deployed with
 * this lambda code.  When invoked, this code interrogates the parameter name from the config.json
 * file, fetches it from SSM in us-east-1, and uses it as the config for cognito-at-edge.
 * @returns {void}
 * @throws {Error} Throws error to cause a 500 if we cannot successful create a new authenticator.
 */
async function createAuthenticatorFromConfiguration() {
  const rootLogger = getLogger();

  try {
    const ssmClient = new SSMClient({ region: 'us-east-1' });

    // interrogates the ${configFile} file for the name of the SSM parameter
    const lambdaConfig = JSON.parse(fs.readFileSync(configFile, 'utf8'));
    rootLogger.info(`Successfully read local ${configFile} file.`);
    const ssmParameterName = lambdaConfig.parameterName;

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

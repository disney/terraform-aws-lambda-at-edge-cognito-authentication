# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.1.0] - 2022-03-16
### Changed
- Updated `aws-sdk` version for Lambda@Edge deployable to `2.1094.0` (was `2.952.0`).
- Updated `axios` version for Lambda@Edge deployable to `0.26.1` (was `0.21.4`).
- Updated `cognito-at-edge` version for Lambda@Edge deployable to `1.2.1` (was `1.1.0`).
- Updated `pino` version for Lambda@Edge deployable to `7.8.1` (was `6.13.1`).

## [4.0.0] - 2022-03-01
**BREAKING CHANGE**

### Changed
- Drop support for AWS Terraform Provider `3.0`. Minimum required provider version is now `~ 4.0`.

## [3.0.0] - 2021-10-28
**BREAKING CHANGES**

### Added
- Added official [cognito-at-edge](https://github.com/awslabs/cognito-at-edge) package that Amazon maintains.

### Removed
- Removed forked cognito@edge Authenticator.js
  - This drops support for the following features:
    -  `redirectPath`
    -  `scopes`
    -  `cookiePath`
- Removed variable `cognito_user_pool_app_client_callback_url` as the official package does not support this.

## [2.0.0] - 2021-09-24
**BREAKING CHANGES**

### Added
- Added SSM Parameter to store Lambda@Edge configuration
- Added KMS key to encrypt SSM Parameter.

### Changed
- Refactored authentication lambda and how configuration is managed within terraform.
  - Lambda configuration is no longer inlined within an index.js template file and instead uses SSM Parameter Store.
  - This overall should reduce the time required for deployments on configuration updates since CloudFront won't need to be redeployed.

### Removed
- `index.js.tpl` file as it is no longer required.

### Fixed
- Fixed constant churn on lambda updates due to usage of `source_code_hash` on lambda resource.
  - More information here: https://github.com/hashicorp/terraform-provider-aws/issues/7385

## [1.0.0] - 2021-09-07
### Added
- Initial addition of the Terraform Lambda@Edge Cognito Authentication module.

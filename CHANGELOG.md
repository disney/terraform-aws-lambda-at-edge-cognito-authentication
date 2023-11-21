# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - TBD

### Added
- Added support for Cognito custom user pool domains via new variable `cognito_user_pool_domain`.
- Added support for custom redirect endpoint for Cognito@Edge via new variable `cognito_redirect_path`.
- Added support for additional Cognito@Edge settings via new variable `cognito_additional_settings`.

### Changed
- Expand TF AWS provider range to allow support for `5.0.0` and greater.
- Update Lambda@Edge NodeJS version to `nodejs20.x` (was `nodejs14.x`) and make it user configurable via new variable `lambda_runtime`.
- Lambda@Edge lambda zip is now bundled via `esbuild` to reduce package size.
- Change default lambda timeout to `5` seconds (was `3` seconds) and make it user configurable via new variable `lambda_timeout`.
- Remove `aws-sdk` in favor of `@aws-sdk` v3 libraries.

## [1.0.1] - 2022-06-22

### Changed
- Updated Lambda Dependency `cognito-at-edge` to `1.2.2` (was `1.2.1`).
- Updated Lambda Dependency `axios` to `0.27.2` (was `0.26.1`).
- Updated Lambda Dev Dependency `aws-sdk` to `2.1159.0` (was `2.1094.0`).

## [1.0.0] - 2022-06-21

### Added
- Initial Open Source Release

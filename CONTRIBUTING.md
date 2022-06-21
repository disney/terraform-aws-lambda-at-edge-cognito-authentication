# How To Contribute
We'd love to accept your patches and contributions to this project. There are just a few guidelines you need to follow which are described in detail below.

## Fork this repo
You should create a fork of this project in your account and work from there. You can create a fork by clicking the fork button in GitHub.

## One feature, one branch
Work for each new feature/issue should occur in its own branch. To create a new branch from the command line:

```
git checkout -b my-new-feature
```

where "my-new-feature" describes what you're working on.

## Changelog Updates
Our CHANGELOG.md drives our versioning for this project, so please ensure that you update the file accordingly and ensure that you adhere to proper [semantic versioning](https://semver.org/spec/v2.0.0.html) when updating the version.

All new versions should adhere to this template:
```
## [0.0.0] - YYYY-MM-DD
### Added
- What functionality was added.
- [ISSUE-01](Link To My Issue) - Functionality was added.

### Changed
- What functionality was changed.

### Fixed
- What functionality was fixed.

### Removed
- What functionality was removed.

```

## Local Development
The easiest way to get a version of terraform locally is to utilize the open source project [tfenv](https://github.com/tfutils/tfenv) which is a version
manager for handling multiple versions of terraform. Once installed you can quickly get started on working within this repository by running the following
shell commands:

```
# Install the Terraform version noted in .terraform-version
tfenv install

# Use the Terraform version noted in .terraform-version
tfenv use
```

---

## Formatting
Ensure that you are running `terraform fmt` before opening up a merge request from your fork. There is no hard CI requirement around this currently,
but this will be added in future releases.

---

## Validating
You can validate a given terraform module by running the following commands locally:

```
# This will initialize your terraform module w/o having to setup a full backend state store.
terraform init -backend=false
terraform validate
```

If your changes to the terraform module are invalid, the validate call will note where those invalid issue are.

---

## Testing
To test your changes, create a secondary repository that matches the Terraform deployment you are attempting to run. Push the changes
to your fork, and reference them within your Terraform Deployment like so:

```
module "cognito_auth" {
  source = "git::https://github.com/<my fork>/terraform-aws-lambda-at-edge-cognito-authentication.git?ref=<my_version_ref>"
 
  name                                      = "my_foo_app""
  cognito_user_pool_name                    = data.aws_cognito_user_pools.my_user_pool.name
  cognito_user_pool_region                  = "us-east-1"
  cognito_user_pool_id                      = aws_cognito_user_pool_client.my_user_pool_client.user_pool_id
  cognito_user_pool_app_client_id           = aws_cognito_user_pool_client.my_user_pool_client.id
  cognito_user_pool_app_client_callback_url = "/saml/consume"

  tags = { foo = "bar" }
}
```

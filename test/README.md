# Tests

This directory contains automated tests for this Terraform Module. All of the tests are written in [Go](https://golang.org/). 
Most of these tests deploy real infrastructure using Terraform and verify that infrastructure 
works as expected using a helper library called [Terratest](https://github.com/gruntwork-io/terratest).



## WARNING: These tests can generate costs!

**Note #1**: Many of these tests create real resources in your AWS account and then try to clean those resources up at
the end of a test run. That means these tests may cost you money to run! When something goes wrong with the tests make
sure to check for resources that were not deleted.

**Note #2**: Never forcefully shut the tests down (e.g. by hitting `CTRL + C`) or the resources will not be deleted!

**Note #3**: The tests run with `-timeout 60m` not because they take that long, but because Go has a
default test timeout of 10 minutes, after which it forcefully kills the tests with a `SIGQUIT`. 
With the long timeout all tests have enough time to finish and and to clean up.


## Running the tests

### Prerequisites

- Install the latest version of [Go](https://golang.org/).
- Install [Terraform](https://www.terraform.io/downloads.html).
- Configure your AWS credentials using one of the [options supported by the AWS 
  SDK](http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html). Usually, the easiest option is to
  set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.


### One-time setup

Download Go dependencies:

```
cd test
go mod download
```


### Run all the tests

```bash
cd test
go test -v -timeout 60m
```


### Run a specific test

To run a specific test called `TestMe`:

```bash
cd test
go test -v -timeout 60m -run TestMe
```

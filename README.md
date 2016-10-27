# Testing commands
The steps below explain how to build, run and develop a set of tests.

## Requirement
- Docker

## Build from source

### Docker
```bash
cd swift-tests
docker build --tag swift-tests .
```

### Vagrant
If the host OS of your VM is Windows, you have to compile the application outside the mounted folder `swift-tests`, run:
```bash
cd swift-tests

# compile.sh copy your swift-tests folder to /tmp/swift-tests and run swift build from there
./compile.sh
```

## Run
To run the tests:
```bash
./run.sh --tests <tests file> --template <template file>
```

## Write your own tests
The tests source file is written in YAML and it's composed by multiple YAML objects: one for each test.
Each test object has multiple fields:
```yaml
# Required
# used to identify a subset of tests
label: string

# Optional, if not set is equals to label
# should describe the tested command
name: string

# Optional
# one or more commands to run before the tested commands
pre: string or array of strings

# Required
# the command to be tested
command: string

# Optional
# one or more commands to run after the tested commands
post: string or array of strings

# Required
# describe the expected result if the command is working
# possible formats:
#   exit code (equals|greater than|less than|greater than or equals|less than or equals) ([0-9]+)
#   output (equals|contains|doesn't contain) '([^']+)'
#
# it's possible to concatenate multiple formats with ' and '
expect: string

# Optional
# add more info to the test, max 2 elements
notes: string or array of strings

# Optional
# if true, skip this test
skip: boolean
```

For example:
```yaml
---
label: kubectl
command: kubectl
expect: exit code equals 0
notes: Local only
skip: true
---
label: kubectl attach
pre:
  - kubectl create -f Resources/test_pod.yaml
  - sleep 5
command: kubectl attach kubectl-web-test
post: kubectl delete --now=true -f Resources/test_pod.yaml
expect: exit code equals 0
notes: Must work
```

## Write your own tests report template
After running the tests the application generate a report of the results.
The only type of template available is the `MarkdownTemplate`.

The report is generated reading the template one line at a time and replacing the following keywords with the corresponding values.
The available keywords are:
```bash
# General keywords
EMPTY_LINE # New line, should be used to mark empty lines
TODAY_DATE # The current date
KUBECTL_VERSION # Kubectl version
KUBECTL_PLATFORM # Kubectl platform
STATUS_SUCCESS # The string representing the result of a successful test
STATUS_FAILED # The string representing the result of a failed test
STATUS_NOTTESTED # The string representing the result of a skipped test
STATUS_UNKOWN # The string representing the result of a malformed test

# Test-specific keywords
STATUS # The string representing the result of a test
COMMAND # The name of the test
CMD_LABEL # The label of the test
RAW_CMD # The tested command
EXPECTED # The string that describe the expected result
NOTES # The notes of the test, if notes is an array the lines are joined with a newline character
NOTE1 # If notes is an array, this is the first element (otherwise it's the same of NOTES)
NOTE2 # If notes is an array, this is the second element (otherwise it's an empty string)
RAW_OUTPUT # The stdout of the test
RAW_ERROR # The stderr of the test
EXIT_CODE # The exit code of the test
REL_URL # Relative URL to another point of the document where the test is found
REL_LABEL # Relative URL to another point of the document where the test label is found

# Special keywords
BEGIN # Begin a multiline block, once for each tests
BEGIN_GROUP # Begin a multiline block, once for each label
END # End a multiline block
```

If one of the `test-specific` keywords is found that line is generated one time for each test.
To prevent this you can wrap multiple line with `test-specific` keywords between a `BEGIN`/`END` block, the block is generated one time for each test.

An example of Markdown template could be:

    # Kubectl KUBECTL_VERSION (KUBECTL_PLATFORM)
    EMPTY_LINE
    ## Legend:
    - STATUS_SUCCESS Command is supported
    - STATUS_FAILED Command is not supported
    - STATUS_NOTTESTED Command not tested
    EMPTY_LINE
    ## Summary:
    EMPTY_LINE
    | :dart: |  :book: Commands   | :memo: Notes |
    | ------ | ------------------ | ------------ |
    | STATUS | [COMMAND](REL_URL) |     NOTES    |
    EMPTY_LINE
    ## Full log:
    *Only tested commands are showed.*
    EMPTY_LINE
    BEGIN
    ### COMMAND
    - Command: `RAW_CMD`
    - Expected result: `EXPECTED`
    - Exit code: `EXIT_CODE`
    EMPTY_LINE
    #### Output:
    ```
    RAW_OUTPUT
    ```
    #### Error:
    ```
    RAW_ERROR
    ```
    [:arrow_up:](#summary)
    ---
    END
    EMPTY_LINE
    *Generated automatically on TODAY_DATE*
    EMPTY_LINE

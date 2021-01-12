# autograder

This repository is used for autograding provided by GitHub Classroom.

## Usage

### Initial setup

Clone all assignment templates.

```shell
$ ./scripts/setup.sh
```

### Synchronize `runtest.sh`

```
$ ./scripts/sync.sh
```

## About `runtest.sh`

```
runtest.sh is a tool for autograding

Usage:
    runtest.sh [<options>]

    - To ignore executing JUnit test, put '.junit_ignore' to the exercise directory
    - To ignore checking if screenshots exist, put '.screenshot_ignore' to the figure/ directory

Options:
       --debug         execute as debug mode
    -h,--help          print this
```

## If you create an assignment template from scratch

- Place `runtest.sh`, `opt/`, and other jar files on the assignment template root.
- Set up the autograding in the admin page of GitHub Classroom.
  - Need to run `./runtest.sh` when executing auto grading.
  - See [the manual](https://docs.github.com/en/free-pro-team@latest/education/manage-coursework-with-github-classroom/use-autograding)

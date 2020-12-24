#!/bin/bash
set -Bu

JUNIT4=junit-4.13.1.jar
HAMCREST=hamcrest-core-1.3.jar
HTDCV6=htdc-v6.jar

JUNIT_FLG=true
SCORE=0
TOTAL=0

STATUS=0

# arguments:
# - dir: assignment directory
exec_javac() {
  dir=$1
  javac -encoding utf8 -cp .:../${JUNIT4}:../${HAMCREST}:../${HTDCV6} "$dir/*.java"
}

exec_junit() {
  target=$1
  java -cp .:../${JUNIT4}:../${HAMCREST}:../${HTDCV6} org.junit.runner.JUnitCore "${target}"
}

# convert to utf8 by using nkf
convert_to_utf8() {
  files=$(find src -name '*.java')
  for f in $files; do
    ./opt/bin/nkf -w --overwrite "${f}"
  done
}

# count up SCORE
# globals:
# - SCORE
score_up() {
  SCORE=$(expr $SCORE + 1)
}

# calculate total score
calc_score_total() {
  exercises=$(find src -mindepth 1 -type d | wc -l)
  checkpoints=$(expr $exercises \* 3) # if JUnit test cases are required
  TOTAL=$(expr $checkpoints + 1)
}

calc_score_total_wo_junit() {
  exercises=$(find src -mindepth 1 -type d | wc -l)
  checkpoints=$(expr $exercises \* 2) # if JUnit test cases are not required
  TOTAL=$(expr $checkpoints + 1)
}

# Check if figure/class-diagram.jpg exists
check_class_diagram() {
  diagram=figure/class-diagram.jpg
  if test -f $diagram; then
    echo "[SUCCESS] $diagram exists"
    score_up
  else
    echo "[ERROR] $diagram not exists"
    STATUS=1
  fi
}

# Check if XXXExample.class or XXXExamples.class exists
# globals:
# - STATUS: if it fails to execute, set STATUS to 1
# arguments:
# - dir: Directory name of the assignment (e.g., ex01)
check_examples() {
  dir=$1
  EXAMPLES=$(find "${dir}" -name "*Example*.class")

  if [ -z "${EXAMPLES}" ]; then
    echo "[ERROR] class XXXExamples for ${dir} is not compiled to .class successfully"
    STATUS=1
  else
    echo "[SUCCESS] class XXXExamples for ${dir} is compiled to .class successfully"
    score_up
  fi
}

# globals:
# - STATUS: if it fails to execute, set STATUS to 1
# arguments:
# - dir: Directory name of the assignment (e.g., ex01)
check_compile() {
  dir=$1

  nums_java_src=$(find $dir -name '*.java' -type f | wc -l)
  if [[ ${nums_java_src} -eq 1 ]]; then
    name_java_src=$(find "$dir" -name '*.java' -type f | xargs basename)
    if [[ "${name_java_src}" == "package-info.java" ]]; then
      echo "[ERROR] no implemented Java source in $dir"
      STATUS=1
    fi
  else
    exec_javac $dir
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
      echo "[ERROR] $dir compilation failed"
      STATUS=1
    else
      echo "[SUCCESS] $dir compilation succeeded"
      score_up
    fi
  fi
}

# arguments
# - dir: assignment directory
check_junit() {
  dir=$1
  logfile=junit_res_${dir}.txt
  junit_status=0

  examples=$(find "${dir}" -name '*Examples.class' -type f | xargs -L1 -I{} basename "{}")

  if [[ -n ${examples} ]]; then
    for example in ${examples}; do
      echo "[TEST] executing JUnit test in ${example}..."
      target="${example%.*}"
      exec_junit $dir.$target > ${logfile}
      junit_out=$(cat "${logfile}" | grep "^FAILURES!!!$")
      if test -z "$junit_out"; then
        echo "[SUCCESS] JUnit tests in ${example} passed."
      else
        echo "[ERROR] JUnit tests in ${example} failed."
        cat "${logfile}"
        junit_status=1
      fi
      rm -f "${logfile}"
    done

    if (( $junit_status==0 )); then
      score_up
    fi
  fi

  rm -f "${logfile}"
}

clean() {
  rm -f src/**/*.class
  rm -f src/junit_res_*.txt
}

do_test() {
  clean && convert_to_utf8
  check_class_diagram

  cd src || exit
  for dir in $(find . -maxdepth 1 -name 'ex*' -type d | sed -e "s/^\.\///g"); do
    check_compile "${dir}"
    check_examples "${dir}"
    if [[ $JUNIT_FLG == "true" ]]; then
      check_junit "${dir}"
    fi
  done
  cd ..

  echo "[SCORE] $SCORE / $TOTAL"

  exit ${STATUS}
}

usage() {
  cat <<EOF
$(basename "${0}") in a tool for autograding

CHANGELOG:
    - Updated on December 24

Usage:
    $(basename "${0}") [<options>]

Options:
    --no-junit      do not run junit test cases
    --debug         execute as debug mode
    --help, -h      print this
EOF
}

# Main
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --no-junit) JUNIT_FLG=false; shift;;
    --debug) set -x; shift ;;
    -h|--help) usage; exit 1 ;;
    *)  echo "Unkown parameter passed: $1"; usage; exit 1 ;;
  esac
  shift
done

# Calculate the total score
if [[ $JUNIT_FLG == "true" ]]; then
  calc_score_total
elif [[ $JUNIT_FLG == "false" ]]; then
  calc_score_total_wo_junit
else
  echo "Unknown parameter passed to JUNIT_FLG: $JUNIT_FLG"; exit 1
fi

do_test
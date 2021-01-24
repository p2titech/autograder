#!/bin/bash
set -Bu

JUNIT4=junit-4.13.1.jar
HAMCREST=hamcrest-core-1.3.jar
HTDCV6=htdc-v6.jar

SCORE=0
TOTAL=0

STATUS=0

exists_junit_ignore() {
  dir=$1
  test -f "$dir/.junit_ignore"
}

exists_screenshot_ignore() {
  dir=$1
  test -f "$dir/.screenshot_ignore"
}

exists_jar() {
  for jar in "${JUNIT4}" "${HAMCREST}" "${HTDCV6}"; do
    if [[ ! -f ../"${jar}" ]]; then
      echo "${jar} not found" && exit 1
    fi
  done
}

# arguments:
# - dir: assignment directory
exec_javac() {
  dir=$1
  exists_jar && \
    javac -encoding utf8 -cp .:../${JUNIT4}:../${HAMCREST}:../${HTDCV6} $dir/*.java
}

exec_junit() {
  target=$1
  exists_jar && \
    java -cp .:../${JUNIT4}:../${HAMCREST}:../${HTDCV6} org.junit.runner.JUnitCore ${target}
}

# convert to utf8 by using nkf
convert_to_utf8() {
  files=$(find src -name '*.java')
  for f in $files; do
    ./opt/bin/nkf -w --overwrite ${f}
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
  # - compilation is successful +1
  # - XXXExamples is defined +1
  # - junit test cases can be run +1
  checkpoints=$(expr $exercises \* 3)
  # reduce the points for the exercise that don't need to execute JUnit test
  junit_ignored=$(find src -name ".junit_ignore" -type f | wc -l)
  checkpoints=$(expr $checkpoints - ${junit_ignored})

  if ! exists_screenshot_ignore "figure"; then
    # - figure/class-diagram.jpg exists + 1
    # - figure/ufo-draw.jpg exists + 1
    TOTAL=$(expr $checkpoints + 2)
  else
    # - figure/class-diagram.jpg exists + 1
    TOTAL=$(expr $checkpoints + 1)
  fi
}


# Check if figure/class-diagram.jpg exists
check_class_diagram() {
  DIAGRAM=$(find figure/ -name "class-diagram*.jpg" -type f)
  if test ! -z "${DIAGRAM}"; then
    echo "[SUCCESS] class diagrams exist"
    score_up
  else
    echo "[ERROR] class diagrams not exist"
    STATUS=1
  fi
}

check_screenshot() {
  FIGS=$(find figure/ -name "ufo-draw*" -type f)
  if test ! -z "${FIGS}"; then
    echo "[SUCCESS] screenshots exist"
    score_up
  else
    echo "[ERROR] screenshots not exist"
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
  EXAMPLES=$(find ${dir} -name *Examples.class)

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
    name_java_src=$(find $dir -name '*.java' -type f | xargs basename)
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
      exec_junit "$dir.$target" > "${logfile}"
      junit_out=$(grep "^FAILURES!!!$" < "${logfile}")
      if test -z "$junit_out"; then
        echo "[SUCCESS] JUnit tests in ${example} passed."
      else
        echo "[ERROR] JUnit tests in ${example} failed."
        cat "${logfile}"
        junit_status=1
        STATUS=1
      fi
    done

    if (( junit_status==0 )); then
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
  clean && convert_to_utf8 && calc_score_total

  check_class_diagram

  exists_screenshot_ignore "figure/" || check_screenshot

  cd src || exit 1
  for dir in $(find . -maxdepth 1 -name 'ex*' -type d | sed -e "s/^\.\///g"); do
    check_compile "${dir}"
    check_examples "${dir}"
    if ! exists_junit_ignore "${dir}"; then
      check_junit "${dir}"
    fi
  done
  cd ..

  echo "[SCORE] $SCORE / $TOTAL"

  exit ${STATUS}
}

usage() {
  cat <<EOF
$(basename ${0}) is a tool for autograding

Usage:
    $(basename ${0}) [<options>]

    - To ignore executing JUnit test, put '.junit_ignore' to the exercise directory
    - To ignore checking if screenshots exist, put '.screenshot_ignore' to the figure/ directory

Options:
       --debug         execute as debug mode
    -h,--help          print this
EOF
}

# Main
while [[ "$#" -gt 0 ]]; do
  key=$1
  shift
  case $key in
    --debug)
      set -x
      shift
      ;;
    -h|--help)
      usage
      exit 1 ;;
    *)  echo "Unkown parameter passed: $1"; usage; exit 1 ;;
  esac
done

do_test

#!/bin/bash

output_help() {
	echo "man versionutil"
}

validate_minor() {
	VALIDATE_NEW_MINOR="$1"
	validate_minor_regex="^([0-9]*)|~?$"
	if [[ "$VALIDATE_NEW_MINOR" =~ $validate_minor_regex ]]; then
		:
	else
		if [ "$DEBUG" ]; then
			echo "XL2 Invalid version format"
		else
			echo "Invalid version format"
		fi
		exit 1
	fi
}

validate_patch() {
	VALIDATE_NEW_PATCH="$1"
	validate_patch_regex="^([0-9]*)|~?$"
	if [[ "$VALIDATE_NEW_PATCH" =~ $validate_patch_regex ]]; then
		:
	else
		if [ "$DEBUG" ]; then
			echo "F9I Invalid version format"
		else
			echo "Invalid version format"
		fi
		exit 1
	fi
}

validate_tag() {
	VALIDATE_TAG="$1"
	if [ "$VALIDATE_TAG" ]; then
		validate_tag_regex="^[-|+][a-zA-Z0-9]*$"
		if [[ "$VALIDATE_TAG" =~ $validate_tag_regex ]]; then
			:
		else
			if [ "$DEBUG" ]; then
				echo "H58 Invalid version format"
			else
				echo "Invalid version format"
			fi
			exit 1	
		fi
	fi
}

getForce() {
	if [ -z "$1" ]; then
		echo ''
		return
	fi
	force=''
	force_version=$1
	force_regex="^(!)?"
	if [[ $force_version =~ $force_regex ]]; then
		force_version="${BASH_REMATCH[1]}"
	fi
	echo $force_version
}

getMajor() {
	if [ -z "$1" ]; then
		echo ''
		return
	fi
	major_major=''
	major_version=$1
	major_regex="^(!)?([0-9]*|~?)"
	if [[ $major_version =~ $major_regex ]]; then
		major_major="${BASH_REMATCH[2]}"
	fi
	echo $major_major
}

getMinor() {
	if [ -z "$1" ]; then
		echo ''
		return
	fi
	minor_minor=''
	minor_version=$1
	minor_regex="^(!)?([0-9]*|~?)\.([0-9]*|~?)"
	if [[ $minor_version =~ $minor_regex ]]; then
		minor_minor="${BASH_REMATCH[3]}"
	fi
	echo $minor_minor
}

getPatch() {
	if [ -z "$1" ]; then
		echo ''
		return
	fi
	patch_patch=''
	patch_version=$1
	if [ "$FORMAT" = "long" ]; then
		patch_regex="^(!)?([0-9]*|~?)\.([0-9]*|~?)\.([0-9]*|~?)"
		if [[ $patch_version =~ $patch_regex ]]; then
			patch_patch="${BASH_REMATCH[4]}"
			echo $patch_patch
		fi
	elif [ "$FORMAT" = "short" ]; then
		echo ""
	fi
}

getTag() {
	if [ -z "$1" ]; then
		echo ''
		return
	fi
	tag_tag=''
	tag_version=$1
	if [ "$FORMAT" = "long" ]; then
		tag_regex="^(!)?([0-9]*|~?)\.([0-9]*|~?)\.([0-9]*|~?)([-+:0-9a-zA-Z]*)?"
		if [[ $tag_version =~ $tag_regex ]]; then
			tag_tag="${BASH_REMATCH[5]}"
		fi
	elif [ "$FORMAT" = "short" ]; then
		tag_regex="^(!)?([0-9]*|~?)\.([0-9]*|~?)([-+:0-9a-zA-Z]*)?"
		if [[ $tag_version =~ $tag_regex ]]; then
			tag_tag="${BASH_REMATCH[4]}"
		fi
	fi
	echo $tag_tag
}

compare() {
	compare=$1
	left_major=$2
	left_minor=$3
	left_patch=$4
	right_major=$5
	right_minor=$6
	right_patch=$7
	if [ "$compare" = "compare" ]; then
		if [ $FORMAT = "long" ]; then
			if [ "$left_major" = "$right_major" ] && [ "$left_minor" = "$right_minor" ] && [ "$left_patch" = "$right_patch" ]; then
				echo "eq"
				return
			fi
		elif [ "$FORMAT" = "short" ]; then
			if [ "$left_major" = "$right_major" ] && [ "$left_minor" = "$right_minor" ]; then
				echo "eq"
				return
			fi
		fi
		if (( $left_major > $right_major )); then
			echo "gt"
			return
		fi
		if (( $left_minor > $right_minor )); then
			echo "gt"
			return
		fi
		if [ "$FORMAT" = "long" ]; then
			if (( $left_patch > $right_patch )); then
				echo "gt"
				return
			fi
		fi
		echo "lt"
		return
	fi

	if [ "$compare" = "lt" ]; then
		if (( "$right_major" < "$left_major" )); then
			echo "false"
			return
		fi
		if (( "$right_minor" < "$left_minor" )); then
			echo "false"
			return
		fi
		if [ "$FORMAT" = "long" ]; then
			if (( "$right_patch" < "$left_patch" )); then
				echo "false"
				return
			fi
		fi
		echo "true"
		return
	fi

	if [ "$compare" = "gt" ]; then
		if (( "$right_major" > "$left_major" )); then
			echo "false"
			return
		fi
		if (( "$right_minor" > "$left_minor" )); then
			echo "false"
			return
		fi
		if [ "$FORMAT" = "long" ]; then
			if (( "$right_patch" > "$left_patch" )); then
				echo "false"
				return
			fi
		fi
		echo "true"
		return
	fi

	if [ "$compare" = "eq" ]; then
		if [ "$FORMAT" = "long" ]; then
			if [ "$left_major" = "$right_major" ] && [ "$left_minor" = "$right_minor" ] && [ "$left_patch" = "$right_patch" ]; then
				echo "true"
				return
			fi
		elif [ "$FORMAT" = "short" ]; then
			if [ "$left_major" = "$right_major" ] && [ "$left_minor" = "$right_minor" ]; then
				echo "true"
				return
			fi
		fi
		
		echo "false"
	fi
}

assert() {
	echo "assert $1 == $2"
	if [ "$1" != "$2" ]; then
		echo "Assert fail $1 != $2"
		exit 1
	fi
}

echo_test() {
	if [ "$TEST_DEBUG" = 'true' ]; then
		echo "$1"
	fi
}

#set default vars
HELP=false
INC_MAJOR=false
INC_MINOR=false
INC_PATCH=false
PRINT_MAJOR=false
PRINT_MINOR=false
PRINT_PATCH=false
PRINT_TAG=false
COMPARE=''
COMPARE_WITH=''
export FORMAT=''
export DEBUG=''
export TEST_DEBUG=''

#parse args
for i in "$@"
do
	case "$i" in
	+major|^major)
		INC_MAJOR=true
		;;
	+minor|^minor)
		INC_MINOR=true
		;;
	+patch|^patch)
		INC_PATCH=true
		;;
	--print-major)
		PRINT_MAJOR=true
		;;
	--print-minor)
		PRINT_MINOR=true
		;;
	--print-patch)
		PRINT_PATCH=true
		;;
	--print-tag)
		PRINT_TAG=true
		;;
	--lt)
		COMPARE='lt'
		COMPARE_WITH=$3
		;;
	--gt)
		COMPARE='gt'
		COMPARE_WITH=$3
		;;
	--eq)
		COMPARE='eq'
		COMPARE_WITH=$3
		;;
	--compare)
		COMPARE='compare'
		COMPARE_WITH=$3
		;;
	--debug)
		export DEBUG=true
		;;
	--test-debug)
		export TEST_DEBUG=true
		;;
	-h|--help)
		output_help
		exit 0
		;;
	esac
done

#check for tests
if [ "$1" = '--tests' ] || [ "$1" = '--test' ]; then
	
	## Test output that is expected to fail

	echo_test "FXO"
	output=$($0 "1")
	assert "$output" "Invalid version format"

	echo_test "FXN"
	output=$($0 "1.")
	assert "$output" "Invalid version format"

	echo_test "09FG"
	output=$($0 "1.2.")
	assert "$output" "Invalid version format"

	echo_test "D0L"
	output=$($0 "!~.~.~.129AFD" +patch)
	assert "$output" "Invalid version format"

	echo_test "F45"
	output=$($0 "1.1.1.129AFD" +patch)
	assert "$output" "Invalid version format"

	echo_test "4NK"
	output=$($0 "1.~+-alpha" +minor +major)
	assert "$output" "Invalid version format"

	echo_test "4LK3"
	output=$($0 "1.~+-alpha.1" +minor +major)
	assert "$output" "Invalid version format"

	echo_test "0P3"
	output=$($0  "1.2.3-alpha1.0" --print-tag)
	assert "$output" "Invalid version format"

	echo_test "3FG"
	output=$($0 "!~.~.~+-alpha" +patch)
	assert "$output" "Invalid version format"

	echo_test "21D"
	output=$($0 "!~.~.~_+-alpha" +patch)
	assert "$output" "Invalid version format"

	echo_test "X87F"
	output=$($0 "!~.~.~x+-alpha" +patch)
	assert "$output" "Invalid version format"

	echo_test "FK3"
	output=$($0 "1.1.1F")
	assert "$output" "Invalid version format"

	echo_test "FKD"
	output=$($0 "1.x")
	assert "$output" "Invalid version format"

	echo_test "5LK3"
	output=$($0 "1:1")
	assert "$output" "Invalid version format"

	echo_test "45TGH"
	output=$($0 '1.2.3' --compare 1.2.)
	assert "$output" "Invalid comparison version format"

	echo_test "4X43X"
	output=$($0 '1.2.3' --compare 1.)
	assert "$output" "Versions can't be compared, format mismatch"

	echo_test "90ORL"
	output=$($0 '1.2.3' --compare 1.2)
	assert "$output" "Versions can't be compared, format mismatch"

	echo_test "DL43"
	output=$($0 '1.2' --compare 1.2.4)
	assert "$output" "Versions can't be compared, format mismatch"

	## Test Parser Functions for Short Format

	export FORMAT="short"

	echo_test "X09L"
	VERSION="1.2"
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '1'
	assert $MINOR '2'
	assert $PATCH ''
	assert $TAG ''

	echo_test "F90K"
	VERSION="1.~"
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '1'
	assert $MINOR '~'
	assert $PATCH ''
	assert $TAG ''

	echo_test "D7L4"
	VERSION="~.2"
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '~'
	assert $MINOR '2'
	assert $PATCH ''
	assert $TAG ''

	echo_test "F987"
	VERSION="~.2"
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '~'
	assert $MINOR '2'
	assert $PATCH ''
	assert $TAG ''

	echo_test "F094"
	VERSION="1.2-alpha"
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '1'
	assert $MINOR '2'
	assert $PATCH ''
	assert $TAG '-alpha'

	echo_test "F04K"
	VERSION="!~.2-alpha"
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '~'
	assert $MINOR '2'
	assert $PATCH ''
	assert $TAG '-alpha'

	## Test Parser Functions for Long Format

	export FORMAT="long"

	echo_test "F4FG"
	VERSION='1.2.3'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '1'
	assert $MINOR '2'
	assert $PATCH '3'
	assert $TAG ''

	echo_test "4FGH"
	VERSION='10.20.30'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '10'
	assert $MINOR '20'
	assert $PATCH '30'
	assert $TAG ''

	echo_test "F983"
	VERSION='100.200.300'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '100'
	assert $MINOR '200'
	assert $PATCH '300'
	assert $TAG ''

	echo_test "DX98"
	VERSION='!1.2.3'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '1'
	assert $MINOR '2'
	assert $PATCH '3'
	assert $TAG ''
	
	echo_test "X04R"
	VERSION='!1.2.3-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '1'
	assert $MINOR '2'
	assert $PATCH '3'
	assert $TAG '-alpha'

	echo_test "F8L4"
	VERSION='!~.2.3'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '~'
	assert $MINOR '2'
	assert $PATCH '3'
	assert $TAG ''

	echo_test "TEST 14"
	VERSION='!~.2.3-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '~'
	assert $MINOR '2'
	assert $PATCH '3'
	assert $TAG '-alpha'

	echo_test "X9PO"
	VERSION='!~.2.3012-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '~'
	assert $MINOR '2'
	assert $PATCH '3012'
	assert $TAG '-alpha'

	echo_test "AS45"
	VERSION='!~.~.3'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '~'
	assert $MINOR '~'
	assert $PATCH '3'
	assert $TAG ''

	echo_test "XSE4"
	VERSION='!~.~.3-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '~'
	assert $MINOR '~'
	assert $PATCH '3'
	assert $TAG '-alpha'

	echo_test "7XLI"
	VERSION='!~.~.~'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '~'
	assert $MINOR '~'
	assert $PATCH '~'
	assert $TAG ''

	echo_test "FX49"
	VERSION='!~.~.~-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE '!'
	assert $MAJOR '~'
	assert $MINOR '~'
	assert $PATCH '~'
	assert $TAG '-alpha'

	echo_test "67FB"
	VERSION='~.2.3'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '~'
	assert $MINOR '2'
	assert $PATCH '3'
	assert $TAG ''

	echo_test "X84F"
	VERSION='~.2.3-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '~'
	assert $MINOR '2'
	assert $PATCH '3'
	assert $TAG '-alpha'

	echo_test "X0TG"
	VERSION='~.~.3'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '~'
	assert $MINOR '~'
	assert $PATCH '3'
	assert $TAG ''

	echo_test "T225"
	VERSION='~.~.3-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '~'
	assert $MINOR '~'
	assert $PATCH '3'
	assert $TAG '-alpha'

	echo_test "DF99"
	VERSION='~.~.~'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '~'
	assert $MINOR '~'
	assert $PATCH '~'
	assert $TAG ''

	echo_test "D4FH"
	VERSION='~.~.~-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '~'
	assert $MINOR '~'
	assert $PATCH '~'
	assert $TAG '-alpha'

	echo_test "X84G"
	VERSION='1.2.~'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '1'
	assert $MINOR '2'
	assert $PATCH '~'
	assert $TAG ''

	echo_test "T4FG"
	VERSION='1.2.~-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '1'
	assert $MINOR '2'
	assert $PATCH '~'
	assert $TAG '-alpha'

	echo_test "D9LF"
	VERSION='1.~.~'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '1'
	assert $MINOR '~'
	assert $PATCH '~'
	assert $TAG ''

	echo_test "D94R"
	VERSION='1.~.~-alpha'
	FORCE=$(getForce $VERSION)
	MAJOR=$(getMajor $VERSION)
	MINOR=$(getMinor $VERSION)
	PATCH=$(getPatch $VERSION)
	TAG=$(getTag $VERSION)
	assert $FORCE ''
	assert $MAJOR '1'
	assert $MINOR '~'
	assert $PATCH '~'
	assert $TAG '-alpha'

	
	## TODO: test for expected failures from script output

	## Test Short Format Script output

	echo_test "F34"
	output=$($0 "1.2")
	assert $output "1.2"

	echo_test "40P"
	output=$($0 "~.1")
	assert $output "0.1"

	echo_test "43F"
	output=$($0 "1.~")
	assert $output "1.0"

	echo_test "4RG"
	output=$($0 "~.~")
	assert $output "0.0"

	echo_test "59F"
	output=$($0 "!~.2" +major)
	assert $output "0.2"

	echo_test "9FT"
	output=$($0 "~.2" +major)
	assert $output "0.2"

	echo_test "0RF"
	output=$($0 "2.3" +major)
	assert $output "3.3"

	echo_test "4FD"
	output=$($0 "2.~" +minor)
	assert $output "2.0"

	echo_test "ULR"
	output=$($0 "2.2" +minor)
	assert $output "2.3"

	echo_test "EPL"
	output=$($0 "1.1" +minor +major)
	assert $output "2.2"

	echo_test "FLK"
	output=$($0 "1.1" +patch)
	assert $output "1.1"

	echo_test "LKI"
	output=$($0 "1.1-alpha")
	assert $output "1.1-alpha"

	echo_test "D9I"
	output=$($0 "1.1-alpha" +minor)
	assert $output "1.2-alpha"

	echo_test "0P3"
	output=$($0 "1.1-alpha" +minor +major)
	assert $output "2.2-alpha"

	echo_test "13R"
	output=$($0 "1.~-alpha" +minor +major)
	assert $output "2.0-alpha"

	## Test Long Format Script Output

	echo_test "X9LI"
	output=$($0 1.2.3)
	assert $output "1.2.3"

	echo_test "X8L4"
	output=$($0 1.2.3 +major)
	assert $output "2.2.3"

	echo_test "4FGHD"
	output=$($0 1.2.3 +minor)
	assert $output "1.3.3"

	echo_test "DP3F"
	output=$($0 1.2.3 +patch)
	assert $output "1.2.4"

	echo_test "DF34"
	output=$($0 1.2.3 +major +minor)
	assert $output "2.3.3"

	echo_test "4BN6"
	output=$($0 1.2.3 +major +patch)
	assert $output "2.2.4"

	echo_test "X9GB"
	output=$($0 1.2.3 +minor +patch)
	assert $output "1.3.4"

	echo_test "X84R"
	output=$($0 1.2.3 +major +minor +patch)
	assert $output "2.3.4"

	echo_test "X09RF"
	output=$($0 "~.2.3")
	assert $output "0.2.3"

	echo_test "F4GN"
	output=$($0 "~.~.3")
	assert $output "0.0.3"

	echo_test "ZS3R"
	output=$($0 "~.~.~")
	assert $output "0.0.0"

	echo_test "ZHJK"
	output=$($0 "!1.2.3")
	assert $output "1.2.3"

	echo_test "X09D"
	output=$($0 "!1.2.3" +major)
	assert $output "1.2.3"

	echo_test "AS3F"
	output=$($0 "!1.2.3" +minor)
	assert $output "1.2.3"

	echo_test "04F3"
	output=$($0 "!1.2.3" +patch)
	assert $output "1.2.3"

	echo_test "X2FH8"
	output=$($0 "!1.2.3" +major +minor)
	assert $output "1.2.3"

	echo_test "X05G"
	output=$($0 "!1.2.3" +major +patch)
	assert $output "1.2.3"

	echo_test "X04H"
	output=$($0 "!1.2.3" +minor +patch)
	assert $output "1.2.3"

	echo_test "DJ4LK"
	output=$($0 "!1.2.3" +major +minor +patch)
	assert $output "1.2.3"

	echo_test "X9L4R"
	output=$($0 "!~.2.3" +major)
	assert $output "0.2.3"

	echo_test "DL4FH"
	output=$($0 "!1.~.3" +minor)
	assert $output "1.0.3"

	echo_test "L3RB"
	output=$($0 "!1.2.~" +patch)
	assert $output "1.2.0"

	echo_test "D09ER"
	output=$($0 "!~.~.~-alpha" +patch)
	assert $output "0.0.0-alpha"

	echo_test "MHEF"
	output=$($0 "!~.~.~+alpha" +patch)
	assert $output "0.0.0+alpha"

	## Test Printing

	echo_test "M4RH"
	output=$($0  "1.2.3" --print-patch)
	assert $output "3"

	echo_test "M8L4"
	output=$($0  "1.2.3" --print-major)
	assert $output "1"

	echo_test "MTR8"
	output=$($0  "1.2.3" --print-minor)
	assert $output "2"

	echo_test "M4FE"
	output=$($0 "1.~.3" --print-minor)
	assert $output "0"

	echo_test "M3FL"
	output=$($0 "!1.~.2" --print-minor +minor)
	assert $output "0"

	echo_test "3RFL"
	output=$($0 "1.1.~" --print-patch +patch)
	assert $output "0"

	echo_test "19FM"
	output=$($0 "1.2.3" +patch --print-patch)
	assert $output "4"

	echo_test "FLMD"
	output=$($0 "1.2.3" --print-patch +patch)
	assert $output "4"

	## Test Comparison for Long Format

	echo_test "4F8"
	output=$($0 "1.2.3" --gt "1.3.4")
	assert $output "false"

	echo_test "4ZD"
	output=$($0 "1.2.3-alpha" --gt "1.3.4-alpha")
	assert $output "false"

	echo_test "LD8"
	output=$($0 "1.2.3" --lt "1.3.4")
	assert $output "true"

	echo_test "4FV"
	output=$($0 "1.2.3" --eq "1.2.3")
	assert $output "true"

	echo_test "GJK"
	output=$($0 "1.2.3" --compare "1.3.4")
	assert $output "lt"

	echo_test "KL3"
	output=$($0 "1.4.3" --compare "1.3.4")
	assert $output "gt"

	echo_test "LO4"
	output=$($0 "1.4.3" --compare "1.4.3")
	assert $output "eq"

	echo_test "D4F"
	output=$($0 "1.4.~" --compare "1.4.0")
	assert $output "eq"

	echo_test "DX4"
	output=$($0 "!1.4.~" --compare "1.4.0")
	assert $output "eq"

	## TODO test comparison of short format

	echo_test "4LK1"
	output=$($0 "1.2" --compare "1.2")
	assert $output "eq"

	echo_test "LM4R"
	output=$($0 "1.~" --compare "1.~")
	assert $output "eq"

	echo_test "19FD"
	output=$($0 "~.1" --compare "~.1")
	assert $output "eq"

	echo_test "39FX"
	output=$($0 "1.1-alpha04" --compare "1.1-alpha04")
	assert $output "eq"

	echo_test "93T5"
	output=$($0 "1.1+04Alpha" --compare "1.2+Alpha")
	assert $output "lt"

	echo_test "45TG"
	output=$($0 "1.2+04Alpha" --compare "1.1+Alpha")
	assert $output "gt"

	echo_test "67GJ"
	output=$($0 "1.2+04Alpha" --gt "1.1+Alpha")
	assert $output "true"

	echo_test "XML4"
	output=$($0 "1.2+04Alpha" --lt "1.1+Alpha")
	assert $output "false"

	echo_test "X04K"
	output=$($0 "1.1+04Alpha" --gt "1.2+Alpha")
	assert $output "false"

	echo_test "0PL3"
	output=$($0 "1.1+04Alpha" --lt "1.2+Alpha")
	assert $output "true"

	echo ""
	echo "all tests passed"
	exit
fi

#setup format regexes
short_regex="^(!)?([0-9]*|~?)\.([0-9]*|~?)([-+:0-9a-zA-Z]*)?$"
long_regex="^(!)?([0-9]*|~?)\.([0-9]*|~?)\.([0-9]*|~?)([-+:0-9a-zA-Z]*)?$"

#grab version from args and validate it against regex
VERSION=$1

#validate args against short or long regex
if [[ $VERSION =~ $short_regex ]]; then
	export FORMAT='short'
fi
if [[ $VERSION =~ $long_regex ]]; then
	export FORMAT='long'
fi
if [ -z "$FORMAT" ]; then
	if [ "$DEBUG" ]; then
		echo "4RT Invalid version format"
	else
		echo "Invalid version format"
	fi
	exit 1
fi

#grab components from version
FORCE=$(getForce $VERSION)
MAJOR=$(getMajor $VERSION)
MINOR=$(getMinor $VERSION)
PATCH=$(getPatch $VERSION)
TAG=$(getTag $VERSION)
NEW_MAJOR=$MAJOR
NEW_MINOR=$MINOR
NEW_PATCH=$PATCH
MAJOR_ZEROED=''
MINOR_ZEROED=''
PATCH_ZEROED=''

#check for ~ to reset major to 0
if [ "$MAJOR" = "~" ]; then
	NEW_MAJOR='0'
	MAJOR_ZEROED='true'
fi

#check for ~ to reset minor to 0
if [ "$MINOR" = "~" ]; then
	NEW_MINOR='0'
	MINOR_ZEROED='true'
fi

#check for ~ to reset patch to 0
if [ "$NEW_PATCH" = "~" ]; then
	NEW_PATCH='0'
	PATCH_ZEROED='true'
fi

#increment major if force isn't present
if [ "$INC_MAJOR" = 'true' ] && [ -z $FORCE ] && [ -z $MAJOR_ZEROED ]; then
	NEW_MAJOR=$(($NEW_MAJOR + 1))
fi

#increment minor if force isn't present
if [ "$INC_MINOR" = 'true' ] && [ -z $FORCE ] && [ -z $MINOR_ZEROED ]; then
	NEW_MINOR=$(($NEW_MINOR + 1))
fi

#increment patch if force isn't present
if [ "$INC_PATCH" = "true" ] && [ -z $FORCE ] && [ -z $PATCH_ZEROED ] && [ "$FORMAT" != "short" ]; then
	NEW_PATCH=$(($NEW_PATCH + 1))
fi

#the regexes to grab each component are a little loose (on purpose),
#validate each component against a stricter regex to ensure proper formatting.

if [ ! "$NEW_MAJOR" ]; then
		if [ "$DEBUG" ]; then
			echo "95T Invalid version format"
		else
			echo "Invalid version format"
		fi
		exit 1
	fi
	
	if [ ! "$NEW_MINOR" ]; then
		if [ "$DEBUG" ]; then
			echo "PO1 Invalid version format"
		else
			echo "Invalid version format"
		fi
		exit 1
	fi

#validate version for short format
if [ "$FORMAT" = "short" ]; then
	
	if [ "$DEBUG" ]; then
		echo "F0P validate_minor $NEW_MINOR"
	fi
	validate_minor $NEW_MINOR

	if [ "$DEBUG" ]; then
		echo "X90 validate_tag $TAG"
	fi
	validate_tag $TAG
fi

#validate version for long format
if [ "$FORMAT" = "long" ]; then
	if [ ! "$NEW_PATCH" ]; then
		if [ "$DEBUG" ]; then
			echo "K45 Invalid version format"
		else
			echo "Invalid version format"
		fi
		exit 1
	fi

	if [ "$DEBUG" ]; then
		echo "4R6 validate_patch $NEW_PATCH"
	fi
	validate_patch $NEW_PATCH

	if [ "$DEBUG" ]; then
		echo "F0P validate_minor $NEW_MINOR"
	fi
	validate_minor $NEW_MINOR

	if [ "$DEBUG" ]; then
		echo "X91 validate_tag $TAG"
	fi
	validate_tag $TAG
fi

#print major
if [ "$PRINT_MAJOR" = true ]; then
	echo $NEW_MAJOR
	exit 0;
fi

#print minor
if [ "$PRINT_MINOR" = true ]; then
	echo $NEW_MINOR
	exit 0
fi

#print patch
if [ "$PRINT_PATCH" = true ]; then
	echo $NEW_PATCH
	exit 0
fi

#print tag
if [ "$PRINT_TAG" = true ]; then
	echo $TAG
	exit 0
fi

#compare
if [ ! -z "$COMPARE" ]; then
	
	# #make sure comparison formats match
	compare_format=""
	
	if [[ "$COMPARE_WITH" =~ $short_regex ]]; then
		compare_format="short"
	fi
	
	if [[ "$COMPARE_WITH" =~ $long_regex ]]; then
		compare_format="long"
	fi
	
	if [ "$FORMAT" != "$compare_format" ]; then
		echo "Versions can't be compared, format mismatch"
		exit 1
	fi

	#grab components
	compare_major=$(getMajor $COMPARE_WITH)
	compare_minor=$(getMinor $COMPARE_WITH)
	compare_patch=$(getPatch $COMPARE_WITH)

	if [ ! "$compare_major" ]; then
		echo "Invalid comparison version format"
		exit 1
	fi

	if [ ! "$compare_minor" ]; then
		echo "Invalid comparison version format"
		exit 1
	fi

	if [ "$compare_format" = "long" ] && [ -z $compare_patch ]; then
		echo "Invalid comparison version format"
		exit 1
	fi

	if [  "$compare_major" = "~" ]; then
		compare_major="0"
	fi
	
	if [ "$compare_minor" = "~" ]; then
		compare_minor="0"
	fi
	
	if [ "$compare_patch" = "~" ]; then
		compare_patch="0"
	fi

	if [ "$compare_format" = "long" ]; then
		validate_patch $compare_patch
	fi

	result=$(compare "$COMPARE" "$NEW_MAJOR" "$NEW_MINOR" "$NEW_PATCH" "$compare_major" "$compare_minor" "$compare_patch")
	echo $result
	exit 0
fi

#create new version
if [ "$TAG" ]; then
	if [ "$FORMAT" = "long" ]; then
		echo "$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH$TAG"
	elif [ "$FORMAT" = "short" ]; then
		echo "$NEW_MAJOR.$NEW_MINOR$TAG"
	fi
else
	if [ "$FORMAT" = "long" ]; then
		echo "$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
	elif [[ "$FORMAT" = "short" ]]; then
		echo "$NEW_MAJOR.$NEW_MINOR"
	fi
fi
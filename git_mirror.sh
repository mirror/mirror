#!/bin/bash
# Repository mirrorer
# © John Peterson. License GNU GPL 3.

function show_usage() {
	echo mirror repo to git hub
	echo 'example usage: git_mirror.sh abc bzr http://launchpad/abc "" --debug --dry-run
--fast skip svn cvs
--interactive require user input
--resume experiment to resume existing svn cvs mirror'
	exit 0
}

if [ $# -lt 3 ]; then
	echo too few arguments
	show_usage
	exit 1
fi

# defaults
isbzr=false
iscvs=false
isgit=false
issvn=false
isdebug=false
isdry=false
isfast=false
isint=false
isresume=false
istest=false

for arg in "$@"; do
case "$arg" in
	-\?|-h|--help|--usage)
		show_usage;;
	-d|--debug)
		isdebug=true;;
	-n|--dry-run)
		isdry=true;;
	-f|--fast)
		isfast=true;;
	-i|--interactive)
		isint=true;;
	-r|--resume)
		isresume=true;;
	-t|--test)
		istest=true;;
esac
done

# disable all commands
if $isdry; then
	shopt -s expand_aliases
	for a in bzr git hg mkdir popd pushd rm svn; do
		alias $a="echo $a"
	done
	# type git; git -v
fi

function format() {
	if $1; then
		bold=$(tput bold)
	fi
	if [ $2 -gt -1 ]; then
		color=$(tput setaf $2)
	fi
	normal=$(tput sgr0)
	shift 2
	echo "${bold}${color}$@${normal}"
}

function is_big() {
	echo checking size
	json=$(curl -s https://api.github.com/repos/$org/$to)
	size=$(echo $json|jshon -e size -u)
if [ $size -gt 100000 ]; then
	format false 9 $(numfmt --to=iec $(($size*1024))) too big for --fast
	exit 1
fi
}

# are we behind ?
function is_behind() {
	echo comparing head dates

	case "$type" in
	git)
		local c="clone --quiet --depth=1";;
	hg)
		local c=" hg clone";;
	*) format false 9 add $type date comparison
		return 0;;
	esac

	# shopt -u expand_aliases
	rm -rf tmp
	mkdir tmp
	pushd tmp
	git $c $from .
	sd=$(TZ=UTC0 git show HEAD --quiet --date=iso-strict-local --format="%cd"|sed "s,+00:00,Z,")
	popd
	# shopt -s expand_aliases
	
	json=$(curl -s https://api.github.com/repos/$org/$to/branches/master)
	md=$(echo $json|jq -r '.. | .date? | strings'|tail -1)

	if [ "$sd" == "$md" ]; then
		echo $to up to date
		exit 0
	else
		echo head dates differ $sd $md
	fi
}

function mirror_exist() {
	if $isdry; then
		echo mirror_exist 0
		return 0
	fi
	echo check for existing repo
	json=$(curl -s https://api.github.com/repos/$org/$to)
	error=$(echo "$json" | jshon -Q -e message -u)
	if [ -n "$error" ] && [[ "$error" != "API rate limit exceeded"* ]]; then
		echo $error;
		return 1
	else
		echo $org/$to exist
		return 0
	fi
}

# create empty repo
function create_repo() {
	description="$from $arg"

	if [ -z "$user" ]; then
		echo user unset
		return 1
	fi
	
	# create repo
	json=$(curl -s -u "$user:$pwd" -d "{\"name\":\"$to\"}" https://api.github.com/orgs/$org/repos)
	error=$(echo "$json" | jshon -Q -e message -u)
	if [ -n "$error" ]; then
		echo $error;
		return 1
	fi

	# set description
	json=$(curl -s -u "$user:$pwd" -X PATCH -d "{\"name\":\"$name\", \"description\":\"$description\"}" https://api.github.com/repos/$org/$name)
}

	# args
	TO=(${1//\// });
	to=${TO[0]}
	branch=${TO[1]}
	type=$2
	from=$3
	arg=$4

	# title
	echo 
	format true -1 $to

	# repo home
	if [ -z "$REPO_HOME" ]; then
		# echo "REPO_HOME not set using ."
		REPO_HOME=.
	fi
	if [ ! -d "$REPO_HOME" ]; then echo "$REPO_HOME doesn't exist"; return 1; fi
	dir=$REPO_HOME/$to

# target org
if [ -z "$org" ]; then
	# echo org is unset using mirror
	org=mirror
fi

# debug
if $isdebug; then
	set -x
fi

# test
if $istest; then
	is_behind
	# mirror_exist
	exit
fi
	
	# type
	m="push --mirror"
	r='add'
	case "$type" in
	bzr) isbzr=true
		c="bzr clone $from ."
		p='bzr sync bzr/master'
		m="push --tags origin HEAD:master";;
	cvs) iscvs=true
		c="cvsimport -i -d $from $arg"
		p="$c";;
	git) isgit=true
		c="clone --mirror $from ."
		p='remote update'
		s=set-url
		r='set-url --push';;
	hg) c="hg clone $from ."
		p='hg pull';;
	svn) issvn=true
		c="svn clone $arg $from ."
		p="svn rebase"
			m="push";;
	*) echo "$type is unsupported"; return 1;;
	esac
	
	# branch push command
	if [ -n "$branch" ]; then
		dir=${dir}_$branch
		m="push origin HEAD:$branch"
	fi

# clone
# why do we need this?
# isrepo=($isgit && -f $dir/HEAD || !$isgit && -f $dir/.git/HEAD)
if [[ -d $dir ]]; then
	echo resume existing repo
	pushd $dir
	git $p

else
	if $isfast && ($issvn || $iscvs); then
		echo --fast disable new clones for $type
		exit 1
	fi

	if $isresume && ! $isgit; then
		echo $type not support resume
		exit 1
	fi

	is_big

	is_behind

	echo creating new folder $to
	mkdir -p $dir
	pushd $dir

	if ! mirror_exist; then
		echo create new repo
		if ! create_repo; then
			exit 1
		fi
	fi

	# this produce errors related to pull requests refs/pull/1/head
	# if $isresume && $isgit; then
	if false; then
		echo clone existing mirror 
		git clone --mirror git@github.com:$org/$to .
		echo update remote
		git remote $s origin $from
		git remote $r origin git@github.com:$org/$to

	else
		echo clone from source
		git $c
		echo update remote
		git remote $r origin git@github.com:$org/$to
	fi
fi

	# select branch - fix this
	if $isbzr; then
		git checkout bzr/master
	fi

	# sync
	git $m
res=$?

	# return to home
	popd

# keep big and slow repos 
if [ $isfast -a $res -eq 0 ]; then
	format false 10 fast success $to
	rm -rf $dir
fi

if $isint; then
	read -p "press return to continue"
fi

if $isdebug; then set +x; fi

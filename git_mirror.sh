#!/bin/bash
# Repository mirrorer
# © John Peterson. License GNU GPL 3.

# install
# sudo apt install -y git mercurial cvs subversion git-cvs git-svn git-remote-bzr jshon jq python3 python-is-python3
#
# curl https://raw.githubusercontent.com/felipec/git-remote-hg/master/git-remote-hg -o ~/bin/git-remote-hg
# chmod +x ~/bin/git-remote-hg
# 
# https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar

# import
source git_login.sh 2>/dev/null

function show_usage() {
	echo mirror repo to git hub
	echo 'example usage: git_mirror.sh abc bzr http://launchpad/abc "" --debug --dry-run
--fast skip svn cvs
--interactive require user input
--quiet no progress info
--resume experiment to resume existing svn cvs mirror
--small less 100 meg
--test test api during dry run
--type=hg -thg only this type
'
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
ishg=false
issvn=false
isdebug=false
isdry=false
isfast=false
isint=false
isresume=false
issmall=false
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
	-q|--quiet)
		q=-q
		qq=-qq;;
	-r|--resume)
		isresume=true;;
	-s|--small)
		issmall=true;;
	--test)
		istest=true;;
	-t*)
		istype=$(echo $arg|cut -c 3-);;
	--type*)
		istype=$(echo $arg|cut -f2 -d=);;
esac
done

# alias
shopt -s expand_aliases
alias svn="svn --trust-server-cert --non-interactive"
# disable commands
if $isdry; then
	for a in git hg mkdir popd pushd rm; do
		alias $a="echo $a"
	done
	# type git; git -v
fi

function format() {
	if $1; then
		local bold=$(tput bold)
	fi
	if [ $2 -gt -1 ]; then
		local color=$(tput setaf $2)
	fi
	normal=$(tput sgr0)
	shift 2
	echo "${bold}${color}$@${normal}"
}

# cloud machine are rate limited 
function have_api() {
	if $isdry && ! $istest; then
		eval $1=false
		return
	fi
	json=$(curl -s https://api.github.com/repos/$org/$to)
	error=$(echo $json | jshon -Q -e message -u)
	if [[ "$error" = "API rate limit exceeded"* ]]; then	
	# if [[ -n "$error" ]]; then	
	# if true; then	
		# echo error $error;
		if [ -z "$user" ]; then
			echo user unset API unavailable
		else
			# retry with credentials 
			json=$(curl -s -u "$user:$pwd" https://api.github.com/repos/$org/$to)
			error=$(echo $json | jshon -Q -e message -u)
			if [ -z "$error" ]; then
				eval $1=true
				login="-u $user:$pwd"
			else
				# echo error $error
			echo API unavailable
			fi
		fi
	else
		eval $1=true
	fi
}

function is_big() {
	if ! ($isfast || $issmall); then return 0; fi
	echo checking size
	if $isdry && ! $istest; then	return 0; fi
	if ! $haveapi; then	return 0; fi
	json=$(curl -s $login https://api.github.com/repos/$org/$to)
	size=$(echo $json|jshon -e size -u)
	megs=$(numfmt --to=iec $(($size*1024)))
if [ $size -gt 100000 ]; then
	format false 9 $megs too big for --fast and --small
	exit 1
else
	format false 2 $megs
fi
}

# only git has shallow clones
function is_behind() {
	if ! $haveapi; then	return 0; fi
	echo comparing head dates
	if  $isdry && ! $istest; then	return 0; fi

	json=$(curl -s $login https://api.github.com/repos/$org/$to/branches/master)
	md=$(echo $json|jq -r '.. | .date? | strings'|tail -1)

	case "$type" in
	git)
		local c="clone --quiet --depth=1";;&

	hg)
		local c=" hg clone";;&

		cvs)
		sd=$(date -u -Is -d "$(cvs -d $from history -a -T|tail -1|cut -f2-4 -d" ")" |sed s,+00:00,Z,)
		# cvs -d $from log -N| grep ^date: | sort | tail -n 1 | cut -d\; -f1
		;;
	svn)
		sd=$(date -u -Is -d "$(svn info $from| grep 'Date' |cut -d' ' -f4-6)"|sed s,+00:00,Z,)
		;;
	git|hg)

	if $istest ; then
		echo last commit $md
		return 0
	fi

	# shopt -u expand_aliases
	rm -rf tmp
	mkdir tmp
	pushd tmp
	echo cloning $from ...
	git $c $from .
	sd=$(TZ=UTC0 git show HEAD --quiet --date=iso-strict-local --format="%cd"|sed "s,+00:00,Z,")
	popd
	# shopt -s expand_aliases
	;;

	*)
		format false 10 mirror date $md 
		format false 9 add $type date comparison
		return 0;;
	esac

	if [ "$sd" == "$md" ]; then
		format false 2 up to date $sd
		exit 0
	else
		format false 9 updating from $md to $sd
	fi
}

function remote_exist() {
	case "$type" in
	cvs)
		cvs -d $from history>/dev/null
;;&
	svn)
		svn info $from >/dev/null
		;;&
	cvs|svn)
		if [ $? -ne 0 ]; then
			exit 1
		fi;;
	*)
		return 0
esac
}

function mirror_exist() {
	if ! $haveapi; then	return 0; fi
	echo check for existing repo
	if $isdry && ! $istest; then	return 0; fi
	json=$(curl -s $login https://api.github.com/repos/$org/$to)
	error=$(echo $json | jshon -Q -e message -u)
	if [[ "$error" = "Not Found" ]]; then
		format false 9 $org/$to missing;
		return 1
	else
		echo $org/$to exist
		return 0
	fi
}

# create empty repo
function create_repo() {
	description="$from $arg"

	# todo read pwd from stdin for one time use
	echo creating $org/$to
	if [ -z "$user" ]; then
		echo fail user unset
		echo run gh repo create
		return 1
	fi
	if $isdry; then	return 0; fi
	
	# create repo
	json=$(curl -s -u $user:$pwd -d "{\"name\":\"$to\"}" https://api.github.com/orgs/$org/repos)
	error=$(echo "$json" | jshon -Q -e message -u)
	if [ -n "$error" ]; then
		echo $error;
		return 1
	fi

	# set description
	json=$(curl -s -u $user:$pwd -X PATCH -d "{\"name\":\"$name\", \"description\":\"$description\"}" https://api.github.com/repos/$org/$name)
}

	# args
	TO=(${1//\// });
	to=${TO[0]}
	branch=${TO[1]}
	type=$2
	from=$3
arg=$4
host=$(echo $from | awk -F[/:] '{print $4}')

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

	# type
	case $type in
	bzr|cvs|git|hg|svn) 
		case $host in
			*gitlab*|github.com) 
				m="push $q --all  --prune" ;;
			*) m="push $q --mirror";;
		esac ;;&
	bzr|git|hg) 
		r='set-url --push';;&
	cvs|svn) 
		r='add';;&
	bzr|hg) 
		c="clone $q --mirror $type::$from ."
		p="pull";;&
	bzr)
		isbzr=true;;
		# git-bzr
		# c="bzr clone $from ."
		# p='bzr sync bzr/master'
		# m="push --tags origin HEAD:master";;
	cvs)
		iscvs=true
		c="cvsimport -i -d $from $arg"
		p="$c";;
	git)
		case $host in
			*gitlab*|github.com) 
				c="clone $q  --no-single-branch --bare $from ."
			# p='fetch --all --prune';;
			# will this still get everything?
			p='remote update';;
			*) c="clone $q --mirror $from ."
			p='remote update';;
		esac
		isgit=true
		s=set-url;;
	hg)
		ishg=true;;
		# git-hg is broken "Cannot chdir to $cdup..."
		# c="hg clone $from ."
		# p='hg pull';;
	svn) issvn=true
		c="svn $qq clone $arg $from ."
		p="svn $qq rebase";;
		# preserve history instead of update
		# m="push $q origin master";;
	*) echo "$type is unsupported"; exit 1;;
	esac
	
	# skip type
if [ -n "$istype" -a "$istype" != "$type" ]; then
	exit
fi

# debug
if $isdebug; then
	set -x
fi

	# title
	echo
	format true -1 $to $type

	# branch push command
	if [ -n "$branch" ]; then
		dir=${dir}_$branch
		m="push origin HEAD:$branch"
	fi

remote_exist

if $isint; then
read -s -n 1 -p "mirror [␣↵/*]" yn
echo
case $yn in
"" ) ;;
* ) exit;;
esac
fi

# clone
# why do we need this?
# isrepo=($isgit && -f $dir/HEAD || !$isgit && -f $dir/.git/HEAD)
if [[ -d $dir ]]; then
	echo resume existing repo
	pushd $dir
	git $p

else
echo no existing clone on disk

	if $isfast && [ -z "$istype" ] && ($issvn || $iscvs); then
		echo --fast disable new $type clones
		exit 1
	fi

	if $isresume && ! $isgit; then
		echo $type not support resume
		exit 1
	fi

# api
haveapi=false
have_api haveapi

# test
if $istest; then
	echo
	# is_big
	# is_behind
	# mirror_exist
	# exit
fi

	is_big

	is_behind

	echo creating new folder $to
	mkdir -p $dir
	pushd $dir

	if ! mirror_exist; then
		if ! create_repo; then
			exit 1
		fi
	fi

	# this produce errors related to pull requests refs/pull/1/head
	# if $isresume && $isgit; then
	if false; then
		echo clone existing mirror 
		git clone --mirror git@github.com:$org/$to .

		echo post processing
		case "$type" in
			bzr)
			git branch master;;
	esac
		case "$to" in
			jdownloader)
			java -jar bfg.jar --strip-blobs-bigger-than 50M
			if [ $? -ne 0 ]; then exit $?; fi;;
	esac

		echo update remote
		git remote $s origin $from
		git remote $r origin git@github.com:$org/$to

	else
		echo $(date -Im -u)Z cloning $from ...
		export GIT_SSL_NO_VERIFY=1
		# git config --global http.sslVerify false
		git $c
		echo update remote address
		git remote $r origin git@github.com:$org/$to
	fi
fi

	# git-bzr
	# if $isbzr; then
		# git checkout bzr/master
	# fi

	# sync
	echo updating $org/$to ...
	git $m
res=$?

	# return home
	popd

if [ $res -eq 0 ]; then
	format true 2 success
	# keep big and slow repos 
	if $isfast && $isgit; then
		rm -rf $dir
	fi
else
	format true 9 fail
fi

if $isdebug; then set +x; fi

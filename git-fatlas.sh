# scripts to find packages in a repo
#
# Set a default upstream if none exists
: ${GIT_FATLAS_UPSTREAM=ssh://git@gitlab.cern.ch:7999/atlas/athena.git}

# _______________________________________________________________________
# init function
#
# This is the first thing you'll have to call to make a sparse
# checkout of Athena. By default this assumes you want to pull from
# the main athena repo and use release 21.2.
#
_git-fatlas-init_usage() {
    echo "usage: $1 [-h] [-v] [-r release] [-u URL] [-s SHARED]"
}
function git-fatlas-init() (

    # make sure this quits if something goes wrong
    set -eu

    # set default configuration
    local RELEASE=main
    local URL=${GIT_FATLAS_UPSTREAM}
    local SHARED=""
    VLOG=/dev/null

    # parse options
    local opt
    while getopts ":hvr:u:s:" opt $@; do
        case $opt in
            h) _git-fatlas-init_usage $FUNCNAME;
               cat <<EOF

Sparse checkout atlas repo and switch to a branch. Note that after
you've run this you need to use git-fatlas-add to add some packages.

With the -s option, clone from a local shared repository

default release: $RELEASE
default repo: $URL

EOF
               return 1;;
            v) VLOG=/dev/stdout ;;
            r) RELEASE=${OPTARG} ;;
            u) URL=${OPTARG} ;;
            s) SHARED=${OPTARG} ;;
            # handle errors
            \?) _git-fatlas-init_usage $FUNCNAME;
                echo "Unknown option: -$OPTARG" >&2;
                return 1;;
            :) _git-fatlas-init_usage $FUNCNAME;
               echo "Missing argument for -$OPTARG" >&2;
               return 1;;
            *) _git-fatlas-init_usage $FUNCNAME;
               echo "Unimplemented option: -$OPTARG" >&2;
               return 1;;
        esac
    done

    if [[ $SHARED ]]; then
        git clone --no-checkout --shared $SHARED athena
        cd athena
        git remote add atlas $URL
    else
        # clone a release without checking out any files
        git clone --no-checkout -o atlas $URL athena
        cd athena
    fi

    # set up the sparse checkout, then move to the desired
    # branch. Note that this leaves git in a rather ugly position
    # since there are no packages checked out.
    git sparse-checkout init --cone

    echo checking out ${RELEASE} > $VLOG
    git checkout ${RELEASE}

    echo caching package list > $VLOG
    git-fatlas-remake-package-list > $VLOG
)


# _____________________________________________________________________
# Add a new remote.
#
# By default this is your user name.
function git-fatlas-user-remote-add() {
    local user=${1-${USER}}
    local br=$(git remote | head -n1)
    local URL=$(git remote get-url $br | sed -r "s:[^/]*(/[^/]*)$:${user}\1:")
    git remote add ${user} ${URL}
}
# this is just the standard atlas one
function git-fatlas-gitlab-remote-add() {
    git remote add atlas ${GIT_FATLAS_UPSTREAM}
}


# ______________________________________________________________________
# Remake package list
#
# We cache the package list in a local file to make tab-complete
# snappy. This could probably be further optimized (i.e. check the
# release and remove packages that aren't used, rebuild automatically
# when it goes out of date).
#
function git-fatlas-make-package-list() {
    git ls-tree --name-only -r HEAD | grep CMakeLists.txt\
        | sed 's@/CMakeLists.txt@@' | sort -f > ${1}
}
function git-fatlas-get-package-list() {
    local pkg_list_dir=/tmp/${USER-fatlas}/${PWD#/}
    mkdir -p $pkg_list_dir
    local pkg_list=${pkg_list_dir}/pkg_list
    if [[ $# == 1 ]]; then
       if [[ $1 == remake ]]; then
           rm -f $pkg_list
       else
           echo "unrecognized option $1" 2>&1
           return 1
       fi
    fi
    if [[ ! -f $pkg_list ]]; then
        git-fatlas-make-package-list $pkg_list
    fi
    echo $pkg_list
}
function git-fatlas-remake-package-list() {
    git-fatlas-get-package-list remake
}

# ______________________________________________________________________
# Add package
#
# Should be pretty self-explanatory: adds the packages you ask for to
# the working tree. There are also tab complete functions defined
# below.
#
function git-fatlas-add() {

    local LOG=${TABTEST-/dev/null}

    echo "--- trying to add a package ---" >> $LOG
    local pkg_list=$(git-fatlas-get-package-list)
    echo "matching against $pkg_list" >> $LOG
    echo "looking for: $1" >> $LOG
    local reply=( $(fgrep ${1} $pkg_list | egrep "(/|^)$1$") )
    echo "matches ${reply[*]}" >> $LOG

    if (( ${#reply[*]} > 1 )); then
        echo "ERROR: too many replies" | tee -a $LOG 2>&1
        return 1
    elif (( ${#reply[*]} == 0 )); then
        echo "ERROR: no matches" | tee -a $LOG 2>&1
        return 1
    fi
    git sparse-checkout add ${reply[*]}
}

# ____________________________________________________________________
# Add a new package to the repo
#
# If you already have something in the working tree and want to check
# it in, you should call this function on it.
#
function git-fatlas-new() (
    pkg_list=$(git-fatlas-get-package-list)
    for STUB in ${@:1} ; do
        if [[ ! -d ${STUB} ]]; then
            echo "${STUB} is not a directory" 2>&1
            return 1
        elif [[ ! -f ${STUB}/CMakeLists.txt ]]; then
            cat <<EOF 1>&2
${STUB} does not contain a CMakeLists.txt file, normally a package should \
contain this
EOF
            return 1
        fi
        echo ${STUB%/} >> $pkg_list
        git-fatlas-add ${STUB%/}
        git add ${STUB%/}/
    done
)

# ____________________________________________________________________
# Remove package
#
# This one is a bit tricky in that we have to make sure we don't
# remove the last package. Git doesn't like that for some reason.
#
function git-fatlas-remove() (
    local NEW=$(git sparse-checkout list | egrep -v $1 | tr '\n' ' ')
    git sparse-checkout set $NEW
)

# ____________________________________________________________________
# Update copyright statements
#
# Only updates the copyrights for files you've touched since branching
# from atlas/main, or whatever branch you name
#
function git-fatlas-copyright-update() {
    local Y=$(date +%Y)
    local T=$(mktemp)
    git diff --name-only ${1-atlas/main}... | while read F ; do
        sed -r "s/(^.*Copyright .* 200.-+).*( CERN.*)/\1$Y\2/" $F > $T
        mv $T $F
    done
}

# ____________________________________________________________________
# Tab complete function for the add utility
#
# if you set TABTEST and then read it with `tail -f` you will see some
# logging info
function _git-fatlas-add() {

    local LOG=${TABTEST-/dev/null}

    # build or get package list
    echo "--- getting package list ---" >> $LOG
    echo "looking for: $2" >> $LOG
    local pkg_list=$(git-fatlas-get-package-list)
    echo "got $pkg_list" >> $LOG

    # first check for completion from the root up
    echo "checking matches in package list" >> $LOG
    COMPREPLY=( $(compgen -W "$(cat $pkg_list)" -- $2 ) )
    if [[ ${#COMPREPLY[*]} != 0 ]]; then
        echo "returning ${#COMPREPLY[*]} matches" >> $LOG
        return 0
    fi

    # then check for a unique fgrep match
    echo "checking with fgrep" >> $LOG
    COMPREPLY=( $(fgrep ${2} $pkg_list ) )
    if [[ ${#COMPREPLY[*]} == 1 ]]; then
        echo "returning ${#COMPREPLY[*]} matches" >> $LOG
        return 0
    fi
    echo "got ${#COMPREPLY[*]} replies, moving on" >> $LOG

    # then check to see if any part of the package name matches
    #
    # note that we can't include the full path because that will
    # trigger a completion to any stub that is shared among all
    # matches.
    echo "checking with fgrep, excluding some patterns" >> $LOG
    COMPREPLY=( $(fgrep ${2} $pkg_list | egrep -o "[^/]*$2.*") )
    echo "returning ${#COMPREPLY[*]} matches" >> $LOG
    return 0
}
complete -F _git-fatlas-add git-fatlas-add

#!/usr/bin/env bash
# =============================================================================
# github.com/mickeys/github-markdown-child-pages
#
# Generate a pretty, relative hierarchical list of child Markdown pages for
# pasting into documents. Man page and white paper at URL above.
#
# Usage: git commit...; cd directory ; children.sh .		# then cut-and-paste into document
# Or usage: ./children.sh roles/ > README.md   # output into README.md
# =============================================================================
PROJURL='https://github.com/mickeys'		# owner URL
PROJECT='github-markdown-child-pages'		# pathTo project git repository

#unwanted=" \[$( whoami )\] "				# " [username] "
PARAMS=''
ARGS='nf'									# -f (full path), -n (color off)
MKDN='.md'									# Markdown file extension
PAT="$MKDN"									# default to Markdown files only
SHOWALL=''									# default to show only $MKDN
UNTRACKED=''								# default to show only git tracked
sp='&nbsp;'									# the most typo'd thing ever

# -----------------------------------------------------------------------------
# Process the command-line arguments passed to us.
# -----------------------------------------------------------------------------
while (( "$#" )); do
	case "$1" in
		-a|--all-filetypes)
			SHOWALL='true'
			ARGS="${ARGS}aF"				# show all, type suffixes
			PAT='*'							# this pattern will show all
			shift 1							# 1 for switch, 2 for following arg
			;;
		-u|--untracked)
			UNTRACKED='true'				# show files regardless of git status
			shift 1							# 1 for switch, 2 for following arg
			;;
		--) # end argument parsing
			shift
			break
			;;
		-*|--*=) # unsupported flags
			echo "Error: Unsupported flag $1" >&2
			exit 1
			;;
		*) # preserve positional arguments
			PARAMS="$PARAMS $1"
			shift
			;;
	esac
done
eval set -- "$PARAMS"						# positional arguments in their place

# -----------------------------------------------------------------------------
# Read into an array a path listing of all the $PAT files below $1.
# -----------------------------------------------------------------------------
# tree -a -I '.git|.DS_Store' -P '*' .
IFS=$'\n' read -d '' -r -a tree \
	< <( tree -${ARGS} -I '.git|.DS_Store' -P "*$PAT" \
		--prune --noreport --charset=ascii "${1:-.}" )

# the following code is obsoleted by --noreport command-line flag
#numBranches="$((${#path[@]}-1))"			# the last array element
#unset "tree[$numBranches]"					# remove `path` summary line

echo "<!-- ${PROJECT}-start -->"			# an easy-to-find start marker
for branch in "${tree[@]}"					# for each line of output left
do
	# -------------------------------------------------------------------------
	# Output from path will look something like:
	#
	# (ASCII path branches) [username] /path/to/file/or/directory
	#
	# so we'll preserve the branch graphics and work on the filepath and then
	# put the parts together.
	# -------------------------------------------------------------------------
	branch="${branch//\`/\\}"				#
#	branch="${branch//$unwanted/}"			# remove "[username]" from each line
 	path="${branch%%-- *}"					# grab left section including `-- `
 	filepath="${branch##*-- }"				# grab right section after `-- `
 	if [ "$path" == '.' ]; then continue ; fi # skip

	# there was a reason I wanted trailing clarifiers but I can't recall now...
	if [ "${filepath: -1}" == '*' ] ; then filepath="${filepath:0:-1}" ; fi

	# if UNTRACKED then just show it (and don't bother testing its git status)
	if [ "$UNTRACKED" == '' ]; then
		gitCmd="git shortlog --summary "$filepath""
		gitStatus="$( $gitCmd  "$filepath" )"
		if [ "${gitStatus:0:2}" == '' ]; then continue ; fi # untracked return nothing
	fi

	# convert ASCII path items to prettier HTML variants
	path="${path// /$sp}"				# non-collapsing spaces
	path="${path//\|/&#9122;}"				# vertical lines
	path="${path//\\/&#9123;}"				# last item in list marker

#echo "DEBUG $filepath ${filepath:(-${#PAT})} $PAT"
	if [ "${filepath:(-${#MKDN})}" == "$MKDN" ]; then
		# ---------------------------------------------------------------------
		# If $filepath ends with the specified extension '.md' then grab the
		# first line of the file to use as a human-readable link part.
		# ---------------------------------------------------------------------
		read -r firstline<"$filepath"
# 		doctitle="${firstline#* }" ## Err \r\n
		doctitle=$(echo "$doctitle" | tr -s '\r\n' ' ') ## Fix \r\n
		branch="$path [$doctitle]($filepath)"
	elif [ "$SHOWALL" != '' ]; then
		# ---------------------------------------------------------------------
		# if we're showing all filetypes provide pathTo the file itself
		# ---------------------------------------------------------------------
		branch="$path [$filepath]($filepath)"
	else
		# ---------------------------------------------------------------------
		# Otherwise this line must be a directory element. Grab the leaf name.
		#
		# Special case: if you pass in '.' the first line will become '. .' :-/
		# ---------------------------------------------------------------------
		if [ "$filepath" == '.' ]; then
			leafname=''
		else
			x="${filepath%%/}"				# remove trailing slash
			leafname="${x##*/}"				# trailing directory name
			branch="$path $leafname"		# format the output
		fi
	fi

	echo "$branch<br>"
done
echo "<table><tr><td><small><i>Generated by <a href=\"${PROJURL}/${PROJECT}?ts=4\">${PROJECT}</a></i>.</small></td></tr></table>"

echo "<!-- ${PROJECT}-end -->"					# an easy-to-find start marker

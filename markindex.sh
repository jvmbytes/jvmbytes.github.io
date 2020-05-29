#!/bin/sh
# 
# ------------------------------------
# author: gelnyang@163.com
# created: 2019/01/10
# 
# `markindex.sh` generate markdown structure files for [docsify.js](https://github.com/docsifyjs/docsify), include `_navbar.md`, `README.md`.
# markdown files MUST contain the following metadata at the begining , eg:
# <!---
# markmeta_author: wongoo
# markmeta_date: 2019-01-09
# markmeta_title: markindex.sh specification
# markmeta_categories: tools
# markmeta_tags: markdown,shell
# -->
# 
# usage: ./markindex.sh "my markdown doc" "http://doc.mydomain.com" "asc" "<DIR>"
# ------------------------------------


markconf_title=$1
markconf_url=$2
markconf_nav_sort=$3
markproj_dir=$4
if [ "$markproj_dir" == "" ]; then
	markproj_dir=$(pwd)
fi

markconf_ignore_dirs=("category" "tags" "media" "static" "files" "tag" "categories")
markproj_sub_dirs=()

function markindex_is_ignore_dir(){
	is_ignore="false"
	for idir in "${markconf_ignore_dirs[@]}"
	do
		if [[ $1 == $idir* ]] || [[ $1 == */$idir* ]]
		then
			is_ignore="true"
			break
		fi
	done
	
	echo $is_ignore
}

function markindex_all_dirs(){
	previous_dir=$(pwd)
	cd $markproj_dir
	dirs=$(find * -type d)
	for dir in $dirs
	do
		ignore=$(markindex_is_ignore_dir $dir)
		if [[ "$ignore" == "true" ]]
		then
			continue
		fi
		level=$(echo $dir |tr "/" "\n" |wc -l)
		if [[ "$markconf_nav_sort" == "asc" ]]	
		then
			numlevel=$((10+$level))
		else
			numlevel=$((100-$level))
		fi
		markproj_sub_dirs+=("$numlevel-$dir")
	done

	if [[ "$markconf_nav_sort" == "asc" ]]	
	then
		markproj_sub_dirs=$(echo "${markproj_sub_dirs[@]}"|tr " " "\n" |grep "-"|sort |sed 's/^[^-]*-//')
	else
		markproj_sub_dirs=$(echo "${markproj_sub_dirs[@]}"|tr " " "\n" |grep "-"|sort -r|sed 's/^[^-]*-//')
	fi

	cd $previous_dir
}

function markindex_parse_categories(){
	grep -m1 "markmeta_categories: " $1 |cut -c 22- |sed 's/,/ /g'
}

function markindex_parse_tags(){
	grep -m1 "markmeta_tags: " $1 |cut -c 16- |sed 's/,/ /g'
}

function markindex_pre_process(){
	mkdir -p $markproj_dir/category
	rm -f $markproj_dir/category/*.md
	echo "" > $markproj_dir/categories.md
	
	mkdir -p $markproj_dir/tag 
	rm -f $markproj_dir/tag/*.md
	echo "" > $markproj_dir/tags.md
	
	echo "# [$markconf_title]($markconf_url)" > $markproj_dir/README.md
	echo "" >> $markproj_dir/README.md
}

function markindex_process_dir(){
	relative_url="/"$1
	if [[ "$1" == "" ]]
	then
		relative_url=""
	fi
	process_dir=$markproj_dir$relative_url
	process_dir_name="${process_dir##*/}"

	echo "process dir $process_dir"

	parent_dir=${process_dir%/*}
	readme=$process_dir/README.md
	
	# ------------> start process files
	if [ "$relative_url" != "" ]; then
		echo "# [$markconf_title]($markconf_url)" > $readme
		echo "" >> $readme
	fi
	
	echo "## $process_dir_name" >> $readme

	files=$(find $process_dir -type f -name "*.md" -maxdepth 1|grep -v _navbar|grep -v README|grep -v categories |grep -v tags |grep -v _sidebar |sort -r)
	for file in $files
	do
		title=$(grep -m1 "markmeta_title:" $file | sed 's/[^:]*://' |xargs)
		date=$(grep -m1 "markmeta_date:" $file | sed 's/[^:]*://' |xargs)
		author=$(grep -m1 "markmeta_author:" $file | sed 's/[^:]*://' |xargs)

		filename="${file##*/}"
		file_extension="${filename##*.}"
		filename="${filename%.*}"

		if [ "$author" == "" ]; then
			author="noname"
	        fi	

		echo "* [$title]($relative_url/$filename), $author, $date" >> $readme

		
		# ----> parse categories	
		categories=$(markindex_parse_categories $file)
		for cate in $categories
		do
			cate=$(echo $cate | tr '[:upper:]' '[:lower:]') # to lowercase
			if [ "$cate" != "" ] && [ ! -f  $markproj_dir/category/$cate.md ]
			then
				cat $markproj_dir/README.md >  $markproj_dir/category/$cate.md
				echo "# $cate" >>  $markproj_dir/category/$cate.md
				echo " [$cate](/category/$cate)" >> $markproj_dir/categories.md
			fi

			echo "* [$title]($relative_url/$filename),$date" >> $markproj_dir/category/$cate.md
		done
	
		# ----> parse tags	
		tags=$(markindex_parse_tags $file)
		for tag in $tags
		do
			tag=$(echo $tag | tr '[:upper:]' '[:lower:]') # to lowercase
			if [ "$tag" != "" ] && [ ! -f  $markproj_dir/tag/$tag.md ]
			then
				echo "# $tag" >>  $markproj_dir/tag/$tag.md
				echo " [$tag](/tag/$tag)" >>  $markproj_dir/tags.md
			fi

			echo "* [$title]($relative_url/$filename),$date" >> $markproj_dir/tag/$tag.md
		done
	done

	# -------> start process navbar
	rm -f $process_dir/_navbar.md
	if [[ "$relative_url" != "" ]]
	then
		echo "[$process_dir_name]($relative_url/)" >> $parent_dir/_navbar.md
	fi
}

function markindex_post_process(){
	echo "" >> $markproj_dir/README.md
	echo "## Navigation" >> $markproj_dir/README.md
	cat $markproj_dir/_navbar.md >> $markproj_dir/README.md
	echo "" >> $markproj_dir/README.md

	echo "## Categories" >> $markproj_dir/README.md
	cat $markproj_dir/categories.md >> $markproj_dir/README.md
	
	echo "" >> $markproj_dir/README.md
	echo "## Tags" >> $markproj_dir/README.md
	cat $markproj_dir/tags.md >> $markproj_dir/README.md

	for dir in $markproj_sub_dirs
	do 
		process_dir=$markproj_dir/$dir
		parent_dir=${process_dir%/*}
		if [ ! -f $process_dir/_navbar.md ]
		then
			cp $parent_dir/_navbar.md $process_dir/_navbar.md
		fi

		echo "" >> $process_dir/README.md
		echo "## Navigation" >> $process_dir/README.md
		cat $process_dir/_navbar.md >> $process_dir/README.md
	done

}

function markindex_process(){
	markindex_pre_process 
	markindex_all_dirs
	markindex_process_dir
	for dir in $markproj_sub_dirs
	do 
		markindex_process_dir $dir
	done

	markindex_post_process 
}

markindex_process

echo "done!"


#!/bin/bash

declare -A _bob
declare -r _bobversion=0.0.1
 
arg=""

_substr() {
	content=$(cat)
	read -r var start end <<< $(echo $content | cut -d ':' --output-delimiter=" " -f1,2,3)
	string=${!var}
	echo ${string:$start:$end}
}

_categories() {
	IFS=',' 
	read -ra categories_arr <<< "$category"
	for cat in ${categories_arr[@]}
	do
		IFS='|'
		read -ra categories_sec <<< "$cat"
		if [ ${#categories_sec[@]} -eq 2 ]
			then
				echo "<itunes:category text=\"${categories_sec[0]}\"><itunes:category text=\"${categories_sec[1]}\"/></itunes:category>"
			else
				echo "<itunes:category text=\"${categories_sec[0]}\"/>"
		fi
		
	done
}

_dateforpage() {

	var=$(cat)
	pubdate=${!var}
	echo $(date -d"$pubdate" "+%x")
	
}

_readepisode() {

	arg=''
	while read line || [ -n "$line" ]
		
	do
	
		[ -z "$line" ] && continue

		
		if  [ ${line:(-1)} == ':' ]
			then
				if [ ! -z "$arg" ] 
				then
					episode[$arg]=${!arg}
				fi
				arg_old=${line:0:(-1)}
				arg=${arg_old//-/_}
				declare $arg=''
			else
				declare $arg="${!arg}$line"
		
		fi

	done < $1
	for i in ${!episode[@]}
	do
		episode[$i]=$(echo ${episode[$i]} | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')
	done
	
	IFS=' ' 
	read -ra enc <<< "${episode[$format]}"

	episode[encurl]=${enc[0]}
	episode[enclen]=${enc[1]}
	case $format in
		'mp3'	)	episode[enctype]='audio/mpeg';;
		'm4a'	)	episode[enctype]='audio/mp4';;
		'opus' 	)	episode[enctype]='audio/ogg;codecs=opus';;
		* 		)	episode[enctype]='audio/mpeg';;
	esac
}

while read line || [ -n "$line" ]
	
	do

	[ -z "$line" ] && continue

	if  [ ${line:(-1)} == ':' ]
		then
			if [ ! -z "$arg" ] 
			then
				declare $arg="$(echo "${!arg}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')"
			fi
			arg_old=${line:0:(-1)}
			arg=${arg_old//-/_}
		else
			declare $arg="${!arg}$line"
		
	fi
	
	
done < feed.cfg

[ ! -z "$language" ] && export LC_ALL="${language//-/_}.utf-8"


declare -a bformats=( $formats )
. ./mo

declare css=$(cat assets/*.css)

echo -e "Processing $title"

for format in ${bformats[@]}; do
	echo -e "\ncreating feed for $format"
	declare -A episode=()
	declare items=''
	declare webitems=''
	for file in episodes/*.epi
	do
		slug=$(basename $file .epi|awk -F '_' '{print $1}')
		_readepisode $file
		episode[slug]=$slug
		echo -e "\tepisode ${episode[title]}"
		items="$items"$(cat templates/item.template | mo)
		webitem=$(cat templates/item_web.template | mo)
		webitems="$webitems""$webitem"
		cat templates/page_episode.template | mo >"$localwebpath"/"$slug".html
		
	done
	
	cat templates/rss.template | mo >"$localwebpath"/feed/"$format"
done

cat templates/page.template | mo >"$localwebpath"/index.html
cp -rf assets "$localwebpath"/
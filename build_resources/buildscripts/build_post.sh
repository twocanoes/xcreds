#!/bin/sh
set -x 
prebeta_filename="${1}"

if [ ! -e Builds ] ; then
	mkdir Builds
fi

cp "${prebeta_filename}" ../../products/builds/
open ../../products/builds/



filename="${prebeta_filename}"

this_dir=$(dirname $0)
source ${this_dir}/../../../build/github_creds.sh 

#echo "Uploading ${prebeta_filename}"
if [ -f "${prebeta_filename}" ] &&  [ -n "${upload}" ]; then

#	curl --progress-bar -X POST "https://${bitbucket_username}:${bitbucket_password}@api.bitbucket.org/2.0/repositories/twocanoes/xcreds/downloads" --form files=@"${prebeta_filename}" > /tmp/curl.log
	owner="twocanoes"
	GH_API="https://api.github.com"
	repo="xcreds"
	tag="prebeta"
	GH_REPO="$GH_API/repos/$owner/$repo"
	GH_TAGS="$GH_REPO/releases/tags/$tag"
	AUTH="Authorization: token $github_api_token"
	if [[ "$tag" == 'LATEST' ]]; then
		GH_TAGS="$GH_REPO/releases/latest"
	fi

	curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "Error: Invalid repo, token or network issue!";  exit 1; }
	response=$(curl -sH "$AUTH" $GH_TAGS)
	
	# Get ID of the asset based on given filename.
	eval $(echo "$response" | grep -m 1 "id.:" | grep -w id | tr : = | tr -cd '[[:alnum:]]=')
	[ "$id" ] || { echo "Error: Failed to get release id for tag: $tag"; echo "$response" | awk 'length($0)<100' >&2; exit 1; }
	
	# Upload asset
	echo "Uploading asset... "
	
	# Construct url
	GH_ASSET="https://uploads.github.com/repos/$owner/$repo/releases/$id/assets?name=$(basename $filename)"
	curl --data-binary @"$filename" -H "Authorization: token $github_api_token" -H "Content-Type: application/octet-stream" $GH_ASSET

fi


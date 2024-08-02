#!/bin/bash
# one fundtion to avoid repetition in GitHub actions
# takes as params:
# 1 --> the vo to use for entitlement
# 2 --> the refresh token
# 3 --> the list of clouds to update
#
# Will throw the OIDC TOKEN to output!


refresh_token() {
	local vo="$1"
	shift
	local token="$2"
	shift

	# using parametric scopes to only have access to the right VO
	SCOPE="openid%20email%20profile%20voperson_id"
	SCOPE="$SCOPE%20eduperson_entitlement:urn:mace:egi.eu:group:$vo:role=vm_operator#aai.egi.eu"
	SCOPE="$SCOPE%20eduperson_entitlement:urn:mace:egi.eu:group:$vo:role=member#aai.egi.eu"
	OIDC_TOKEN=$(curl -X POST "https://aai.egi.eu/auth/realms/egi/protocol/openid-connect/token" \
			  -d "grant_type=refresh_token&client_id=token-portal&scope=$SCOPE&refresh_token=$token" \
			  | jq -r ".access_token")
	echo "::add-mask::$OIDC_TOKEN"
	echo $@
	for cloud in "$@" ; do
		echo $cloud
		local site="$(yq -r ".clouds.$cloud.site" clouds.yaml)"
		local vo="$(yq -r ".clouds.$cloud.vo" clouds.yaml)"
		local os_token="$(fedcloud openstack token issue --oidc-access-token "$OIDC_TOKEN" \
						--site "$site" --vo "$vo" -j | jq -r '.[0].Result.id')"
		yq -y -i '.clouds.'"$cloud"'.auth.token="'"$os_token"'"'  clouds.yaml
	done

	echo $OIDC_TOKEN
}

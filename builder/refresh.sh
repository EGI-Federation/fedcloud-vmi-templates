#!/bin/bash
# one script to avoid repetition in GitHub actions
# takes as params:
# 1 --> the vo to use for entitlement
# 2 --> the refresh token
# 3 --> the list of clouds to update
#
# Will throw the OIDC TOKEN to output!

set -e

VO="$1"
REFRESH_TOKEN="$2"
CLOUDS="$3"

# using parametric scopes to only have access to the right VO
SCOPE="openid%20email%20profile%20voperson_id"
SCOPE="$SCOPE%20eduperson_entitlement:urn:mace:egi.eu:group:$VO:role=vm_operator#aai.egi.eu"
SCOPE="$SCOPE%20eduperson_entitlement:urn:mace:egi.eu:group:$VO:role=member#aai.egi.eu"
OIDC_TOKEN=$(curl -X POST "https://aai.egi.eu/auth/realms/egi/protocol/openid-connect/token" \
                  -d "grant_type=refresh_token&client_id=token-portal&scope=$SCOPE&refresh_token=$REFRESH_TOKEN" \
                  | jq -r ".access_token")
echo "::add-mask::$OIDC_TOKEN"
echo $CLOUDS
for cloud in $CLOUDS; do
	SITE="$(yq -r ".clouds.$cloud.site" clouds.yaml)"
	VO="$(yq -r ".clouds.$cloud.vo" clouds.yaml)"
	OS_TOKEN="$(fedcloud openstack token issue --oidc-access-token "$OIDC_TOKEN" \
        			--site "$SITE" --vo "$VO" -j | jq -r '.[0].Result.id')"
	yq -y -i '.clouds.'"$cloud"'.auth.token="'"$OS_TOKEN"'"'  clouds.yaml
done

echo $OIDC_TOKEN

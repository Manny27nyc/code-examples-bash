# Redirect to the DocuSign console web tool

# Check that we're in a bash shell
if [[ $SHELL != *"bash"* ]]; then
  echo "PROBLEM: Run these scripts from within the bash shell."
fi



# Configuration
# 1. Obtain an OAuth access token from
#    https://developers.docusign.com/oauth-token-generator
access_token=$(cat config/ds_access_token.txt)
# 2. Obtain your accountId from demo.docusign.net -- the account id is shown in
#    the drop down on the upper right corner of the screen by your picture or
#    the default picture.
account_id=$(cat config/API_ACCOUNT_ID)

base_path="https://demo.docusign.net/restapi"

# Check that we have an envelope id
if [ ! -f config/ENVELOPE_ID ]; then
    echo ""
    echo "PROBLEM: An envelope id is needed. Fix: execute script eg002SigningViaEmail.sh"
    echo ""
    exit -1
fi
envelope_id=`cat config/ENVELOPE_ID`

# The returnUrl is normally your own web app. DocuSign will redirect
# the signer to returnUrl when the embedded signing completes.
# For this example, we'll use http://httpbin.org/get to show the 
# query parameters passed back from DocuSign

# The web tool console can be opened in either of two views:
echo ""
PS3='Select the console view: '
options=("Front page" "Envelope view")
select opt in "${options[@]}"
do
    case $opt in
        "Front page")
            json='{"returnUrl": "http://httpbin.org/get"}'
            break
            ;;
        "Envelope view")
            json="{\"returnUrl\": \"http://httpbin.org/get\",
                   \"envelopeId\": \"${envelope_id}\"}"
            break
            ;;
    esac
done

echo ""
echo "Requesting the console view url"
echo ""

response=$(mktemp /tmp/response-eg-012.XXXXXX)
# ***DS.snippet.0.start
curl --header "Authorization: Bearer ${access_token}" \
     --header "Content-Type: application/json" \
     --data-binary "${json}" \
     --request POST ${base_path}/v2.1/accounts/${account_id}/views/console \
     --output $response

echo ""
echo "Results:"
echo ""
cat $response
console_url=`cat $response | grep url | sed 's/.*\"url\": \"//' | sed 's/\".*//'`
# ***DS.snippet.0.end
echo ""
printf "The console URL is ${console_url}\n"
printf "It is only valid for five minutes. Attempting to automatically open your browser...\n"
if which xdg-open &> /dev/null  ; then
  xdg-open "$console_url"
elif which open &> /dev/null    ; then
  open "$console_url"
elif which start &> /dev/null   ; then
  start "$console_url"
fi

# cleanup
rm "$response"

echo ""
echo "Done."
echo ""
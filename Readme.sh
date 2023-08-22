oc delete secret httpbasicauth
oc create secret generic httpbasicauth   --from-file=./apicast-policy.json   --from-file=./init.lua   --from-file=./httpbasicauth.lua
oc rollout latest dc/apicast-staging
oc get dc/apicast-staging
#add the following properties in the APIManager yaml definition at the spec.apicast.stagingSpec.customPolicies
#        - name: muishttpbasicauth
#          secretRef:
#            name: muishttpbasicauth
#          version: '0.1'


#links :
https://gist.github.com/crisidev/3d314af9494255e24aa5f78646909ec0
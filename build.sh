#!/usr/bin/env bash

# Build the site from templates, upload it to S3, and invalidate the CloudFront cache.
#
# Designed to work as a github action. You'll want to define $AWS_ACCOUNT_ID, $COMPLIANCE_BUCKET, and
# $CLOUDFRONT_DISTRIBUTION_ID if you want to run this locally.
#

export AWS_PAGER=""

e2() {
   echo "$@" >&2
}

warn() {
   echo "$1" >&2
}

die() {
   warn "$1"
   exit 1
}

fixup_standalone_policies() {
  sed 's/class="md-sidebar\ /style="display: none" class="md-sidebar\ /g' site/cookie-policy/index.html > site/cookie-policy/index-standalone.html
  sed -i 's/class="md-search"/style="display: none" class="md-search"/g' site/cookie-policy/index-standalone.html
  sed -i 's/class="md-footer"/style="display: none" class="md-footer"/g' site/cookie-policy/index-standalone.html
  sed -i 's/class="md-header md-header--shadow"/style="display: none" class="md-header md-header--shadow"/g' site/cookie-policy/index-standalone.html
  sed -i 's/Appendix .* Cookie Policy//' site/cookie-policy/index-standalone.html
  sed 's/class="md-sidebar\ /style="display: none" class="md-sidebar\ /g' site/privacy-policy/index.html > site/privacy-policy/index-standalone.html
  sed -i 's/class="md-search"/style="display: none" class="md-search"/g' site/privacy-policy/index-standalone.html
  sed -i 's/class="md-footer"/style="display: none" class="md-footer"/g' site/privacy-policy/index-standalone.html
  sed -i 's/class="md-header md-header--shadow"/style="display: none" class="md-header md-header--shadow"/g' site/privacy-policy/index-standalone.html
  sed -i 's/Appendix .* Privacy Policy//' site/privacy-policy/index-standalone.html
}

rm -fr ./site/* ./docs/* ./partials/*

command -v gdate >/dev/null 2>&1 && DATE_CMD=gdate || DATE_CMD=date

sed -i  -e "s,\"currentRevision\":.*,\"currentRevision\": \"Last Reviewed: $(git log -1 --format="%at" | xargs -I{} $DATE_CMD -d @{} +%F:%T-%Z)\"," abvprp-config.json

psp build -t ./templates -c abvprp-config.json --noninteractive || die "Failed to build markdown files from templates"

# This is a kludge; I can't get psp to ref a non-default image
cp assets/images/aps_logo.png docs/assets/images || die "APS logo did not copy"

mkdocs build || die "mkdocs failed"
fixup_standalone_policies || die "failed to create standalone html files"

if [[ ! -z "$AWS_ACCOUNT_ID" ]] && [[ $(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null) == "$AWS_ACCOUNT_ID" ]]; then
  cd site || die "site directory unavailable, not updating web site"
  echo "Uploading site to S3:"
  sleep 1
  aws s3 sync . s3://$COMPLIANCE_BUCKET  || die "S3 sync failed"
  echo ""
  echo "Creating CloudFront cache invalidation:"
  sleep 1
  aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths "/*" || die "cloudfront invalidation request failed"
fi

# We don't really need a Word version and this stuff barely works, but I'm leaving it
# here for future work if we want to revist.
#
#mkdir -p site/docx
#cat mkdocs.yml | grep -v index.md | yq -r '.nav[] | to_entries | .[] | .value' > temp.md
##cat temp.md
#for token in $(cat mkdocs.yml | grep -v index.md | yq -r '.nav[] | to_entries | .[] | .value'); do
#    sed -i "s/$token#/#/g" temp.md
#done
#sed -i "s/program\.md/\#security-program-overview/" temp.md
#sed -i "s/corp-gov\.md/\#corporate-governance/" temp.md
#sed -i "s/policy-mgmt\.md/\#policy-management/" temp.md
#sed -i "s/model\.md/\#security-architecture-and-operating-model/" temp.md
#sed -i "s/rar\.md/\#roles-responsibilities-and-training/" temp.md
#sed -i "s/risk-mgmt\.md/\#risk-management-and-risk-assessment-process/" temp.md
#sed -i "s/compliance-audit\.md/\#compliance-audits-and-external-communications/" temp.md
#sed -i "s/system-audit\.md/\#system-audits-monitoring-and-assessments/" temp.md
#sed -i "s/hr\.md/\#hr-and-personnel-security/" temp.md
#sed -i "s/access\.md/\#access/" temp.md
#sed -i "s/facility\.md/\#facility-access-and-physical-security/" temp.md
#sed -i "s/asset-mgmt\.md/\#asset-inventory-management/" temp.md
#sed -i "s/data-mgmt\.md/\#data-management/" temp.md
#sed -i "s/data-protection\.md/\#data-protection/" temp.md
#sed -i "s/sdlc\.md/\#secure-software-development-and-product-security/" temp.md
#sed -i "s/ccm\.md/\#configuration-and-change-management/" temp.md
#sed -i "s/threat\.md/\#threat-detection-and-prevention/" temp.md
#sed -i "s/vuln-mgmt\.md/\#vulnerability-management/" temp.md
#sed -i "s/mdm\.md/\#mobile-device-security-and-media-management/" temp.md
#sed -i "s/bcdr\.md/\#business-continuity-and-disaster-recovery/" temp.md
#sed -i "s/ir\.md/\#incident-response/" temp.md
#sed -i "s/breach\.md/\#breach-investigation-and-notification/" temp.md
#sed -i "s/vendor\.md/\#third-party-security-and-vendor-risk-management/" temp.md
#sed -i "s/privacy\.md/\#privacy-practice-and-consent/" temp.md
#sed -i "s/ref\.md/\#addendum-and-references/" temp.md
#sed -i "s/employee-handbook\.md/\#appendix-a-employee-handbook/" temp.md
#sed -i "s/approved-software\.md/\#appendix-b-approved-software/" temp.md
#sed -i "s/approved-vendors\.md/\#appendix-c-approved-vendors/" temp.md
#sed -i "s/definitions\.md/\#appendix-d-key-definitions/" temp.md
#sed -i "s/privacy-policy\.md/\#appendix-e-privacy-policy/" temp.md
#sed -i "s/cookie-policy\.md/\#appendix-f-cookie-policy/" temp.md
##pandoc -s --toc -o site/docx/policies.docx temp.md
#rm temp.md
##echo "Please open $(pwd)/site/docx/policies.docx in Microsoft Word to fix the TOC."

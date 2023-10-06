#!/bin/bash
rm -fr ./site/* ./docs/* ./partials/*
command -v gdate >/dev/null 2>&1 && DATE_CMD=gdate || DATE_CMD=date
sed -i  -e "s,\"currentRevision\":.*,\"currentRevision\": \"Last Reviewed: $(git log -1 --format="%at" | xargs -I{} $DATE_CMD -d @{} +%F:%T-%Z)\"," abvprp-config.json
psp build -t ./templates -c abvprp-config.json
mkdocs build
sed 's/class="md-sidebar\ /style="display: none" class="md-sidebar\ /g' site/privacy-policy/index.html > site/privacy-policy/index-standalone.html
sed -i 's/class="md-search"/style="display: none" class="md-search"/g' site/privacy-policy/index-standalone.html
sed -i 's/class="md-footer"/style="display: none" class="md-footer"/g' site/privacy-policy/index-standalone.html
sed -i 's/class="md-footer"/style="display: none" class="md-header"/g' site/privacy-policy/index-standalone.html
mkdir -p site/docx
cat mkdocs.yml | grep -v index.md | yq -r '.nav[] | to_entries | .[] | .value' > temp.md
#cat temp.md
for token in $(cat mkdocs.yml | grep -v index.md | yq -r '.nav[] | to_entries | .[] | .value'); do
    sed -i "s/$token#/#/g" temp.md
done
sed -i "s/program\.md/\#security-program-overview/" temp.md
sed -i "s/corp-gov\.md/\#corporate-governance/" temp.md
sed -i "s/policy-mgmt\.md/\#policy-management/" temp.md
sed -i "s/model\.md/\#security-architecture-and-operating-model/" temp.md
sed -i "s/rar\.md/\#roles-responsibilities-and-training/" temp.md
sed -i "s/risk-mgmt\.md/\#risk-management-and-risk-assessment-process/" temp.md
sed -i "s/compliance-audit\.md/\#compliance-audits-and-external-communications/" temp.md
sed -i "s/system-audit\.md/\#system-audits-monitoring-and-assessments/" temp.md
sed -i "s/hr\.md/\#hr-and-personnel-security/" temp.md
sed -i "s/access\.md/\#access/" temp.md
sed -i "s/facility\.md/\#facility-access-and-physical-security/" temp.md
sed -i "s/asset-mgmt\.md/\#asset-inventory-management/" temp.md
sed -i "s/data-mgmt\.md/\#data-management/" temp.md
sed -i "s/data-protection\.md/\#data-protection/" temp.md
sed -i "s/sdlc\.md/\#secure-software-development-and-product-security/" temp.md
sed -i "s/ccm\.md/\#configuration-and-change-management/" temp.md
sed -i "s/threat\.md/\#threat-detection-and-prevention/" temp.md
sed -i "s/vuln-mgmt\.md/\#vulnerability-management/" temp.md
sed -i "s/mdm\.md/\#mobile-device-security-and-media-management/" temp.md
sed -i "s/bcdr\.md/\#business-continuity-and-disaster-recovery/" temp.md
sed -i "s/ir\.md/\#incident-response/" temp.md
sed -i "s/breach\.md/\#breach-investigation-and-notification/" temp.md
sed -i "s/vendor\.md/\#third-party-security-and-vendor-risk-management/" temp.md
sed -i "s/privacy\.md/\#privacy-practice-and-consent/" temp.md
sed -i "s/ref\.md/\#addendum-and-references/" temp.md
sed -i "s/employee-handbook\.md/\#appendix-a-employee-handbook/" temp.md
sed -i "s/approved-software\.md/\#appendix-b-approved-software/" temp.md
sed -i "s/approved-vendors\.md/\#appendix-c-approved-vendors/" temp.md
sed -i "s/definitions\.md/\#appendix-d-key-definitions/" temp.md
sed -i "s/privacy-policy\.md/\#appendix-e-privacy-policy/" temp.md
sed -i "s/cookie-policy\.md/\#appendix-f-cookie-policy/" temp.md
#pandoc -s --toc -o site/docx/policies.docx temp.md
rm temp.md
#echo "Please open $(pwd)/site/docx/policies.docx in Microsoft Word to fix the TOC."

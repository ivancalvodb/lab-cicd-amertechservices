curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh
databricks bundle schema > bundle-settings-schema.json


echo "# yaml-language-server: $schema=bundle-settings-schema.json
bundle:
  name: dlt-wikipedia

resources:
  pipelines:
    dlt-wikipedia-pipeline:
      name: dlt-wikipedia-pipeline
      development: true
      continuous: false
      channel: "CURRENT"
      photon: false
      libraries:
        - notebook:
            path: ./dlt-wikipedia-python.py
      edition: "ADVANCED"
      clusters:
        - label: "default"
          num_workers: 1

environments:
  development:
    workspace:
      host: <workspace-url>" > bundle2.yml

cd /Users/ivan.calvo

echo "host  = <workspace-url>
token = <personal-access-token>" > .databricksCustom

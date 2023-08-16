# CI/CD with DAB demo
This is a demo that implements CI/CD using DAB on Databricks platformn

# Commands for DAB

(One time config) When the repo is cloned, run this in projects root:
```console
databricks bundle schema > bundle-settings-schema.json
```

## Validate bundle.yml config file

Before deploying your current project, validate the **bundle.yml** config file using the following command:

```console
databricks bundle validate
```

If a JSON is returned everything is ready to be deployed.

P.D: **This command only validates the host and file syntax**, this does not check the existence of catalogs, schemas, tables or paths in DBFS.

## Deploy the project

The following command will deploy the pipeline defined on the **bundle.yml** file (*etl-dtl-sensors-pipeline*) in the workspace:

```console
databricks bundle deploy -e
```

## Execute the pipeline deployed on the previous step

The following command runs the pipeline *etl-dtl-sensors-pipeline* on the development environment:
```console
databricks bundle run -e development etl-dtl-sensors-pipeline
```






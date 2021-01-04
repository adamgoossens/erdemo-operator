- [1. End User Quick Start using ER-Demo Operator](#1-end-user-quick-start-using-er-demo-operator)
- [2. ER-Demo Ansible Playbook Development](#2-er-demo-ansible-playbook-development)
  - [2.1. Local Tooling](#21-local-tooling)
  - [2.2. MapBox Access Token](#22-mapbox-access-token)
  - [2.3. Setup](#23-setup)
  - [2.4. Option A:  Pre-built Images](#24-option-a--pre-built-images)
  - [2.5. Option B: CI/CD](#25-option-b-cicd)
  - [2.6. Troubleshooting A Failed Deployment](#26-troubleshooting-a-failed-deployment)
    - [2.6.1. Ansible Hints](#261-ansible-hints)
    - [2.6.2. Idempotency](#262-idempotency)
  - [2.7. Uninstall](#27-uninstall)
  - [2.8. Advanced Multi-User Installation](#28-advanced-multi-user-installation)
- [3. ER-Demo Operator Image Upgrade](#3-er-demo-operator-image-upgrade)
  - [3.1. Pre-reqs](#31-pre-reqs)
  - [3.2. Procedure](#32-procedure)
- [4. Operator Development and Test](#4-operator-development-and-test)

# 1. End User Quick Start using ER-Demo Operator

Please see the ER-Demo [Install Guide](https://erdemo.io/install).

# 2. ER-Demo Ansible Playbook Development
This ER-Demo operator is based on an ansible playbook that is included in this git project.
Optionally for development purposes, this ansible can be executed directly from this project (rather than having the ER-Demo operator execute the ansible).
In addition, changes to this ansible can be made and subsequent releases of this operator will incorporate these new ansible changes.

The following sections provide details on how to execute the included ansible playbook to provision an ER-Demo environment :

## 2.1. Local Tooling

To install the Emergency Response application, you will need the following tools on your local machine:

1. **Unix flavor OS with BASH shell**:  ie; Fedora, RHEL, CentOS, Ubuntu, OSX
2. **git**
3. **[oc utility v4.6](https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.6/)**
4. **[Ansible](https://www.redhat.com/en/technologies/management/ansible)**
   
   Installation of the Emergency Response application is tested using the _ansible-playbook_ utility from the _ansible_ package of Fedora 31.  Others in the community have also succeeded in installing the app using ansible on OSX.

## 2.2. MapBox Access Token

The Emergency Response application makes use of a third-party SaaS API called [MapBox](https://www.mapbox.com/).
MapBox APIs provide the Emergency Response application with an optimized route for a responder to travel given pick-up and drop-off locations.  To invoke its APIs, MapBox requires an [access token](https://docs.mapbox.com/help/how-mapbox-works/access-tokens).  For normal use of the Emergency Response application the _free-tier_ account provides ample rate-limits.

![MapBox token](/images/mapbox_token.png)

## 2.3. Setup

1. Using the oc utility on your local machine, ensure that you are authenticated in your OCP 4 environment as a cluster-admin.
1. OPTIONAL: Checkout the latest tag of this project:
   ```
   git checkout 2.10
   ```

1. Copy the _inventory.template_
   ```
   cp playbooks/group_vars/inventory.yml inventory
   ```

1. Using your favorite text editor, open the inventory.yml file:
   `````
   $ vi inventory
   `````

1. Replace the sample MapBox access token (`map_token`) with a real MapBox token.
   ```
   # MapBox API token, see https://docs.mapbox.com/help/how-mapbox-works/access-tokens/
   map_token=pk.egfdgewrthfdiamJyaWRERKLJWRIONEWRwerqeGNjamxqYjA2323czdXBrcW5mbmg0amkifQ.iBEb0APX1Vmo-2934rj
   ```

1. Save the changes

You will now execute the ansible to install the Emergency Response application.
**Select one of the following two approaches:  _Pre-built Images_ or _CI/CD_**


## 2.4. Option A:  Pre-built Images
This approach is best suited for those that want to utilize (ie: for a customer demo) the Emergency Response app.  This installation approach does not use Jenkins pipelines.  Instead, the OpenShift _deployments_ for each component of the Emergency Response application are started using pre-built Linux container images pulled from corresponding [public Quay image repositories](https://quay.io/organization/emergencyresponsedemo).  With this approach, the typical duration to build the Emergency Response app is about 20 minutes.  This is the default installation approach.


1. Kick-off the Emergency Response app provisioning using pre-built container images in quay:
   `````
   $ ansible-playbook -i inventory playbooks/install.yml
   `````

1. After about 20 minutes, you should see ansible log messages similar to the following:
   ```
   PLAY RECAP ********************************************************************************
   localhost : ok=432  changed=240  unreachable=0    failed=0    skipped=253  rescued=0    ignored=0
   ```
## 2.5. Option B: CI/CD

This approach is best suited for code contributors to the Emergency Response app.  Individual Jenkins pipelines are provided for each component of the app.  Each pipeline builds from source, tests, creates a Linux container image and deploys that image to OpenShift.  The typical duration to build the Emergency Response application from source using these pipelines is about an hour.  This approach is also of value if the focus of a demo to a customer and/or partner is to introduce them to CI/CD best practices of a microservice architected application deployed to OpenShift.

1. kick-off the Emergency Response app provisioning:
   ```
   ansible-playbook -i inventory playbooks/install.yml \
                    -e deploy_from=source
   ```

2. After about an hour, the provisioning should be complete.

3. You can review any of the CI/CD pipelines that ran as part of this provisioning process:
   1. List all build pipelines:
       ```
       oc get build -n user1-er-tools | grep pipeline

       ...

       user1-incident-service-pipeline-1         JenkinsPipeline            Complete   2 hours ago
       user1-mission-service-pipeline-1          JenkinsPipeline            Complete   2 hours ago
       user1-responder-service-pipeline-1        JenkinsPipeline            Complete   2 hours ago
       user1-assignment-rules-model-pipeline-1   JenkinsPipeline            Complete   2 hours ago
       ```

   2. From that list, pick any of the builds to get the URL to the corresponding Jenkins pipeline:
      ```
      oc logs user2-incident-service-pipeline-1 -n user1-er-tools

      info: logs available at https://jenkins-user2-er-tools.apps.cluster-denver-8ab6.denver-8ab6.example.opentlc.com/blue/organizations/jenkins/user2-er-tools%2Fuser2-er-tools-user2-mission-service-pipeline/detail/user2-er-tools-user2-mission-service-pipeline/1/
      ```
   3. Open a browser tab and navigate to the provided URL:
      ![](/images/pipeline_example.png)


## 2.6. Troubleshooting A Failed Deployment
Considering that the automated provisioning of ER-Demo consists of many hundreds of discrete steps, errors can occur from time to time.

The good news is that at least you have full cluster-admin access to your OpenShift cluster to troubleshoot.  This is where your OpenShift skills will be of great assistance.

### 2.6.1. Ansible Hints

Normally you can get a ball-park approximation as to where the provisioning failed by studying the ansible output. ie:

````
TASK [../roles/openshift_process_service : deploy postgresql] ****************************************************************************************************************************************************
fatal: [localhost]: FAILED! => {"changed": false, "msg": {"cmd": "oc create -f /tmp/process-service-4LN1V4/postgresql.yml -n user1-er-demo", "results": {}, "returncode": 1, "stderr": "Error from server (AlreadyExists): persistentvolumeclaims \"process-service-postgresql\" already exists\n", "stdout": "service/process-service-postgresql created\ndeploymentconfig.apps.openshift.io/process-service-postgresql created\n"}}

NO MORE HOSTS LEFT ***********************************************************************************************************************************************************************************************

PLAY RECAP *******************************************************************************************************************************************************************************************************
localhost                  : ok=16   changed=8    unreachable=0    failed=1    skipped=1    rescued=0    ignored=0  
````

The above log alludes to a problem provisioning the postgresql database for the _process-service_.
For further troubleshooting assistance, feel free to reach out to the community at:  emer-demo-team at redhat dot com .

### 2.6.2. Idempotency

Also of good news is that the ansible itself is idempotent.
In particular, it is feasible to re-run the ansible more than one time without introducing unintended consequences.

As a short-cut, you may not have to re-run the entire install playbook.
Included are playbooks for each service that make up the ER-Demo.

`````
$ ls playbooks/

assignment_rules_model.yml      emergency_console.yml          incident_service.yml  kafka_lag_exporter.yml  monitoring.yml       responder_client_app.yml
assignment_rules.yml            erd_monitoring.yml             install.yml           kafka_topics.yml        nexus.yml            responder_service.yml
datagrid.yml                    find_service.yml               jenkins.yml           knative.yml             pgadmin4.yml         responder_simulator_service.yml
datawarehouse.yml               group_vars                     kafdrop.yml           library                 postgresql.yml       sso_realm.yml
disaster_service.yml            incident_priority_service.yml  kafka_cluster.yml     mission_service.yml     process_service.yml  sso.yml
disaster_simulator_service.yml  incident_process.yml           kafka_connect.yml     module_utils            process_viewer.yml   strimzi_operator.yml

`````

For example, to re-install just the _process-service_, the following could be executed:

`````
$ ansible-playbook -i inventories/inventory playbooks/process_service.yml -e ACTION=uninstall

$ ansible-playbook -i inventories/inventory playbooks/process_service.yml
`````


## 2.7. Uninstall

To uninstall:

```
$ ansible-playbook -i inventory \
                   playbooks/install.yml \
                   -e ACTION=uninstall \
                   -e uninstall_cluster_resources=true \
                   -e uninstall_delete_project=true
```
## 2.8. Advanced Multi-User Installation

The ER-Demo ansible provisioning allows for more than one ER-Demo installations per OpenShift cluster.
This becomes useful, for example, when using the ER-Demo as the basis of customer and/or partner workshops where each student would be assigned their own demo environment.

Its often the case that a fresh OpenShift cluster can accommodate more than one ER-Demo environment. 
Mileage will vary depending on the amount of available hardware resources.
For example, the _OCP4 for ER-Demo_ cluster available through RHPDS can typically run about 5 concurrent ER-Demo environments.

The ansible provisioning segregates ER-Demo environments on the same OpenShift cluster by OpenShift users.
This can be done by applying the _project_admin_ environment variable to each ansible command as follows:

1. Set an environment variable that reflects the userId of your non cluster-admin user.  ie:
   ```
   OCP_USERNAME=user2
   ```
   
2. From the _install/ansible_ directory, kick-off the Emergency Response app provisioning:
   ```
   ansible-playbook -i inventories/inventory playbooks/install.yml \
                    -e project_admin=$OCP_USERNAME
   ```

3. To uninstall:
   ```
    $ ansible-playbook playbooks/install.yml \
                   -e ACTION=uninstall \
                   -e project_admin=$OCP_USERNAME \
                   -e uninstall_cluster_resources=true \
                   -e uninstall_delete_project=true
   ```



# 3. ER-Demo Operator Image Upgrade
This section describes the procedure for updating the ER-Demo Operator container images using an updated ER-Demo ansible playbook.


There are 3 ER-Demo related container images that are updated during this process:
*  quay.io/emergencyresponsedemo/erdemo-operator-bundle
*  quay.io/emergencyresponsedemo/erdemo-operator-catalog
*  quay.io/emergencyresponsedemo/erdemo-operator

## 3.1. Pre-reqs
1. Install the ansible based operator-sdk and check its version at the command line:
   `````
   $ operator-sdk version

   operator-sdk version: "v1.1.0", commit: "9d27e224efac78fcc9354ece4e43a50eb30ea968", kubernetes version: "v1.18.2", go version: "go1.15.2 linux/amd64", GOOS: "linux", GOARCH: "amd64"
   `````

1.  Install the opm utility and check its version at the command line:
    `````
    $ opm version

    Version: version.Version{OpmVersion:"v1.15.0", GitCommit:"bf13cb4", BuildDate:"2020-10-27T20:59:33Z", GoOs:"linux", GoArch:"amd64"}
    `````

1. Install podman and buildah utilities and check versions:
   `````
   $ podman version

     Version:      2.1.1
     API Version:  2.0.0

   $ buildah version

     Version:         1.16.2
     Go Version:      go1.15
     Image Spec:      1.0.1-dev
     Runtime Spec:    1.0.2-dev
     CNI Spec:        0.4.0
     libcni Version:  
     image Version:   5.5.2
   `````


## 3.2. Procedure

1. Clone this git project and change directories into the project:
   `````
   $ git clone htps://github.com/Emergency-Response-Demo/erdemo-operator.git \
         && cd erdemo-operator
   `````

1. Set environment variables called: `VERSION` and `IMG`:
   `````
   $ export VERSION=2.10.3
   $ export IMG=quay.io/emergencyresponsedemo/erdemo-operator:$VERSION
   `````

2. Create the `erdemo-operator-bundle` container image:
   1. Make the bundle
      `````
      $ make bundle
      `````

   1. Comment out the `replaces` attribute in `bundle/manifests/erdemo-operator.clusterserviceversion.yaml` (at about line 208)
      ````
      #  replaces: erdemo-operator.v2.10.2
      ````
   
   2. Execute:
      `````
      $ make bundle-build
      $ podman tag localhost/erdemo-operator-bundle:$VERSION quay.io/emergencyresponsedemo/erdemo-operator-bundle:$VERSION
      $ podman push quay.io/emergencyresponsedemo/erdemo-operator-bundle:$VERSION
      `````

3. Create the `erdemo-operator-catalog` container image:
   `````
   $ opm index add -p podman --bundles quay.io/emergencyresponsedemo/erdemo-operator-bundle:$VERSION --tag quay.io/emergencyresponsedemo/erdemo-operator-catalog:$VERSION
   $ podman push quay.io/emergencyresponsedemo/erdemo-operator-catalog:$VERSION
   `````

4. Create the `erdemo-operator` container image:
   `````
   $ buildah bud -f Dockerfile -t quay.io/emergencyresponsedemo/erdemo-operator:$VERSION .
   $ podman push quay.io/emergencyresponsedemo/erdemo-operator:$VERSION
   `````


# 4. Operator Development and Test
To install:
1. Clone this repository and `cd` into it.
```
git clone https://github.com/Emergency-Response-Demo/erdemo-operator
cd erdemo-operator 
```
2. Ensure you're logged in with `oc` as a `cluster-admin`
3. Run `hack/operate.sh` to install the `CustomResourceDefinition` and accompanying assets, and to create a `Deployment` for the operator. It will be created in the `erdemo-operator-system` namespace.
4. Create an `ErDemo` Custom Resource: `oc apply -n erdemo-operator-system -f config/samples/apps_v1alpha1_erdemo.yaml`
5. Watch the progress in the logs of the `erdemo-operator-controller-manager` pod.

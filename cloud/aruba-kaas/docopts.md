<!---
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->
# Tasks  `ops cloud aruba-kaas`

Create and Manage Aruba KaaS cluster

## Synopsis

```text
Usage:
  aruba-kaas connect <kubeconfig>
  aruba-kaas create <kubeconfig>
  aruba-kaas deploy <apihost>
  aruba-kaas elastic-ip
  aruba-kaas fix-mongodb-permissions
  aruba-kaas create-lb <namespace> <deployment> <service>
  aruba-kaas delete
  aruba-kaas info
  aruba-kaas kubeconfig <kubeconfig>
  aruba-kaas status
```

## Commands

```
  connect     import Aruba KaaS kubeconfig (absolute path or ~/.kube/<file>) and verify cluster connectivity
  create      connect an existing Aruba KaaS k3s cluster and install cert-manager
  deploy      configure and deploy Nuvolaris using <apihost>
  elastic-ip  provision and attach an Elastic IP via Aruba API (uses KAAS_API_KEY from .env)
  fix-mongodb-permissions  apply mongodb/ferretdb PVC permission fix (fsGroup) and restart StatefulSet
  create-lb   expose a deployment with Service type LoadBalancer on ports 80 and 443
  delete      force delete namespace nuvolaris (including finalizer cleanup)
  info        info on the current Aruba KaaS cluster context
  kubeconfig  import Aruba KaaS kubeconfig from local file (absolute path or ~/.kube/<file>)
  status      status of the current Aruba KaaS cluster
```

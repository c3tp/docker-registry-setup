# Information on deploying the container registry onto k8s with authn/authz configs. 
## AUTHZ SERVER
The authz basic server is just a basic prototype to show that you can connect to the authn server and set up basic acls that can be configured by rest endpoints. 

The rest endpoints are as follows: 

## AUTHN SERVER 
authn server for the k8s image is from https://github.com/cesanta/docker_auth.
The authn server allows you to deploy an external script to build hooks into it, so i did that to get it to network against the authz basic server. 

but change their dockerfile form busybox to something that can install curl, because we needed curl to deploy the external auth configs. 

## Changing the deploy from compose to k8s files. 
Use [kompose](https://github.com/kubernetes/kompose). It doesn't do most of the work with the configmaps/volumes however, so you'll need to convert that yourself. 

Docs on [services](https://kubernetes.io/docs/concepts/services-networking/service/), [configmap mounting](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) and [persistentvolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) are pretty robust. May want to config the certs to be secrets instead but the current ones are just cheap throwaways so that's not an issue atm. 

Note that named ports can be accessed like services, so you can use them that way if you want, but I wouldn't recommend it because of Separation of Concerns. 


## Deploying on the k8s deploys. 

Converted the docker-compose resource to k8s resources and deployed them. 
Was able to get it working, but requires you to deploy 
authz_server, then auth_server, then registry_server in that order. 

The authz server is composed of: 
- a deployment.
- service representing the deploy.

The authn server is composed of: 
- a deployment.
- service representing the deploy.
- configmaps for the settings.
- volume mount for logs.
- configmaps for the certs. 

The container registry is composed of:
- a deployment.
- a service representing the deploy. 
- configmaps for the settings. 
- volume mount for the images. 
- configmaps for the certs. 


Simplest way is to create the configmaps and the pvcs first. 

You'll need the configmaps for certs, authn_server, and registry.
You'll need a pvc to store the data for the registry. We use the OS cinder deploys for our case.
There's an empty dir volume for logs of the authn server. that's auto generated so you don't have to consider that. 

You'll want to generate real certs in a real deploy. 
Commands to generate the configmaps are as follows.
```
kubectl create configmap certs-config --from-file=certs/ -o yaml 
cd registry && kubectl create configmap registry-config --from-file=conf/ -o yaml && cd -
cd auth && kubectl create configmap authn-config --from-file=config/ -o yaml && cd -
```

Then you can just create the services/deployments in order. 

```
kubectl create -f authz-deployment.yaml
kubectl create -f authz-service.yaml
kubectl create -f auth-deployment.yaml
kubectl create -f auth-service.yaml
kubectl create -f registry-pvc.yaml
kubectl create -f registry-deployment.yaml
```

Then you can access it via the nodeport port on one of the accessible nodes. 

## Problems and issues 

### Requires that the servers are deployed in a specific order. 

Attempted to do some work to change this, but there wasn't any nice way to automatically find a service that met your needs. Essentially, it works like DNS. You need to know the name of your website/service before you can use it. 

https://kubernetes.io/docs/concepts/services-networking/service/#discovering-services

So you can use it to have the env vars deployed or use a dns server. DNSmasq generates that for us. 
So we can just use it w/o having to use env_vars, otherwise that was an option. 

### Certs are hardwired 
This means the config map for certs need to restart every few weeks.

Remove certs and push that forward so that we can run ssl termination and have k8s ingresses do our letsencrypt SSL work. 

### PVC based backend. 
No site failover or multisite backing. 

Switch to different backend. K8s supports ceph and nfs and s3, so in theory we could use the botched WOS for things. 



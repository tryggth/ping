#!/usr/bin/env /bin/bash

echo -n -e "\033]0;Main demo window\007"

# create cluster
gcloud beta container clusters create demo --cluster-version=1.6.4 --enable-autorepair --enable-autoupgrade --num-nodes=3 --machine-type=n1-standard-2
# get the credentials
gcloud container clusters get-credentials demo

# install helm
helm init
watch kubectl -n kube-system get pods

# install concourse
helm install --namespace concourse --name concourse --set concourse.password=Bugopolis0 --set web.service.type=LoadBalancer stable/concourse

# install deis/workflow
#helm install --namespace deis --name deis --set router.service_type=LoadBalancer --set controller.platform_domain=deis.tryggth.com deis/workflow

# install istio
cd /Users/jwalters/istio-0.1.6
export PATH=$PWD/bin:$PATH

kubectl apply -f install/kubernetes/istio-rbac-beta.yaml
kubectl apply -f install/kubernetes/istio-auth.yaml

kubectl apply -f install/kubernetes/addons/prometheus.yaml
kubectl apply -f install/kubernetes/addons/grafana.yaml
kubectl apply -f install/kubernetes/addons/servicegraph.yaml
kubectl apply -f install/kubernetes/addons/zipkin.yaml
watch kubectl get pods --all-namespaces

#osascript -e 'tell application "Terminal" to activate' -e 'tell application "System Events" to tell process "Terminal" to keystroke "t" using command down'

# open the dashboard
(kubectl proxy &); PROXY_PID=$!
sleep 10
open http://localhost:8001/ui

# set concourse ingress
export CONCOURSE_SERVICE_IP=$(kubectl get svc --namespace concourse concourse-web -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
open http://$CONCOURSE_SERVICE_IP:8080

kubectl port-forward $(kubectl get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
sleep 10
open http://localhost:3000/dashboard/db/istio-dashboard

kubectl port-forward $(kubectl get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &
sleep 10
open http://localhost:8088/dotviz

kubectl port-forward $(kubectl get pod -l app=zipkin -o jsonpath='{.items[0].metadata.name}') 9411:9411 &
sleep 10
open http://localhost:9411

cd /Users/jwalters/demo
ingressip=$(kubectl get ingress -o wide | fgrep gateway | awk '{print $3}')
GATEWAY_URL=$ingressip:80
export GATEWAY_URL


#kubectl create -f <(istioctl kube-inject -f cowsay.yaml)
#watch -n1 kubectl get pods
#watch curl -s $GATEWAY_URL
#
#cat routerules.yaml
#
#istioctl create -f routerules.yaml
#watch curl -s $GATEWAY_URL
#
#$kubectl create -f <(istioctl kube-inject -f cowsay-v2.yaml)
#watch -n1 kubectl get pods

#cd /Users/jwalters/istio-0.1.6
#kubectl apply -f <(istioctl kube-inject -f samples/apps/bookinfo/bookinfo.yaml)
#watch kubectl get services
#watch kubectl get pods

#curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
#open http://$GATEWAY_URL/productpage
#
#open http://localhost:8088/dotviz

# routing task
# create a default route
#istioctl create -f samples/apps/bookinfo/route-rule-all-v1.yaml
#istioctl get route-rules -o yaml

# now route user jason to v2 of reviews
#istioctl create -f samples/apps/bookinfo/route-rule-reviews-test-v2.yaml
#istioctl get route-rule reviews-test-v2

# now lets move 50% traffic to v3.
#istioctl replace -f samples/apps/bookinfo/route-rule-reviews-50-v3.yaml

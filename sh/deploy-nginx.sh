# to make a deployment
kubectl create deploy nginx -n default --image=nginx
kubectl create deploy nginx -n fluent --image=nginx
# to make a service
kubectl expose deploy/nginx -n default --port=80
kubectl expose deploy/nginx -n fluent --port=80

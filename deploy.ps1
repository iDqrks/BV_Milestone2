# deploy.ps1 - Windows PowerShell deployment script for MariaDB + Lighttpd

Write-Host "Creating Kind cluster..." -ForegroundColor Green
kind create cluster --config kind-config.yaml

Write-Host "Building Docker images..." -ForegroundColor Green
docker build -t milestone-frontend:latest ./frontend
docker build -t milestone-api:latest ./api

Write-Host "Loading images into Kind cluster..." -ForegroundColor Green
kind load docker-image milestone-frontend:latest --name milestone-cluster
kind load docker-image milestone-api:latest --name milestone-cluster

Write-Host "Deploying NGINX Ingress Controller..." -ForegroundColor Green
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

Write-Host "Waiting for ingress controller..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

Write-Host "Creating namespace..." -ForegroundColor Green
kubectl apply -f k8s/namespace.yaml

Write-Host "Deploying MariaDB..." -ForegroundColor Green
Get-ChildItem -Path "k8s/Database" -Filter "*.yaml" | ForEach-Object { kubectl apply -f $_.FullName }

Write-Host "Waiting for MariaDB..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
kubectl wait --namespace milestone-app --for=condition=ready pod --selector=app=mariadb --timeout=120s

Write-Host "Deploying API..." -ForegroundColor Green
Get-ChildItem -Path "k8s/api" -Filter "*.yaml" | ForEach-Object { kubectl apply -f $_.FullName }

Write-Host "Deploying frontend..." -ForegroundColor Green
Get-ChildItem -Path "k8s/frontend" -Filter "*.yaml" | ForEach-Object { kubectl apply -f $_.FullName }

Write-Host "Waiting for all pods to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
kubectl wait --namespace milestone-app --for=condition=ready pod --all --timeout=120s

Write-Host "Cluster status:" -ForegroundColor Cyan
kubectl get pods -n milestone-app

Write-Host "Services:" -ForegroundColor Cyan
kubectl get svc -n milestone-app

Write-Host "" -ForegroundColor Green
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Access your application at:" -ForegroundColor Yellow
Write-Host "Frontend: http://milestone.local" -ForegroundColor White
Write-Host "API: http://api.milestone.local" -ForegroundColor White
Write-Host "" -ForegroundColor Yellow
Write-Host "Add these entries to your C:\Windows\System32\drivers\etc\hosts file:" -ForegroundColor Yellow
Write-Host "127.0.0.1 milestone.local" -ForegroundColor White
Write-Host "127.0.0.1 api.milestone.local" -ForegroundColor White

Write-Host "" -ForegroundColor Green
Write-Host "Test the application:" -ForegroundColor Yellow
Write-Host "1. Open browser to: http://milestone.local" -ForegroundColor White
Write-Host "2. Update user name: kubectl exec -n milestone-app deployment/api-deployment -- python -c `"import requests; requests.put('http://localhost:8000/user/NewName')`"" -ForegroundColor White
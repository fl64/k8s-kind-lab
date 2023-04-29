#! /usr/bin/env bash

set -x
echo host
kubectl -n prober exec -it deploy/prober -- dig +short echo-0.echo.echo.svc.cluster.local
kubectl -n echo exec -it sts/echo -- dig +short echo-0.echo.echo.svc.cluster.local
echo svc
kubectl -n prober exec -it deploy/prober -- dig +short echo.echo.svc.cluster.local
kubectl -n echo exec -it sts/echo -- dig +short echo.echo.svc.cluster.local

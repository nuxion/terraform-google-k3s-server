.EXPORT_ALL_VARIABLES:
# VERSION := $(shell git describe --tags)
# BUILD := $(shell git rev-parse --short HEAD)
# PROJECTNAME := $(shell basename "$(PWD)")
PROJECT := $(shell echo "${PROJECT}")
REGION := us-central1
ZONE := us-central1-c
BASE_PATH := $(shell git rev-parse --show-toplevel)

init:
	terraform init

.PHONY: plan
plan:
	terraform plan -var 'region=${REGION}' -var 'zone=${ZONE}' -var 'bucket=${BUCKET}' -var 'project_id=${PROJECT}' -out=/tmp/terraform.plan

.PHONY: apply
apply:
	terraform apply /tmp/terraform.plan
	rm /tmp/terraform.plan

refresh:
	terraform apply -refresh-only

.PHONY: apply
destroy:
	terraform destroy -var 'region=${REGION}' -var 'zone=${ZONE}' -var 'project_id=${PROJECT}'  -var 'bucket=${BUCKET}'

.PHONY: force-unlock
force-unlock:
	terraform force-unlock ${LOCK}

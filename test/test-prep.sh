#!/bin/bash
#
# Copyright 2018 The Kubeflow Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -x

# Ensure the kubeflow namespace exists
kubectl create namespace kubeflow || true

# If your tests need specific setup, you can add those here.
# For example, setting up any required CRDs, services, etc.

# Sample setup: Apply some manifests (this is just an example, replace with your actual setup)
# kubectl apply -f some-manifest.yaml -n kubeflow

# Set up any other environment variables or configuration as needed
echo "Test environment setup for Kind cluster is complete"

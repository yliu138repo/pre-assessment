# pre-assessment

# Part I
## Assumptions
- No CI/CD pipelines are enabled in this project for simplicity purpose. All image build, push operations etc. are manual.


1. Compose the Dockerfile with multistages and alpine image to ensure minimal image size. Also make sure the container is run with non-root user to ensure security best practices. Refer to the [Dockerfile](./Dockerfile)
2. Run commands with [makefile](./Makefile) for ease with debugging and running
3. In the golang program provided, I found out the server is specifically bound to 127.0.0.1. This also fails the container with port-forwarding too. The code is modified to listen to all traffic by removing the specific IP address. Refer to [main.go](./main.go)
4. Test and run container locally and verify the connectivity by running `curl http://localhost:8080`

# Part 2 - Containerisation
## Assumptions:
- For demonstration purpose, VM A and VM B are AWS EC2 instances within the same VPC using the same account. 
- Multi AZ are not considered for this assessment.
- Performance is not a consideration in this project and hence t2.micro EC2 type is selected for demo purpose.
- VM A sits in public subnet while VM B sits in private subnet. VM a will be able to connect to VM B web servers via private IP address.
- Assign static IP address to VM B for the simplicity purpose. However, in production, better use DNS-based strategies for VM B to ensure scalabiilty and IP management. 
- Terraform is leveraged to automate and manage the infrastructure provisions. However, versioning and regular backup of Terraform statefile is not enabled.
- The infrastructure auotmation is simplified for demonstration purposes. There is only one single environment (Dev) for this project.
- Currently use the github repo as the image repository. But for security consideraiton, in production, the EC2 instance within the private subnet could use ECR VPC endpoints (AWS privatelink) to avoid internet exposure.


## Pre-Requisites
- In the bootstrap folder, run `terraform apply` to create the s3 bucket for remote terraform statefile.
- Make sure the image are updated on dockerhub `leoliu1988/go-server:v1.0.0:v1.0.0`

## Provision
```bash
terraform fmt
terraform validate
terraform plan -out plan.tfplan -var-file=dev.tfvars
terraform apply -auto-approve plan.tfplan
```

## output
curl command from VM A
```bash
# vma_private_ip = "10.0.1.154"
# vma_public_ip = "44.203.187.218"
# vmb_private_ip = "10.0.2.77"
# vmb_public_ip = ""
[ec2-user@ip-10-0-1-127 (VMA) ~]$ curl -vvv http://10.0.2.77:8080
*   Trying 10.0.2.77:8080...
* Connected to 10.0.2.77 (10.0.2.77) port 8080
> GET / HTTP/1.1
> Host: 10.0.2.77:8080
> User-Agent: curl/8.3.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Date: Mon, 09 Jun 2025 07:23:42 GMT
< Content-Length: 14
< Content-Type: text/plain; charset=utf-8
< 
Hello, World!
* Connection #0 to host 10.0.2.77 left intact
```

Container logs from curl command:
```bash
[ec2-user@ip-10-0-2-77 ~]$ sudo docker logs web_server -f
2025/06/09 07:23:03 Server listening on http://:8080
```
## Simulate errors
create a paylod.json file with 
```bash
{
  "fail": true
}
```
Run command
```bash
# in the VM A instance
curl -X POST -H "Content-Type: application/json" -d @payload.json http://10.0.2.77:8080
```

# Part 3 - Proxy
## Assumption:
- nginx is used as the reverse proxy, listening to backend golang web server via private IP address, and exposed port 80 to outside

## Outputs
```bash
# note the public static IP address of VM A is 52.21.82.1
❯ curl  http://52.21.82.1
Hello, World!
```

# Part 4 - TLS
## Assumptions
- self-signed certificate (/certs/) is used for this project. In prod, it should be used with trusted CA. (Refer to user_data section for `resource "aws_instance" "vma"`)

## pre-requisites
- Install self-signed certs (VM A: /certs/nginx.crt) and reference self-signed certificate on local machine to perform tests. 

## Outputs
```bash
❯ curl --cacert ../build/selfsigned.crt https://goserver.yoursafespace.com.au
Hello, World!
```

# Summary
## Architecture Design
- Balance the simplicity and flexibility. Since this is a 2 VMs architecture, it might be overkill to leverage container orchestration with network overlay between containers such as k8s or docker swarm.
- Enhance security by placing VM A in public subnet while VM B in private subnet. This setup minimizes the attack surface, as only VM A in the public subnet is accessible from the internet.
- Security groups and network NACL are leveraged to define layered security for networks.
- Implement NAT for Private Subnet to pull images from github repo.
- Elastic IP is used to ensure static IP address for VM A instance.
- Simulate container auto-restart by leveraging docker restart policy (like k8s deployment)
- IaC using Terraform to automate the provision
- Golang web server is modified to listen to all traffic (0.0.0.0/0) rather than 127.0.0.1.  Also modify to gracefully server stops and simulate fail path for the web server.

## Limitations
- Single point of failure as If VM A serves as the sole access point to VM B, its failure could disrupt access to backend services. Implementing redundancy and failover mechanisms is essential to mitigate this risk.
- The infrastructure is not auto-scalable. It would be vulnerable in the events of high volume of traffic and resource shortage on the VMs. 
- No observability are enabled on the workloads, such as CPU/memory utilisation on the golang web server and alerting. Use cloudwatch and VPC flow logs to monitor traffic patterns and detect unusual activities.
- ECR with private link should be leveraged instead of github repo through Internet.
- Self-signed cert is utilised for TLS connection. However, in production environment, a proper CA should be set up, e.g Lets encrypt.

# Future works
- Enable CI/CD pipeline automation for image build, push and infrastructure provisons

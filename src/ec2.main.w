bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as aws;

// let ami = "ami-00c71bd4d220aa22a"; // Canonical, Ubuntu, 22.04 LTS, amd64 jammy image build on 2024-03-01
// let userData = "#!/bin/bash
// sudo apt update
// sudo apt install -y build-essential cmake git
// git clone https://github.com/coilhq/tigerbeetle.git tigerbeetle-src
// ./tigerbeetle-src/bootstrap.sh

// ./tigerbeetle-src/tigerbeetle format --cluster=0 --replica=0 --replica-count=1 0_0.tigerbeetle

// ./tigerbeetle-src/tigerbeetle start --addresses=3000 0_0.tigerbeetle
// ";

// let ami = "ami-0720246d895625a23"; // Amazon Linux 2 Kernel 5.10 AMI 2.0.20240329.0 x86_64 HVM gp2
// let instanceType: "t2.nano";
let ami = "ami-0e8a62bd8368b0881"; // Amazon Linux 2 LTS Arm64 Kernel 5.10 AMI 2.0.20240329.0 arm64 HVM gp2
// let instanceType = "t4g.nano";
// let instanceType = "t4g.micro";
// let instanceType = "t4g.small";
let instanceType = "t4g.large";
let userData = "#!/bin/bash
sudo yum update -y
sudo yum install git unzip -y
sudo mkdir /app
sudo chmod 777 /app
cd /app
git clone https://github.com/coilhq/tigerbeetle.git tigerbeetle-src --no-depth
./tigerbeetle-src/bootstrap.sh
./tigerbeetle-src/tigerbeetle format --cluster=0 --replica=0 --replica-count=1 0_0.tigerbeetle
./tigerbeetle-src/tigerbeetle start --addresses=0.0.0.0:3000 0_0.tigerbeetle
";

let vpc = new aws.vpc.Vpc(
   cidrBlock: "10.0.0.0/16",
   enableDnsSupport: true,
   enableDnsHostnames: true,
);

let publicSubnet = new aws.subnet.Subnet(
   vpcId: vpc.id,
   cidrBlock: "10.0.0.0/24", // 10.0.0.0 - 10.0.0.255
   availabilityZone: "eu-west-3a",
) as "PublicSubnet";

let privateSubnet = new aws.subnet.Subnet(
   vpcId: vpc.id,
   cidrBlock: "10.0.4.0/22", // 10.0.4.0 - 10.0.7.255
   availabilityZone: "eu-west-3a",
) as "PrivateSubnet";

let internetGateway = new aws.internetGateway.InternetGateway(
   vpcId: vpc.id,
);

let publicIp = new aws.eip.Eip({
   domain: "vpc",
});

let natGateway = new aws.natGateway.NatGateway(
   allocationId: publicIp.id,
   subnetId: publicSubnet.id,
);

let publicRouteTable = new aws.routeTable.RouteTable(
   vpcId: vpc.id,
   route: [
      {
         // This will route all traffic to the internet gateway
         cidrBlock: "0.0.0.0/0",
         gatewayId: internetGateway.id,
      },
   ],
) as "PublicRouteTable";

let privateRouteTable = new aws.routeTable.RouteTable(
   vpcId: vpc.id,
   route: [
     {
       // This will route all traffic to the NAT gateway
       cidrBlock: "0.0.0.0/0",
       natGatewayId: natGateway.id,
     },
   ],
) as "PrivateRouteTable";

new aws.routeTableAssociation.RouteTableAssociation(
   subnetId: publicSubnet.id,
   routeTableId: publicRouteTable.id,
) as "PublicRouteTableAssociation";

new aws.routeTableAssociation.RouteTableAssociation(
   subnetId: privateSubnet.id,
   routeTableId: privateRouteTable.id,
) as "PrivateRouteTableAssociation";

let securityGroup = new aws.securityGroup.SecurityGroup(
   vpcId: vpc.id,
   ingress: [
     {
       fromPort: 3000,
       toPort: 3000,
       protocol: "tcp",
       cidrBlocks: ["0.0.0.0/0"],
     },
   ],
   egress: [
     {
       fromPort: 0,
       toPort: 0,
       protocol: "-1", // Allow all outbound traffic
       cidrBlocks: ["0.0.0.0/0"],
     },
   ],
);

let instance = new aws.instance.Instance(
   ami: ami,
   instanceType: instanceType,
   userData: userData,
   associatePublicIpAddress: true,
   subnetId: privateSubnet.id,
   vpcSecurityGroupIds: [securityGroup.id],
   iamInstanceProfile: "SSM",
   // rootBlockDevice: {
   //    volumeType: "gp3",
   //    volumeSize: 16, // Specifies the volume size in GB
   //    deleteOnTermination: true,
   // },
);


new cdktf.TerraformOutput(
   value: instance.publicIp,
) as "InstancePublicIP";

new cdktf.TerraformOutput(
   value: publicIp.publicIp,
) as "PublicIP";

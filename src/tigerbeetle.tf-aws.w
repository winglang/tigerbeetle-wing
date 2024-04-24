bring cloud;
bring fs;
bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as aws;
bring "./tigerbeetle.types.w" as types;

pub class TigerBeetleTfAws {
   pub replicaAddresses: Array<str>;
   pub clusterId: str;
   pub replicaCount: num;
   new(props: types.TigerBeetleProps) {
      this.clusterId = props.clusterId;
      this.replicaCount = 2;

      let securityGroup = new aws.securityGroup.SecurityGroup(
         vpcId: props.vpcId,
         ingress: [
            {
               description: "TigerBeetle",
               fromPort: 3000,
               toPort: 3000,
               protocol: "tcp",
               cidrBlocks: ["0.0.0.0/0"],
            },
            {
               description: "SSH",
               fromPort: 22,
               toPort: 22,
               protocol: "tcp",
               cidrBlocks: ["0.0.0.0/0"],
            },
         ],
         egress: [
            {
               fromPort: 0,
               toPort: 0,
               protocol: "-1",
               cidrBlocks: ["0.0.0.0/0"],
            },
         ],
      );

      let publicKey = fs.readFile("data/orchestrator-key.pub");

      let keyPair = new aws.keyPair.KeyPair(
         publicKey: publicKey,
      );

      let replicas = MutArray<aws.instance.Instance>[];
      let replicaAddresses = MutArray<str>[];
      for replicaIndex in 0..this.replicaCount {
         let replica = new aws.instance.Instance(
            ami: "ami-0e8a62bd8368b0881", // Amazon Linux 2 LTS Arm64 Kernel 5.10 AMI 2.0.20240329.0 arm64 HVM gp2.
            instanceType: "t4g.medium", // Minimum size that worked for the AMI above.
            userData: [
               "#!/bin/bash",
               "yum update -y",
               "yum install git unzip -y",
               "git clone https://github.com/coilhq/tigerbeetle.git /tigerbeetle --no-depth",
               "/tigerbeetle/bootstrap.sh",
               "mv /tigerbeetle/tigerbeetle /usr/local/bin",
               "cp /tigerbeetle/tools/systemd/tigerbeetle-pre-start.sh /usr/local/bin",
               "cp /tigerbeetle/tools/systemd/tigerbeetle.service /etc/systemd/system",
               "rm -rf /tigerbeetle",
            ].join("\n"),
            associatePublicIpAddress: true,
            subnetId: props.subnetId,
            vpcSecurityGroupIds: [securityGroup.id],
            keyName: keyPair.keyName,
         ) as "Replica-{replicaIndex}";
         replicas.push(replica);
         replicaAddresses.push("{replica.publicIp}:3000");
      }

      this.replicaAddresses = replicaAddresses.copy();

      let addressesString = replicaAddresses.join(",");
      new cdktf.TerraformOutput(
         value: addressesString,
      ) as "ReplicaAddresses";

      let orchestratorReplicasUserData = MutArray<str>[];
      for replicaIndex in 0..this.replicaCount {
         let replica = replicas.at(replicaIndex);

         let localAddresses = replicaAddresses.copy().copyMut();
         localAddresses.set(replicaIndex, "0.0.0.0:3000");

         let serviceOverrides = [
            "[Service]",
            "Environment=TIGERBEETLE_ADDRESSES={localAddresses.join(",")}",
            "Environment=TIGERBEETLE_REPLICA_COUNT={this.replicaCount}",
            "Environment=TIGERBEETLE_REPLICA_INDEX={replicaIndex}",
            "Environment=TIGERBEETLE_CLUSTER_ID={this.clusterId}",
            "Environment=TIGERBEETLE_DATA_FILE=/tigerbeetle-data/{this.clusterId}_{replicaIndex}.tigerbeetle",
            "",
         ];
   
         let orchestratorRemoteScript = [
            "sudo mkdir -p /tigerbeetle-data/",
            "sudo chmod 777 /tigerbeetle-data/",
            "sudo mkdir -p /etc/systemd/system/tigerbeetle.service.d/",
            "sudo touch /etc/systemd/system/tigerbeetle.service.d/override.conf",
            "sudo chown ec2-user:ec2-user /etc/systemd/system/tigerbeetle.service.d/override.conf",
            "printf \"{serviceOverrides.join("\\n")}\" > /etc/systemd/system/tigerbeetle.service.d/override.conf",
            "sudo chown root:root /etc/systemd/system/tigerbeetle.service.d/override.conf",
            "sudo systemctl daemon-reload",
            "sudo systemctl start tigerbeetle",
         ];
   
         new cdktf.TerraformOutput(
            value: replica.publicIp,
         ) as "ReplicaAddress-{replicaIndex}";

         orchestratorReplicasUserData.push(
            "echo '{orchestratorRemoteScript.join("\n")}' > /tigerbeetle-script-{replicaIndex}",
            "cat /tigerbeetle-script-{replicaIndex} | ssh -i /orchestrator-key ec2-user@{replica.publicIp} -o \"StrictHostKeyChecking no\" bash",
         );
      }

      let orchestrator = new aws.instance.Instance(
         ami: "ami-0e8a62bd8368b0881", // Amazon Linux 2 LTS Arm64 Kernel 5.10 AMI 2.0.20240329.0 arm64 HVM gp2.
         instanceType: "t4g.nano",
         userData: [
            "#!/bin/bash",
            "yum update -y",
            "yum install openssh-clients -y",
            "echo '{fs.readFile("data/orchestrator-key")}' > /orchestrator-key",
            "chmod 600 /orchestrator-key",
         ].concat(orchestratorReplicasUserData.copy()).join("\n"),
         associatePublicIpAddress: true,
         subnetId: props.subnetId,
         vpcSecurityGroupIds: [securityGroup.id],
         keyName: keyPair.keyName,
      ) as "Orchestrator";

      for replica in replicas {
         orchestrator.node.addDependency(replica);
      }

      new cdktf.TerraformOutput(
         value: orchestrator.publicIp,
      ) as "OrchestratorAddress";
   }
}

bring cloud;
bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as aws;
bring "./tigerbeetle.types.w" as types;

pub class TigerBeetleTfAws impl types.TigerBeetleClient {
   pub port: str;
   pub address: str;
   pub clusterId: str;
   pub replica: str;
   pub replicaCount: str;
   pub dataFilename: str;
   new(props: types.TigerBeetleProps) {
      this.clusterId = props.clusterId;
      this.replica = "0";
      this.replicaCount = "1";

      this.dataFilename = "{this.node.addr.substring(this.node.addr.length - 8)}.tigerbeetle";

      let instance = new aws.instance.Instance(
         ami: "ami-0e8a62bd8368b0881", // Amazon Linux 2 LTS Arm64 Kernel 5.10 AMI 2.0.20240329.0 arm64 HVM gp2."
         instanceType: "t4g.medium", // Minimum size that worked for the AMI above.
         userData: [
            "#!/bin/bash",
            "yum update -y",
            "yum install git unzip -y",
            "mkdir /app",
            "cd /app",
            "git clone https://github.com/coilhq/tigerbeetle.git tigerbeetle-src --no-depth",
            "./tigerbeetle-src/bootstrap.sh",
            "./tigerbeetle-src/tigerbeetle format --cluster={this.clusterId} --replica={this.replica} --replica-count={this.replicaCount} {this.dataFilename}",
            "./tigerbeetle-src/tigerbeetle start --addresses=0.0.0.0:3000 {this.dataFilename}",
         ].join("\n"),
         associatePublicIpAddress: props.associatePublicIpAddress,
         subnetId: props.subnetId,
         vpcSecurityGroupIds: props.vpcSecurityGroupIds,
      );

      this.port = "3000";
      this.address = "{instance.publicIp}:{this.port}";
   }

   extern "./tigerbeetle.inflight.ts" inflight static createClient(options: types.TigerBeetleClientOptions): types.TigerBeetleClient;

   inflight client: types.TigerBeetleClient;

   inflight new() {
      this.client = TigerBeetleTfAws.createClient(
         cluster_id: this.clusterId,
         replica_addresses: [
            this.address,
         ],
      );
   }

   pub inflight createAccounts(batch: Array<types.Account>): Array<types.CreateAccountsError> {
      return this.client.createAccounts(batch);
   }

   pub inflight createTransfers(batch: Array<types.Transfer>): Array<types.CreateTransfersError> {
      return this.client.createTransfers(batch);
   }

   pub inflight lookupAccounts(batch: Array<str>): Array<types.Account> {
      return this.client.lookupAccounts(batch);
   }
}

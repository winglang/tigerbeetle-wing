bring cloud;
bring util;
bring fs;
bring ui;
bring "./tigerbeetle.types.w" as types;
bring "./tigerbeetle.sim.w" as sim;
bring "./tigerbeetle.tf-aws.w" as tfaws;

pub class TigerBeetle impl types.TigerBeetleClient {
   pub replicaAddresses: Array<str>;
   pub clusterId: str;
   pub replicaCount: num;
   new(props: types.TigerBeetleProps) {
      let target = util.env("WING_TARGET");
      if target == "sim" {
         let implementation = new sim.TigerBeetleSim(props);
         nodeof(implementation).hidden = true;
         this.replicaAddresses = implementation.replicaAddresses;
         this.clusterId = implementation.clusterId;
         this.replicaCount = implementation.replicaCount;
      } elif target == "tf-aws" {
         let implementation = new tfaws.TigerBeetleTfAws(
            clusterId: props.clusterId,
         );
         nodeof(implementation).hidden = true;
         this.replicaAddresses = implementation.replicaAddresses;
         this.clusterId = implementation.clusterId;
         this.replicaCount = implementation.replicaCount;
      } else {
         throw "unsupported target {target}";
      }

      new ui.Field(
         "Cluster ID",
         inflight () => {
            return this.clusterId;
         },
      ) as "ClusterField";

      new ui.Field(
         "Replica Addresses",
         inflight () => {
            return this.replicaAddresses.join(", ");
         },
      ) as "ReplicaField";

      new ui.Field(
         "Replica Count",
         inflight () => {
            return "{this.replicaCount}";
         },
      ) as "ReplicaCountField";
   }

   extern "./tigerbeetle.inflight.ts" inflight static createClient(options: types.TigerBeetleClientOptions): types.TigerBeetleClient;

   inflight client: types.TigerBeetleClient;

   inflight new() {
      this.client = TigerBeetle.createClient(
         cluster_id: this.clusterId,
         replica_addresses: this.replicaAddresses,
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

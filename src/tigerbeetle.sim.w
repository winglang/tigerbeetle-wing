bring cloud;
bring sim;
bring util;
bring fs;
bring "./tigerbeetle.types.w" as types;

pub class TigerBeetleSim impl types.TigerBeetleClient {
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

      let state = new sim.State();
      nodeof(state).hidden = true;

      let resolvePwdService = new cloud.Service(inflight () => {
         let pwd = util.shell("echo $(pwd)").trim();
         state.set("pwd", pwd);
      }) as "ResolvePwdService";
      nodeof(resolvePwdService).hidden = true;
      let pwd = state.token("pwd");

      this.dataFilename = "{this.node.addr.substring(this.node.addr.length - 8)}.tigerbeetle";

      let createDataService = new cloud.Service(inflight () => {
         try {
            if fs.exists("{pwd}/data/{this.dataFilename}") == false {
               util.shell(
                  "docker run -v {pwd}/data:/data ghcr.io/tigerbeetle/tigerbeetle format --cluster={this.clusterId} --replica={this.replica} --replica-count={this.replicaCount} /data/{this.dataFilename}",
               );
            }
         } catch error {
            log("failed to format data file data/{this.dataFilename}. error: {error}");
            throw error;
         }
      }) as "CreateDataService";
      nodeof(createDataService).hidden = true;

      let container = new sim.Container(
         name: "tigerbeetle",
         image: "ghcr.io/tigerbeetle/tigerbeetle",
         containerPort: 3000,
         volumes: [
            "{pwd}/data:/data",
         ],
         args: [
            "start",
            "--cache-grid=256MiB", // smaller cache size for local development
             "--addresses=0.0.0.0:3000",
             "/data/{this.dataFilename}",
         ],
      );
      container.node.addDependency(createDataService);
      nodeof(container).hidden = true;

      this.port = state.token("port");
      this.address = state.token("address");
      let resolveService = new cloud.Service(inflight () => {
         state.set("port", container.hostPort);
         state.set("address", "127.0.0.1:{container.hostPort!}");
      }) as "ResolveService";
      nodeof(resolveService).hidden = true;
   }

   extern "./tigerbeetle.inflight.ts" inflight static createClient(options: types.TigerBeetleClientOptions): types.TigerBeetleClient;

   inflight client: types.TigerBeetleClient;

   inflight new() {
      this.client = TigerBeetleSim.createClient(
         cluster_id: this.clusterId,
         replica_addresses: [
            this.port,
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

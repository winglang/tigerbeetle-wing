bring cloud;
bring sim;
bring util;
bring fs;
bring "./tigerbeetle.types.w" as types;

pub class TigerBeetleSim {
   pub replicaAddresses: Array<str>;
   pub clusterId: str;
   pub replicaCount: num;
   new(props: types.TigerBeetleProps) {
      this.clusterId = props.clusterId;
      this.replicaCount = 1;

      let state = new sim.State();
      nodeof(state).hidden = true;

      let resolvePwdService = new cloud.Service(inflight () => {
         let pwd = util.shell("echo $(pwd)").trim();
         state.set("pwd", pwd);
      }) as "ResolvePwdService";
      nodeof(resolvePwdService).hidden = true;
      let pwd = state.token("pwd");

      let dataFilename = "{this.node.addr.substring(this.node.addr.length - 8)}.tigerbeetle";

      let createDataService = new cloud.Service(inflight () => {
         try {
            if fs.exists("{pwd}/data/{dataFilename}") == false {
               util.shell(
                  "docker run -v {pwd}/data:/data ghcr.io/tigerbeetle/tigerbeetle format --cluster={this.clusterId} --replica=0 --replica-count={this.replicaCount} /data/{dataFilename}",
               );
            }
         } catch error {
            log("failed to format data file data/{dataFilename}. error: {error}");
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
             "/data/{dataFilename}",
         ],
      );
      container.node.addDependency(createDataService);
      nodeof(container).hidden = true;

      this.replicaAddresses = [state.token("address")];
      let resolveService = new cloud.Service(inflight () => {
         state.set("address", "127.0.0.1:{container.hostPort!}");
      }) as "ResolveService";
      nodeof(resolveService).hidden = true;
   }
}

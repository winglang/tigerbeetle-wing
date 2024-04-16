bring cloud;
bring sim;
bring util;

class TigerBeetle {
   new() {
      let state = new sim.State();
      new cloud.Service(inflight () => {
         let pwd = util.shell("echo $(pwd)").trim();
         state.set("pwd", pwd);
      }) as "ResolvePwd";
      let pwd = state.token("pwd");

      let container = new sim.Container(
         name: "tigerbeetle",
         image: "ghcr.io/tigerbeetle/tigerbeetle",
         containerPort: 3000,
         volumes: [
            "{pwd}/data:/data",
         ],
         args: [
            "start",
             "--addresses=0.0.0.0:3000",
             "/data/0_0.0.tigerbeetle",
         ],
      );
      new cloud.Service(inflight () => {
         log("tigerbeetle is running on port {container.hostPort ?? ""}");
      });
   }
}

let tigerbeetle = new TigerBeetle();

// bring containers;
// new containers.Workload(
//   name: "tigerbeetle",
//   image: "ghcr.io/tigerbeetle/tigerbeetle",
//   port: 3000,
//   readiness: "/",
//   replicas: 4,
//   env: {
//     "MESSAGE" => "message",
//   },
// );

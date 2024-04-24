# tigerbeetle-wing

## How it works in AWS

1. A bunch of EC2 instances are deployed as TigerBeetle replicas. They will let the orchestrator know their IP addresses
2. The orchestrator will be deployed as a small EC2 instance, and will SSH into the replicas to start the TigerBeetle instances (using systemd)

## To improve

- [ ] Stop the orchestrator after the replicas are started
- [ ] Generate the SSH key using the CDKTF null provider as part of the deployment

## Scripts

### Install

```sh
pnpm install
```

### Dev

> [!WARNING] pnpm script runner (and npm > `10.5.2`) have a problem handling SIGTERM signals. This will cause the Wing Console not to stop and remove the docker containers. For now, you will have to manually stop the Wing Console and remove the docker containers:
>
> ```sh
> # Remove all docker containers (from previous runs)
> docker rm -f $(docker ps -aq)
> ```

```sh
pnpm run dev
```

### Test (locally)

```sh
pnpm run test
```

### Deploy (to AWS)

First, generate an SSH key for the orchestrator to use:

```sh
# The key will be created at `data/orchestrator-key`.
pnpm run generate-ssh-key
```

Then, compile:

```sh
pnpm run compile
```

Finally, see the plan and deploy:

```sh
pnpm run plan
pnpm run deploy
```

And the end of the deployment, you'll see the replica addresses, such as `TigerBeetle_TigerBeetleTfAws_ReplicaAddresses_3DD647ED    = "15.237.191.154:3000,51.44.16.54:3000"`. You can use those in your TigerBeetle client to connect to the replicas.

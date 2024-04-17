import * as tigerbeetle from "tigerbeetle-node";
import type extern from "./tigerbeetle.inflight.extern";

export const createClient: extern["createClient"] = async (options) => {
  const client = tigerbeetle.createClient({
    cluster_id: BigInt(options.cluster_id),
    concurrency_max: options.concurrency_max,
    replica_addresses: [...options.replica_addresses],
  });

  return {
    createAccounts(batch) {
      return client.createAccounts(
        batch.map((account) => ({
          code: account.code,
          credits_pending: BigInt(account.credits_pending),
          credits_posted: BigInt(account.credits_posted),
          debits_pending: BigInt(account.debits_pending),
          debits_posted: BigInt(account.debits_posted),
          flags: account.flags,
          id: BigInt(account.id),
          ledger: account.ledger,
          reserved: account.reserved,
          timestamp: BigInt(account.timestamp),
          user_data_128: BigInt(account.user_data_128),
          user_data_32: account.user_data_32,
          user_data_64: BigInt(account.user_data_64),
        }))
      );
    },
    createTransfers(batch) {
      return client.createTransfers(
        batch.map((transfer) => ({
          id: BigInt(transfer.id),
          debit_account_id: BigInt(transfer.debit_account_id),
          credit_account_id: BigInt(transfer.credit_account_id),
          amount: BigInt(transfer.amount),
          pending_id: BigInt(transfer.pending_id),
          user_data_128: BigInt(transfer.user_data_128),
          user_data_64: BigInt(transfer.user_data_64),
          user_data_32: transfer.user_data_32,
          timeout: transfer.timeout,
          ledger: transfer.ledger,
          code: transfer.code,
          flags: transfer.flags,
          timestamp: BigInt(transfer.timestamp),
        }))
      );
    },
    async lookupAccounts(batch) {
      const accounts = await client.lookupAccounts(
        batch.map((id) => BigInt(id))
      );
      return accounts.map((account) => ({
        id: account.id.toString(),
        debits_pending: account.debits_pending.toString(),
        debits_posted: account.debits_posted.toString(),
        credits_pending: account.credits_pending.toString(),
        credits_posted: account.credits_posted.toString(),
        user_data_128: account.user_data_128.toString(),
        user_data_64: account.user_data_64.toString(),
        user_data_32: account.user_data_32,
        reserved: account.reserved,
        ledger: account.ledger,
        code: account.code,
        flags: account.flags,
        timestamp: account.timestamp.toString(),
      }));
    },
  };
};

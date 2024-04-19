export default interface extern {
  createClient: (options: TigerBeetleClientOptions) => Promise<TigerBeetleClient$Inflight>,
}
export interface TigerBeetleClientOptions {
  readonly cluster_id: string;
  readonly concurrency_max?: (number) | undefined;
  readonly replica_addresses: (readonly (string)[]);
}
export interface Account {
  readonly code: number;
  readonly credits_pending: string;
  readonly credits_posted: string;
  readonly debits_pending: string;
  readonly debits_posted: string;
  readonly flags: number;
  readonly id: string;
  readonly ledger: number;
  readonly reserved: number;
  readonly timestamp: string;
  readonly user_data_128: string;
  readonly user_data_32: number;
  readonly user_data_64: string;
}
export interface CreateAccountsError {
  readonly index: number;
  readonly result: number;
}
export interface Transfer {
  readonly amount: string;
  readonly code: number;
  readonly credit_account_id: string;
  readonly debit_account_id: string;
  readonly flags: number;
  readonly id: string;
  readonly ledger: number;
  readonly pending_id: string;
  readonly timeout: number;
  readonly timestamp: string;
  readonly user_data_128: string;
  readonly user_data_32: number;
  readonly user_data_64: string;
}
export interface CreateTransfersError {
  readonly index: number;
  readonly result: number;
}
export interface TigerBeetleClient$Inflight {
  readonly createAccounts: (batch: (readonly (Account)[])) => Promise<(readonly (CreateAccountsError)[])>;
  readonly createTransfers: (batch: (readonly (Transfer)[])) => Promise<(readonly (CreateTransfersError)[])>;
  readonly lookupAccounts: (batch: (readonly (string)[])) => Promise<(readonly (Account)[])>;
}
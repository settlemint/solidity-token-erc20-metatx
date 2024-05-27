import { Address } from '@graphprotocol/graph-ts';
import { ForwarderContract } from '../../generated/schema';
import { fetchAccount } from './account';

export function fetchForwarder(address: Address): ForwarderContract {
  const account = fetchAccount(address);
  let contract = ForwarderContract.load(account.id.toHex());

  if (contract == null) {
    contract = new ForwarderContract(account.id.toHex());
    contract.asAccount = account.id;
    account.asForwarder = contract.id;

    contract.save();
    account.save();
  }

  return contract as ForwarderContract;
}

import { events, transactions } from "@amxx/graphprotocol-utils";
import { Bytes } from "@graphprotocol/graph-ts";
import { fetchAccount } from "../fetch/account";
import { fetchForwarder } from "../fetch/forwarder";
import {
  ForwarderCreated as ForwarderCreatedEvent,
  MetaTransactionExecuted as MetaTransactionEvent,
} from "../generated/forwarder/Forwarder";
import { ForwarderCreated, MetaTransactionExecuted } from "../generated/schema";

export function handleForwarderCreated(event: ForwarderCreatedEvent): void {
  const contract = fetchForwarder(event.address);
  fetchAccount(event.params.forwarderAddress);

  const ev = new ForwarderCreated(events.id(event));
  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;

  ev.contract = contract.id;
  ev.forwarderAddress = Bytes.fromHexString(
    event.params.forwarderAddress.toHexString()
  );

  ev.save();
}

export function handleMetaTransactionExecuted(
  event: MetaTransactionEvent
): void {
  const contract = fetchForwarder(event.address);
  fetchAccount(event.params.from);
  fetchAccount(event.params.to);

  const ev = new MetaTransactionExecuted(events.id(event));
  ev.emitter = Bytes.fromHexString(contract.id);
  ev.transaction = transactions.log(event).id;
  ev.timestamp = event.block.timestamp;

  ev.contract = contract.id;
  ev.from = Bytes.fromHexString(event.params.from.toHexString());
  ev.to = Bytes.fromHexString(event.params.to.toHexString());

  ev.save();
}

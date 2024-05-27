import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const GenericTokenMetaModule = buildModule('GenericTokenMetaModule', (m) => {
  const forwarder = m.contract('Forwarder');
  const token = m.contract('GenericTokenMeta', [
    'GenericERC20',
    'GT',
    forwarder,
  ]);

  return { forwarder, token };
});

export default GenericTokenMetaModule;

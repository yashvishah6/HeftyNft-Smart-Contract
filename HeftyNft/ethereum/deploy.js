const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
const compiledFactory = require('./build/AuctionFactory.json');
const provider = new HDWalletProvider(
'hungry help relax plate love system draw arrive scheme scout useless nice',
'https://rinkeby.infura.io/v3/3a46f37e8e254666a4f6b2a1d9682870'
);

const web3 = new Web3(provider);
const deploy = async() =>{
   const accounts = await web3.eth.getAccounts();
   console.log('attempting to deploy from account', accounts[0]);
   const result = await new web3.eth.Contract(JSON.parse(compiledFactory.interface))
   .deploy({ data: compiledFactory.bytecode})
   .send({gas: '1000000', from: accounts[0]});

   console.log('Contract deployed to', result.options.address);
};
deploy();

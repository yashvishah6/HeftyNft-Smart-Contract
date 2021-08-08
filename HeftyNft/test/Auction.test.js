const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

const compiledFactory = require('../ethereum/build/AuctionFactory.json');
const compiledAuction = require('../ethereum/build/Auction.json');

let accounts;
let factory;
let auctionAddress;
let auction;

beforeEach(async () =>{
  accounts = await web3.eth.getAccounts();

  factory = await new web3.eth.Contract(JSON.parse(compiledFactory.interface))
     .deploy({ data : compiledFactory.bytecode })
     .send({ from: accounts[0], gas: '1000000'});

  await factory.methods.createAuction( accounts[0], 9067544, 9999999, 'sfhagdh', '1000').send({
    from: accounts[0],
    gas: '1000000'

  });

  [auctionAddress] = await factory.methods.getDeployedAuctions().call();
  auction = await new web3.eth.Contract(
    JSON.parse(compiledAuction.interface),
    auctionAddress
  );
});

describe('Auctions', () => {
  it('deploys a factory and an auction', () => {
    assert.ok(factory.options.address);
    assert.ok(auction.options.address);
  });

  it('marks the caller as the auction owner', async () =>{
    const owner = await auction.methods.owner().call();
    assert.equal(accounts[0], owner);
    });

});

var abi = require('./abi');
var abi2 = require('./abi2');
var Web3 = require('web3');
Web3.providers.HttpProvider.prototype.sendAsync = Web3.providers.HttpProvider.prototype.send
provider = new Web3.providers.HttpProvider("NODE_PROVIDER_ADDRESS")
const HDWalletProvider = require("@truffle/hdwallet-provider");
const { snakeCase } = require('lodash');

const myPrivateKeyHex = '#INSERT_YOUR_PRIVATE_KEY_HERE';


const localKeyProvider = new HDWalletProvider({
    privateKeys: [myPrivateKeyHex],
    providerOrUrl: provider,
  });

const web3 = new Web3(localKeyProvider);

const myAccount = web3.eth.accounts.privateKeyToAccount(myPrivateKeyHex);

const address = '0x317D94dC86cFbF75dB2b7142aaadcCE58dc10502';
const myContract = new web3.eth.Contract(abi, '0xFc40a0e00bdbA0613929F5c54113B9EF659102A1');

const sanskarContract = new web3.eth.Contract(abi2, '0x82266B802fBb84F8f3Fcc83859d2aCeFE3437CF3');

const newPayload = sanskarContract.methods.mint('0x317D94dC86cFbF75dB2b7142aaadcCE58dc10502','20').encodeABI()
const functionABI = web3.eth.abi.encodeFunctionSignature('mint(address,uint256)');

const param1 = web3.eth.abi.encodeParameter('address','0x317D94dC86cFbF75dB2b7142aaadcCE58dc10502');
const param2 = web3.eth.abi.encodeParameter('uint256','10');

let payload = functionABI+param1+param2;

console.log(web3.utils.isHexStrict(param1));

console.log(web3.utils.isHexStrict(payload));

console.log(web3.utils.isHexStrict(newPayload));

console.log(newPayload);

//myContract.methods.submitTransaction("0x82266B802fBb84F8f3Fcc83859d2aCeFE3437CF3","0",newPayload).send({ from: myAccount.address });

//myContract.methods.confirmTransaction("7").send({ from: myAccount.address });

//myContract.methods.executeTransaction("7").send({ from: myAccount.address });


const main = async () => {

  const [owner, superCoder] = await hre.ethers.getSigners();
  
  const domainContractFactory = await hre.ethers.getContractFactory('Domain');
  const domainContract = await domainContractFactory.deploy("eda");
  await domainContract.deployed();

  console.log("Contract owner:", owner.address);

  // Let's be extra generous with our payment (we're paying more than required)
  let txn = await domainContract.register("a16z",  {value: hre.ethers.utils.parseEther('1234')});
  await txn.wait();

  // get the balance 
  const balance = await hre.ethers.provider.getBalance(domainContract.address);
  console.log("Contract balance:", hre.ethers.utils.formatEther(balance));

  // ge the funds from the contract. This is a contract that will collect the funds 
  // very cool 
  try {
    txn = await domainContract.connect(superCoder).withdraw();
    await txn.wait();
  } catch(error){
    console.log("Could not rob contract");
  }

  // updated balance of the contract 
  let ownerBalance = await hre.ethers.provider.getBalance(owner.address);
  console.log("Balance of owner before withdrawal:", hre.ethers.utils.formatEther(ownerBalance));

}

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
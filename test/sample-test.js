const { expect } = require("chai");
const { ethers } = require("hardhat");
const ProjectJSON = require("../artifacts/contracts/Project.sol/Project.json");

describe("ProjectFactory", function () {

  it("Should work", async function () {

    const ProjectFactory = await ethers.getContractFactory("ProjectFactory");
    const projectFactory = await ProjectFactory.deploy();
    await projectFactory.deployed();

    const [owner, contrib1, contrib2] = await ethers.getSigners();

    console.log("Owner : " + owner.address);
    console.log("contrib1 : " + contrib1.address);
    console.log("contrib2 : " + contrib2.address);
    
    await projectFactory.connect(owner).createProject("Project 1", ethers.utils.parseEther('10'));
    await projectFactory.connect(owner).createProject("Project 2", ethers.utils.parseEther('100'));
    await projectFactory.connect(owner).createProject("Project 3", ethers.utils.parseEther('1000'));

    const projects = await projectFactory.getProjects();

    const contractAddress = projects[0];

    const contract = new ethers.Contract(contractAddress, ProjectJSON.abi, ethers.getDefaultProvider());

    // contract.connect(owner).contribute({ value: ethers.utils.parseEther('3') });
    await contract.connect(contrib1).contribute({ value: ethers.utils.parseEther('0.7') });
    await contract.connect(contrib1).contribute({ value: ethers.utils.parseEther('6') });
    await contract.connect(contrib2).contribute({ value: ethers.utils.parseEther('5') });

    try
    {
      await contract.connect(owner).contribute({ value: ethers.utils.parseEther('1') });
    }
    catch {}

    await contract.connect(contrib1).withdraw(ethers.utils.parseEther('3'));
    console.log(await contract.connect(contrib1).myBalance());

    await contract.connect(owner).getFunds(ethers.utils.parseEther('2'));

    // console.log("Contrib1", await contract.connect(contrib1).myBalance());
    // console.log("Contrib2", await contract.connect(contrib2).myBalance());

    // await contract.connect(owner).cancel();

    // await contract.connect(contrib2).withdraw(ethers.utils.parseEther('1'));


  });
});

import { Provider } from "@ethersproject/abstract-provider";
import { AssertionError, expect } from "chai";
import { Contract, ContractFactory, Signer } from "ethers";
import { ethers } from "hardhat";

describe("Governance", function () {
  let owner: any,
    contract: ContractFactory,
    Governance: Contract,
    voter1: string | Signer | Provider,
    voter2: string | Signer | Provider,
    voter3: string | Signer | Provider,
    voter4: string | Signer | Provider,
    voter5: string | Signer | Provider,
    voter6: string | Signer | Provider,
    voter7: string | Signer | Provider;

  let proposal = "Voting Test Automatic";
  let notResolvedLower = 30;
  let notResolvedHigher = 50;
  let startDate = 1651495648;
  let endDate = 1651495649;
  let minVoters = 5;
  let whiteList = false;

  const dataForConstructor: [
    string,
    number,
    number,
    number,
    number,
    number,
    boolean
  ] = [
    proposal,
    notResolvedLower,
    notResolvedHigher,
    startDate,
    endDate,
    minVoters,
    whiteList,
  ];
  beforeEach(async () => {
    contract = await ethers.getContractFactory("Governance");
    Governance = await contract.deploy(...dataForConstructor);
    [owner, voter1, voter2, voter3, voter4, voter5, voter6, voter7] =
      await ethers.getSigners();
  });

  describe("Deployment", () => {
    it("Check owner", async () => {
      expect(await Governance.ballotOfficialAddress()).to.equal(owner.address);
    });
    it("Check proposal", async () => {
      expect(await Governance.proposal()).to.equal(proposal);
    });
    it("Check minVoters", async () => {
      expect(await Governance.minVoters()).to.equal(minVoters);
    });
    it("Check startDate", async () => {
      expect(await Governance.startDate()).to.equal(startDate);
    });
    it("Check endDate", async () => {
      expect(await Governance.endDate()).to.equal(endDate);
    });
    it("Check notResolvedLower", async () => {
      expect(await Governance.notResolvedLower()).to.equal(notResolvedLower);
    });
    it("Check notResolvedHigher", async () => {
      expect(await Governance.notResolvedHigher()).to.equal(notResolvedHigher);
    });

    //Update Parameters
    it("Update parameters in test", async () => {
      Governance.updateParameters(30, 50, 1651495648, 1651495649, 3);
      expect(await Governance.notResolvedHigher()).to.equal(50);
      expect(await Governance.notResolvedLower()).to.equal(30);
      expect(await Governance.endDate()).to.equal(1651495649);
      expect(await Governance.startDate()).to.equal(1651495648);
      expect(await Governance.minVoters()).to.equal(3);
    })
    it("Update parameters as user not owner", async () => {
      let errorM;
      try{
        await Governance.connect(voter1).updateParameters(30, 50, 1651592236, 1651592736, 3)
      }catch(err: any){
        errorM = err.message
      }
      expect(errorM).to.equal("VM Exception while processing transaction: reverted with reason string 'Sender not authorized.'")
    })    
    it("Address one vote", async () => {
      await Governance.startVote();
      expect(await Governance.state()).to.equal(1);
      await Governance.connect(voter1).doVote(0);
      await Governance.connect(voter2).doVote(0);
      await Governance.connect(voter3).doVote(0);
      await Governance.connect(voter4).doVote(0);
      await Governance.connect(voter5).doVote(0);
      expect(await Governance.totalVoter()).to.equal(5);
    })

    it("Close voting", async () => {
      await Governance.startVote();
      await Governance.endVote();
      expect(await Governance.state()).to.equal(2)
    })

    it("finalResultDescription", async () => {
      await Governance.startVote();
      await Governance.endVote();
      expect(await Governance.finalResultDescription()).to.equal("To small people voted...")
    })
  });
});

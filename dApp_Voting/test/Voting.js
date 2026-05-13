const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting", function () {
  async function deployVotingFixture() {
    const [owner, voter] = await ethers.getSigners();
    const Voting = await ethers.getContractFactory("Voting");
    const voting = await Voting.deploy();
    await voting.waitForDeployment();

    return { voting, owner, voter };
  }

  it("records who voted and which candidate they selected", async function () {
    const { voting, voter } = await deployVotingFixture();

    await expect(voting.connect(voter).vote(3))
      .to.emit(voting, "votedEvent")
      .withArgs(voter.address, 3n);

    expect(await voting.hasVoted(voter.address)).to.equal(true);
    expect(await voting.votedCandidate(voter.address)).to.equal(3n);
    expect(await voting.getVotersCount()).to.equal(1n);
    expect(await voting.getVoterAt(0)).to.equal(voter.address);
    expect((await voting.candidates(3)).voteCount).to.equal(1n);
  });

  it("does not allow the same wallet to vote twice", async function () {
    const { voting, voter } = await deployVotingFixture();

    await voting.connect(voter).vote(1);

    await expect(voting.connect(voter).vote(2)).to.be.revertedWith(
      "You have already voted"
    );
    expect(await voting.votedCandidate(voter.address)).to.equal(1n);
  });

  it("lets only the owner reset a voter when an election operator needs to reopen a ballot", async function () {
    const { voting, voter } = await deployVotingFixture();

    await voting.connect(voter).vote(4);

    await expect(voting.connect(voter).resetVoter(voter.address)).to.be.revertedWith(
      "Only owner can call this function"
    );

    await expect(voting.resetVoter(voter.address))
      .to.emit(voting, "voteReset")
      .withArgs(voter.address, 4n);

    expect(await voting.hasVoted(voter.address)).to.equal(false);
    expect(await voting.votedCandidate(voter.address)).to.equal(0n);
    expect((await voting.candidates(4)).voteCount).to.equal(0n);

    await voting.connect(voter).vote(2);
    expect(await voting.votedCandidate(voter.address)).to.equal(2n);
  });

  it("rejects votes after the voting period has ended", async function () {
    const { voting, voter } = await deployVotingFixture();
    const latestBlock = await ethers.provider.getBlock("latest");

    await voting.setVotingPeriod(latestBlock.timestamp - 120, latestBlock.timestamp - 60);

    await expect(voting.connect(voter).vote(1)).to.be.revertedWith("Voting has ended");
  });
});

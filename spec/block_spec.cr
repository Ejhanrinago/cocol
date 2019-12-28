require "./spec_helper"

describe "Ledger::Model::Block" do
  let(:height) { 0_u64 }
  let(:previous_hash) { "Olivia" }

  describe "Pow" do
    describe "Generic block" do
      let(:block) do
        Ledger::Model::Block::Pow.new(
          height: height,
          transactions: Array(Ledger::Model::Transaction).new,
          previous_hash: previous_hash,
          nbits: Ledger::Model::Block::Pow::MIN_NBITS
        )
      end

      it "should have autogenerated values" do
        block.hash.wont_be_nil
        block.nonce.wont_be_nil
        block.timestamp.wont_be_nil
        block.height.must_equal(height)
        block.previous_hash.must_equal(previous_hash)
      end
    end
  end

  describe "Pos" do
    describe "Generic block" do
      let(:nodes) { %w(4001 4002) }
      let(:stakes) do
        [
          Ledger::Model::Stake.new(
            staker: nodes[0],
            amount: 50_i64
          ),
          Ledger::Model::Stake.new(
            staker: nodes[1],
            amount: 50_i64
          ),
        ]
      end

      let(:block) do
        Ledger::Model::Block::Pos.new(
          height: height,
          previous_hash: previous_hash,
          stakes: stakes,
          transactions: Array(Ledger::Model::Transaction).new,
          miner: "3000"
        )
      end

      it "contains all genesis stakes" do
        block.hash.wont_be_nil
        block.stakes.must_equal(stakes)
        block.height.must_equal(height)
        block.previous_hash.must_equal(previous_hash)
        block.timestamp.wont_be_nil
      end
    end
  end
end
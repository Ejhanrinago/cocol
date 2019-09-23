require "json"
require "kemal"
require "socket"
require "totem"
require "uuid"
require "uuid/json"

require "./cocol/logger.cr"

require "./cocol/cli/argument"

require "./cocol/node/settings"
require "./cocol/node.cr"
require "./cocol/node/ledger.cr"
require "./cocol/node/event.cr"
require "./cocol/node/messenger.cr"

class Cocol::App
  def run_api(port : Int32)
    before_all do |env|
      env.response.content_type = "application/json"
      env.response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
      env.response.headers["Access-Control-Allow-Origin"] = "*"
      env.response.headers["Access-Control-Allow-Headers"] =
        "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
    end

    logging false
    Kemal.run(port: port, args: nil)
  end

  def self.block_mining_loop
    args = CLI::Argument.parse(ARGV)
    if args.miner?
      threshold = 2
      loop do
        sleep 1

        pending_transactions_count = (
          pending_transactions = Ledger::Mempool.pending.values
        ).size

        if pending_transactions_count >= threshold
          Cocol.logger.info "[Node: #{Node.settings.port}] Mining triggered"
          mining_transactions = pending_transactions
          Ledger::Mempool.remove(mining_transactions)
          Ledger.workflow_mine(mining_transactions)
        end
      end
    end
  end

  def self.start
    args = CLI::Argument.parse(ARGV)
    cocol = Cocol::App.new
    Node.settings.port = args.port.to_i32
    Node.settings.max_connections = args.max_connections.to_i32
    Node.settings.miner = args.miner?
    Node.settings.master = args.master?

    spawn Node.start()

    if args.update?
      spawn Ledger.update_ledger()
    end

    parallel(
      block_mining_loop(),
      cocol.run_api(port: args.port.to_i32)
    )

    loop do
      # nothing
      sleep 0.01
    end
  end
end

Cocol::App.start

# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/sky_ledger/integration"

class SkyLedgerIntegrationTest < Minitest::Test
  def setup
    @ledger = SkyLedger::Ledger.new
    @command = {
      "schema" => "sky.ledger.post.v1",
      "source" => { "product" => "SkyPayments", "reference" => "payment-123" },
      "transaction" => {
        "id" => "payment-123",
        "currency" => "USD",
        "occurred_at" => "2026-08-25T09:00:00Z",
        "entries" => [
          { "account" => "cash", "amount_minor" => 2500 },
          { "account" => "payments_clearing", "amount_minor" => -2500 }
        ]
      }
    }
  end

  def test_posts_cross_product_command_and_returns_stable_receipt
    receipt = SkyLedger::Integration.post_command(@ledger, @command)

    assert_equal "sky.ledger.receipt.v1", receipt["schema"]
    assert_equal({ "product" => "SkyPayments", "reference" => "payment-123" }, receipt["source"])
    assert_equal "payment-123", receipt["transaction_id"]
    assert_match(/\A[0-9a-f]{64}\z/, receipt["transaction_digest"])
    assert_equal 2500, @ledger.balance("cash", "USD")
  end

  def test_rejects_unknown_schema_before_posting
    @command["schema"] = "sky.ledger.post.v2"

    assert_raises(SkyLedger::ValidationError) { SkyLedger::Integration.post_command(@ledger, @command) }
    assert_empty @ledger.transactions
  end

  def test_rejects_invalid_source_metadata
    @command["source"]["product"] = "bad product!"
    assert_raises(SkyLedger::ValidationError) { SkyLedger::Integration.post_command(@ledger, @command) }

    @command["source"] = { "product" => "SkyBilling", "reference" => "" }
    assert_raises(SkyLedger::ValidationError) { SkyLedger::Integration.post_command(@ledger, @command) }
    assert_empty @ledger.transactions
  end

  def test_preserves_ledger_duplicate_protection
    SkyLedger::Integration.post_command(@ledger, @command)

    assert_raises(SkyLedger::DuplicateTransactionError) do
      SkyLedger::Integration.post_command(@ledger, @command)
    end
    assert_equal 2500, @ledger.balance("cash", "USD")
  end
end

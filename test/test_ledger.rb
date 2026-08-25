# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/sky_ledger"

class SkyLedgerTest < Minitest::Test
  def setup
    @ledger = SkyLedger::Ledger.new
    @transaction = {
      "id" => "txn-001",
      "currency" => "USD",
      "occurred_at" => "2026-08-24T12:00:00Z",
      "entries" => [
        { "account" => "cash", "amount_minor" => 10_00 },
        { "account" => "revenue", "amount_minor" => -10_00 }
      ]
    }
  end

  def test_posts_balanced_transaction_and_updates_balances
    posted = @ledger.post(@transaction)
    assert_equal "txn-001", posted.id
    assert_match(/\A[0-9a-f]{64}\z/, posted.digest)
    assert_equal 10_00, @ledger.balance("cash", "USD")
    assert_equal(-10_00, @ledger.balance("revenue", "USD"))
  end

  def test_rejects_unbalanced_transaction
    payload = Marshal.load(Marshal.dump(@transaction))
    payload["entries"][1]["amount_minor"] = -900
    assert_raises(SkyLedger::ValidationError) { @ledger.post(payload) }
  end

  def test_rejects_duplicate_transaction_id_without_double_posting
    @ledger.post(@transaction)
    assert_raises(SkyLedger::DuplicateTransactionError) { @ledger.post(@transaction) }
    assert_equal 10_00, @ledger.balance("cash", "USD")
  end

  def test_rejects_invalid_currency_account_and_zero_amount
    invalid_currency = Marshal.load(Marshal.dump(@transaction))
    invalid_currency["currency"] = "usd"
    assert_raises(SkyLedger::ValidationError) { @ledger.post(invalid_currency) }

    invalid_account = Marshal.load(Marshal.dump(@transaction))
    invalid_account["entries"][0]["account"] = "bad account"
    assert_raises(SkyLedger::ValidationError) { @ledger.post(invalid_account) }

    zero_amount = Marshal.load(Marshal.dump(@transaction))
    zero_amount["entries"][0]["amount_minor"] = 0
    assert_raises(SkyLedger::ValidationError) { @ledger.post(zero_amount) }
  end

  def test_transactions_are_sorted_deterministically
    later = Marshal.load(Marshal.dump(@transaction))
    later["id"] = "txn-later"
    later["occurred_at"] = "2026-08-24T13:00:00Z"
    earlier = Marshal.load(Marshal.dump(@transaction))
    earlier["id"] = "txn-earlier"
    earlier["occurred_at"] = "2026-08-24T11:00:00Z"

    @ledger.post(later)
    @ledger.post(earlier)
    assert_equal %w[txn-earlier txn-later], @ledger.transactions.map(&:id)
  end
end

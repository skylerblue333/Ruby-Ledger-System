# frozen_string_literal: true

require "digest"
require "json"
require "time"

module SkyLedger
  class Error < StandardError; end
  class ValidationError < Error; end
  class DuplicateTransactionError < Error; end

  Entry = Data.define(:account, :amount_minor)
  Transaction = Data.define(:id, :currency, :occurred_at, :entries, :digest)

  class Ledger
    ACCOUNT_PATTERN = /\A[a-zA-Z0-9_.:-]{1,128}\z/
    TRANSACTION_PATTERN = /\A[a-zA-Z0-9_.:-]{1,128}\z/
    CURRENCY_PATTERN = /\A[A-Z]{3}\z/
    MAX_ENTRIES = 100

    def initialize
      @transactions = {}
      @balances = Hash.new(0)
    end

    def post(payload)
      transaction = normalize(payload)
      raise DuplicateTransactionError, "transaction id already posted" if @transactions.key?(transaction.id)

      @transactions[transaction.id] = transaction
      transaction.entries.each do |entry|
        @balances[[transaction.currency, entry.account]] += entry.amount_minor
      end
      transaction
    end

    def balance(account, currency)
      validate_account!(account)
      validate_currency!(currency)
      @balances[[currency, account]]
    end

    def balances
      @balances.keys.sort.map do |currency, account|
        { "currency" => currency, "account" => account, "amount_minor" => @balances[[currency, account]] }
      end
    end

    def transactions
      @transactions.values.sort_by { |transaction| [transaction.occurred_at, transaction.id] }
    end

    private

    def normalize(payload)
      raise ValidationError, "transaction must be an object" unless payload.is_a?(Hash)

      id = payload.fetch("id", nil)
      currency = payload.fetch("currency", nil)
      occurred_at_raw = payload.fetch("occurred_at", nil)
      entries_raw = payload.fetch("entries", nil)

      validate_id!(id)
      validate_currency!(currency)
      occurred_at = parse_time!(occurred_at_raw)
      entries = normalize_entries(entries_raw)
      raise ValidationError, "entries must sum to zero" unless entries.sum(&:amount_minor).zero?

      canonical = {
        "id" => id,
        "currency" => currency,
        "occurred_at" => occurred_at.utc.iso8601(6),
        "entries" => entries.map { |entry| { "account" => entry.account, "amount_minor" => entry.amount_minor } }
      }
      digest = Digest::SHA256.hexdigest(JSON.generate(canonical))
      Transaction.new(id:, currency:, occurred_at:, entries: entries.freeze, digest:)
    rescue KeyError => error
      raise ValidationError, error.message
    end

    def normalize_entries(entries)
      unless entries.is_a?(Array) && entries.length.between?(2, MAX_ENTRIES)
        raise ValidationError, "entries must contain between 2 and #{MAX_ENTRIES} items"
      end

      entries.map do |raw|
        raise ValidationError, "entry must be an object" unless raw.is_a?(Hash)
        account = raw.fetch("account", nil)
        amount = raw.fetch("amount_minor", nil)
        validate_account!(account)
        raise ValidationError, "amount_minor must be a non-zero integer" unless amount.is_a?(Integer) && !amount.zero?
        Entry.new(account:, amount_minor: amount)
      end
    end

    def parse_time!(value)
      raise ValidationError, "occurred_at must be an ISO-8601 string" unless value.is_a?(String)
      Time.iso8601(value)
    rescue ArgumentError
      raise ValidationError, "occurred_at must be a valid ISO-8601 timestamp"
    end

    def validate_id!(value)
      raise ValidationError, "invalid transaction id" unless value.is_a?(String) && TRANSACTION_PATTERN.match?(value)
    end

    def validate_account!(value)
      raise ValidationError, "invalid account" unless value.is_a?(String) && ACCOUNT_PATTERN.match?(value)
    end

    def validate_currency!(value)
      raise ValidationError, "currency must be a three-letter uppercase code" unless value.is_a?(String) && CURRENCY_PATTERN.match?(value)
    end
  end
end

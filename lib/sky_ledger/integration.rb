# frozen_string_literal: true

require_relative "../sky_ledger"

module SkyLedger
  module Integration
    COMMAND_SCHEMA = "sky.ledger.post.v1"
    RECEIPT_SCHEMA = "sky.ledger.receipt.v1"
    PRODUCT_PATTERN = /\A[A-Za-z][A-Za-z0-9_-]{1,63}\z/
    REFERENCE_PATTERN = /\A[a-zA-Z0-9_.:-]{1,128}\z/

    module_function

    def post_command(ledger, command)
      raise ValidationError, "command must be an object" unless command.is_a?(Hash)
      raise ValidationError, "unsupported command schema" unless command["schema"] == COMMAND_SCHEMA

      source = command["source"]
      raise ValidationError, "source must be an object" unless source.is_a?(Hash)

      product = source["product"]
      reference = source["reference"]
      unless product.is_a?(String) && PRODUCT_PATTERN.match?(product)
        raise ValidationError, "invalid source product"
      end
      unless reference.is_a?(String) && REFERENCE_PATTERN.match?(reference)
        raise ValidationError, "invalid source reference"
      end

      transaction = ledger.post(command["transaction"])
      {
        "schema" => RECEIPT_SCHEMA,
        "source" => { "product" => product, "reference" => reference },
        "transaction_id" => transaction.id,
        "transaction_digest" => transaction.digest,
        "currency" => transaction.currency,
        "occurred_at" => transaction.occurred_at.utc.iso8601(6)
      }.freeze
    end
  end
end

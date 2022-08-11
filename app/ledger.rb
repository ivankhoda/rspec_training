module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message)
  class Ledger
    def record(expense); end

    def expenses_on(_date); end
  end
end
